# agents/ — AI 팀원 (서브에이전트 정의)

작업 특화 서브에이전트. 각 에이전트 = 마크다운 1파일. frontmatter:

| 필드 | 용도 |
|---|---|
| `name` | 에이전트 이름 |
| `description` | 언제 위임할지(자동 선택 기준) |
| `tools` | 접근 가능 도구(쉼표 구분) |
| `model` | `sonnet`/`opus`/`haiku`/`inherit`(부모 세션 상속) 또는 전체 모델 ID. 작업 강도별 차등 — 기계적 스캔·대량 반복=haiku, 일반 구현·리뷰=sonnet, 심층 판단·보안=opus |
| `memory` | `user`/`project`/`local` — 세션 간 컨텍스트 학습 |
| `maxTurns` | 중단 전 최대 턴 |

신규 생성 시 `{{PROJECT_NAME}}-ag-*` prefix 권장. 동봉 예시: `code-reviewer.md`.

Workflow 스크립트에서 에이전트를 부를 땐 `model` 외에 `effort`(low~max)로도 강도를
조절할 수 있다 — `workflows/README.md` 참조.
