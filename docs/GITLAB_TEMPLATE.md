# agents-scaffold 을 GitLab 템플릿으로 쓰기

새 프로젝트를 만들 때 agents-scaffold 구성을 자동으로 깔리게 하는 방법.

> **에디션별 요약**
> 네이티브 **커스텀 프로젝트 템플릿**(아래 A안)은 **Premium/Enterprise 전용**이라 **Community Edition(CE)** 에선 메뉴가 없다.
> → CE 에서는 **B안(Import by URL + 스크립트)** 또는 **C안(스크립트 단독)** 을 쓴다.

---

## A안 — 네이티브 커스텀 프로젝트 템플릿 (Premium 필요, 참고용)

Premium 이상에서만 동작. 향후 라이선스 업그레이드 시 사용.

전제: 템플릿 프로젝트는 **서브그룹** 안에 있어야 한다. agents-scaffold 을 예컨대 `<group>/templates/agents-scaffold` 으로 옮긴다.

### 그룹 레벨 등록
1. `<group>` 그룹 → **Settings → General → Custom project templates** 펼치기.
2. 템플릿 소스로 서브그룹(`<group>/templates`) 선택 → 저장.
3. 새 프로젝트 생성 시 **Create from template → Group** 탭에 `agents-scaffold` 이 노출됨.

### 인스턴스 레벨 등록(전 그룹 공용, admin 필요)
1. **Admin Area → Settings → Templates → Custom project templates**.
2. 템플릿 프로젝트가 모인 그룹 지정 → 저장.
3. 모든 새 프로젝트의 **Create from template → Instance** 탭에 노출.

> 두 경로 모두 프로젝트 전체(=agents-scaffold 의 `bin/`·`presets/`·`docs/` 포함)가 복제된다.
> 생성 후 반드시 `bin/agents-scaffold.sh .` 를 1회 실행해 스택 적용 + 플레이스홀더 치환 + self-clean 한다.

---

## B안 — Import by URL + 스크립트 (CE 에서 권장)

CE 에서 "템플릿"에 가장 가까운 방법. 새 프로젝트에 agents-scaffold 내용을 그대로 가져온 뒤 마무리한다.

1. **New project → Import project → Repository by URL**.
2. Git repository URL 에 agents-scaffold 주소 입력:
   `https://<your-gitlab-host>/<group>/agents-scaffold.git`
   (프로젝트 이름·네임스페이스는 새 프로젝트 것으로 지정)
3. import 완료 후 로컬에 clone, 부트스트랩 1회 실행:
   ```bash
   git clone git@<your-gitlab-host>:<group>/<new-repo>.git
   cd <new-repo>
   bin/agents-scaffold.sh . --stack nextjs,springboot --name <new-repo>
   git add -A && git commit -m "chore: agents-scaffold 부트스트랩"
   git push
   ```
   `bin/agents-scaffold.sh .` 는 in-place 모드 → 스택 적용 + 치환 + `bin/`·`presets/`·`docs/superpowers/` self-clean.

> import 는 agents-scaffold 의 git 히스토리도 가져온다. 깨끗이 시작하려면 import 대신 C안을 쓴다.

---

## C안 — 스크립트 단독 (히스토리 없이, 가장 단순)

agents-scaffold 을 한 번 clone 해두고, 빈/기존 레포에 구성만 주입한다.

```bash
# agents-scaffold 은 한 번만 받아두면 됨
git clone git@<your-gitlab-host>:<group>/agents-scaffold.git ~/agents-scaffold

# 새 레포 디렉터리에 구성 주입
~/agents-scaffold/bin/agents-scaffold.sh /path/to/new-repo --stack springboot --name my-app
```

대상이 agents-scaffold 자신이 아니므로 self-clean 은 일어나지 않고, 베이스 `.claude/` + 선택 스택만 복사된다.

---

## 스택·옵션 참고

| 옵션 | 설명 |
|---|---|
| `--stack` | `nextjs`, `springboot` 쉼표구분. 생략 시 대화형 프롬프트 |
| `--name` | `{{PROJECT_NAME}}` 치환값(기본 = 대상 디렉터리명) |
| `--yes` | 비대화 모드 |

`{{JAVA_VERSION}}` 은 springboot 프리셋에서 `1.8` 로 치환된다(= Java 8 → Spring Boot 2.7.x).
