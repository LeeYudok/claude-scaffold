---
name: sonar
description: SonarQube 정적분석 실행 및 결과 조회. 코드 품질·보안 핫스팟·커버리지 확인 시 사용.
argument-hint: "[rescan|hotspots|coverage|qg] [path-filter]"
---

SonarQube 정적분석을 실행하고 결과를 요약한다.

## 인자 파싱

`$ARGUMENTS` 첫 단어가 서브커맨드. 없으면 현재 지표 요약.

| 서브커맨드 | 동작 |
|---|---|
| (없음) | 캐시된 현 지표 요약 |
| `rescan` | 스캐너 실행 + CE task 폴링 + 결과 요약 |
| `hotspots` | TO_REVIEW 보안 핫스팟 조회 |
| `coverage` | 커버리지 분석 |
| `qg` | Quality Gate 조건 breakdown |
| `<path>` | 해당 경로 CRITICAL 이슈만 필터 |

## API 접속

- `sonar-project.properties` 에서 `sonar.projectKey` 와 `sonar.host.url` 읽기
- **토큰은 환경변수 우선** — `SONAR_TOKEN`(또는 프로젝트 `.env`). `sonar-project.properties` 에 토큰 저장 금지: 커밋되는 파일이라 git 히스토리로 유출된다. `sonar.token` 라인이 이미 있으면 rotate + env 이관 권고.
- **host 사전 리브니스 체크**: `curl -s -o /dev/null -w "%{http_code}" $host/api/system/status` → 200 아니면 properties 의 URL 이 죽은 주소(예: 방치된 `localhost:9000`)일 수 있음. 실제 서버 확인 후 `-Dsonar.host.url` 로 override.
- 인증: `curl -u "$SONAR_TOKEN:" ...` 또는 `curl -H "Authorization: Bearer $SONAR_TOKEN" ...`

**토큰 2종 구분**:
- `sqp_` Project Analysis Token → `sonar-scanner` 실행, 일반 조회
- `squ_` User Token → hotspot 상태 변경 등 관리 API (403 나면 이쪽으로)

## 서브커맨드 상세

### 기본 — 현 지표 요약

```bash
token="${SONAR_TOKEN:?SONAR_TOKEN 설정 필요 (sonar-project.properties 에서 읽지 말 것)}"
key=$(grep 'sonar.projectKey' sonar-project.properties | cut -d= -f2-)
curl -s -u "$token:" \
  "http://localhost:9000/api/measures/component?component=$key&metricKeys=bugs,vulnerabilities,code_smells,coverage,security_hotspots,duplicated_lines_density,ncloc"
```

표 형태로 출력: bugs / vulnerabilities / security_hotspots / code_smells / coverage / ncloc

### `rescan` — 재스캔 + delta

1. 서버 리브니스 체크 (API 접속 섹션 참조) — 스캐너 30초 hang 대신 조기 중단
2. 현 수치 `/tmp/sonar-before.json` 저장
3. 스캐너는 명시 override 로 실행 (낡은 properties 값이 스캔을 납치하지 못하게):
   ```bash
   sonar-scanner -Dsonar.host.url="$host" -Dsonar.token="$SONAR_TOKEN"
   ```
4. CE task 폴링 (최대 90초, 2초 간격):
   ```bash
   for i in $(seq 1 45); do
     status=$(curl -s -u "$token:" "http://localhost:9000/api/ce/task?id=$ceTaskId" | python3 -c "import sys,json; print(json.load(sys.stdin)['task']['status'])")
     [ "$status" = "SUCCESS" ] && break
     [ "$status" = "FAILED" ] && { echo "task FAILED" >&2; break; }
     sleep 2
   done
   ```
5. **분석 경고 확인** — CE task 응답의 `warnings`(대시보드 경고 배너와 동일). 인코딩 깨짐, `sonar.python.version` 미지정 등은 이슈 목록엔 절대 안 나오고 여기만 나온다. 인코딩 경고 시 오염 파일 탐지:
   ```bash
   grep -rlI $'\xef\xbf\xbd' <source-dirs>   # U+FFFD 치환문자 포함 파일
   ```
6. 전/후 수치 delta 표시

**함정**: 스캐너 종료 ≠ 수치 반영. CE task status=SUCCESS 확인 필수.

### `hotspots` — 보안 핫스팟

```bash
curl -s -u "$squ_token:" \
  "http://localhost:9000/api/hotspots/search?projectKey=$key&status=TO_REVIEW&ps=500" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); [print(h['ruleKey'], h['component'], h.get('line','')) for h in d['hotspots']]"
```

### `coverage` — 커버리지

테스트 + 커버리지 리포트 생성 후 파일별 낮은 순 출력.

### `qg` — Quality Gate

```bash
curl -s -u "$squ_token:" \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=$key" \
  | python3 -c "import sys,json; [print(c['metricKey'], c['status'], c.get('actualValue','')) for c in json.load(sys.stdin)['projectStatus']['conditions']]"
```

**`conditions` 가 빈 배열이면 게이트 미구성 상태** — 이때 "Success" 는 무의미하다(무조건 통과). 초록불 보고 대신 "조건 0개"를 명시할 것.

## 함정 FAQ

- **403 Insufficient privileges**: sqp_ 로 관리 API 호출. → squ_ 로 전환
- **rescan 후 수치 이전 값**: CE task 폴링 누락. status=SUCCESS 확인 후 재조회
- **hotspot 벌크 마킹 금지**: 한 건씩 근거와 함께 → SAFE 마킹
- **`sonar-project.properties` 에 커밋된 토큰 발견**: 즉시 rotate 권고 + env 이관. 유출된 값을 계속 쓰지 말 것
- **"analyzed as compatible with all Python 3 versions" 경고**: `sonar.sources` 에 `.py` 가 섞임 — `sonar.python.version` 지정 또는 `sonar.exclusions` 추가
