# agents/ — AI 팀원 (서브에이전트 정의)

작업 특화 서브에이전트. 각 에이전트 = 마크다운 1파일. frontmatter:

| 필드 | 용도 |
|---|---|
| `name` | 에이전트 이름 |
| `description` | 언제 위임할지(자동 선택 기준) |
| `tools` | 접근 가능 도구(쉼표 구분) |
| `model` | `sonnet`/`opus`/`haiku` |
| `memory` | `user`/`project`/`local` — 세션 간 컨텍스트 학습 |
| `maxTurns` | 중단 전 최대 턴 |

신규 생성 시 `{{PROJECT_NAME}}-ag-*` prefix 권장. 동봉 예시: `code-reviewer.md`.
