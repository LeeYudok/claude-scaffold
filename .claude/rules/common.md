# 공통 규칙 ({{PROJECT_NAME}})

<!-- paths 없음 → 세션 시작 시 항상 로드 -->

## 우선순위 체계

| 등급 | 의미 | 위반 시 |
|------|------|---------|
| **P0** | 절대 규칙 — 보안·데이터 파괴·시크릿 노출 | 즉시 중단, 사용자 에스컬레이션 |
| **P1** | 필수 — 이슈 연결, 타입체크, 테스트 | PR/MR 차단 |
| **P2** | 권장 — CC 임계값, 파일 크기 | 리뷰 지적 |

## P0 — 절대 규칙 (예외 없음)

- **시크릿**: `.env`/토큰/비밀번호를 코드·로그·이슈·채팅에 노출 금지. `source` 경유만.
- **데이터**: 프로덕션 `DELETE/DROP/TRUNCATE` 전 사용자 명시 동의.
- **git**: `force push`·`reset --hard` 전 확인. `.env` 스테이징 금지.
- **인증**: 인증 없는 API 엔드포인트 신규 추가 금지.

## P1 — 필수

- **이슈 우선**: 작업은 이슈 트래커에 이슈 등록 → 번호를 브랜치/커밋/PR·MR에 박는다. trivial typo만 예외.
- **git 동사 즉시 실행**: "푸시/머지/커밋/싱크/풀/배포" 명령엔 바로 실행. 파괴적 git만 별도 확인.
- **commit 직전 브랜치 재확인**: 자동 프로세스가 `main` 으로 checkout 했을 수 있음.
- **브랜치 전략**: `main`(prod) / `develop`(통합) / `feature·fix·chore`(작업) / `hotfix`(main 직접).
- **이슈 클로즈**: forge 규약에 따름(`.claude/rules/forge.md`). GitHub=`Closes #N` 자동. GitLab 19=자동 클로즈 동작하나 머지 후 확인, `opened` 로 남은 경우만 수동.
- **새 기능 = 테스트 동반**: 최소 1개 unit/integration 테스트.
- **배포 전 버전 bump**: 배포되는 push 직전, 변경된 서비스의 버전 매니페스트(`package.json`/`pyproject.toml`/`Cargo.toml`/`build.gradle`) bump 를 patch/minor/major/no-bump 중 무엇으로 할지 물어 같은 커밋/푸시에 반영. 디폴트: 버그픽스→patch, 새 기능→minor, 호환성 파괴→major, 인프라만(CI/scripts/docs)→no-bump. 명시적 "그냥 푸시"면 bump 생략. `[규율]`

## P2 — 권장

- 함수 인지 복잡도(CC) 15 이하 (`cc-check.py` 경고).
- 파일 300줄 초과 시 분리 검토.
- TODO/FIXME 에 이슈 번호 병기.

## 보안

- settings.json `deny`로 `.env` read·`rm -rf`·force push 차단됨. allow 추가는 신중히(self-permission 게이트).
- `curl` `-v`/`-sv` 금지 — 헤더에 시크릿 노출됨. `--silent` + status code만.

## 소통

- 대화형 응답은 가벼운 구어체. **코드·커밋·이슈/PR·MR 본문·문서는 표준/전문 톤** 유지.
- 상태 질문엔 yes/no + 짧은 근거. 디버깅은 실제 에러 원문 먼저 확보 후 행동.
- 부수효과 큰 작업(DB write·push·배포)은 사용자 명시 실행 신호 후 시작.

## 코드 탐색

- 레포 루트에 `.codegraph/` 디렉터리(CodeGraph 사전 인덱싱 지식 그래프)가 있으면, 코드 위치 파악·이해에는 grep/find/파일 순회보다 `codegraph explore "<심볼 또는 질문>"`(또는 `codegraph` MCP 도구)을 우선한다. `.codegraph/` 가 없으면 건너뜀 — 인덱싱 여부는 사용자 결정.

## 메모리

- SSOT는 `.claude/memory/`. 타입접두 `project_`/`feedback_`/`reference_`/`user_`. 자세히는 `memory/README.md`.
- `user_*.md` 만 개인(gitignore), 그 외 팀 공유.
