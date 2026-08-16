# memory/ — 프로젝트 메모리 (SSOT)

이 프로젝트 auto-memory **단일 진실원천**. 시스템 기본 경로 미사용, 모든 메모리는 여기서.

## 규칙

- `MEMORY.md` — 인덱스(단일). 메모리 1개 = 파일 1개, 한 줄 포인터를 인덱스에 추가.
- 타입 접두:
  - `project_*` — 진행 작업·목표·제약(코드/git에서 안 드러나는 것)
  - `feedback_*` — 작업 방식 지침(왜 + 적용법)
  - `reference_*` — 외부 리소스 포인터(URL·대시보드·티켓)
  - `user_*` — 개인 메모리, **gitignore 제외**(팀 비공유). 그 외 팀 공유.
  - `instinct_*` — 세션 관찰에서 추출된 습관(instinct-lite). frontmatter 에
    `trigger`(발동 조건)/`confidence`(0.3 잠정 ~ 0.9 확신)/`evidence`(근거 관찰),
    본문에 행동 1개. 같은 습관 재관찰 시 confidence 상향, 반증 시 하향/삭제.
- 단정형 사실(임계값·active flag)은 날짜를 박고, 행동 전 code/DB로 재검증(decay).
- `observations/` — PostToolUse 훅(observe-lite.sh)의 세션 관찰 JSONL. **gitignore**(비커밋),
  7일 자동 정리. Stop 훅이 이 로그로 instinct 추출을 유도한다.
- 신선도 감사(stale 정정·dead 아카이브)는 `memory-factcheck` 스킬로. 아카이브 파일은
  `archive/` 로 이동(`archived:` frontmatter 추가)하고 인덱스에서 제거 — 삭제 금지.
