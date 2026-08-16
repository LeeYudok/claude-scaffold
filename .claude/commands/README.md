# commands/ — 커스텀 슬래시 커맨드

반복 작업을 `/이름` 으로 호출. 파일명 = 커맨드 이름(`fix-issue.md` → `/fix-issue`).
frontmatter `name`/`argument-hint`, 본문에 프롬프트. `$ARGUMENTS` 로 인자 수신.

동봉: `fix-issue.md`, `sdlc-cycle.md`, `sonar.md`, `knowledge-graph.md`(.claude 지식 그래프
재생성 + 깨진 링크 체크). 신규는 `{{PROJECT_NAME}}` 워크플로에 맞춰 추가.
