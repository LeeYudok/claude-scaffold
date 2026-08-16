---
name: project-github-publish-flow
description: GitHub 공개 미러는 fresh-history 스냅샷 전용 — 내부 main 계보를 직접 push/rebase 하면 안 되는 이유와 정식 갱신 절차
metadata:
  type: project
---

GitHub 공개 리모트(`github`)의 `main` 은 내부 main 과 **무관한 히스토리**다 — `scripts/publish-github.sh`(내부 전용, 공개 트리 제외)가 만드는 부모 없는 스냅샷 커밋 1개로 유지된다. 개인 이메일·내부 이슈 이력을 공개하지 않기 위한 설계.

**Why**: 2026-08-16 내부 main 을 `git push github main` 으로 밀려다 non-fast-forward 거부로 발견. 그대로 force 했다면 내부 커밋 이력(이메일·내부 그룹 경로) 전체가 공개될 뻔했다. 같은 날 공개 트리에 publish-github.sh 자신(내부 호스트/IP 가드 패턴 평문)이 남아 있던 유출도 재퍼블리시로 제거(#39 반영 누락이 원인).

**How to apply**:
- GitHub 갱신은 항상 `scripts/publish-github.sh` 실행 → `git push github publish/github:main --force` (force 는 설계상 필수, 사용자 승인 후).
- `git push github main` 금지. 거부(non-fast-forward)는 정상 방어이므로 pull/rebase 로 "해결"하려 들지 말 것.
- 공개 반경 주의: `.claude/memory/` 의 `user_*` 외 파일과 MEMORY.md 인덱스는 공개 트리에 실린다 — 내부 호스트·고객사명 금지(스크립트 가드가 최종 차단하지만 애초에 쓰지 말 것). 내부 정보는 [[user-reference-jaybbot]] 처럼 `user_*` 로.
