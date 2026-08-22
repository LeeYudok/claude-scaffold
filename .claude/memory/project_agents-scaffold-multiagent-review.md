---
name: project_agents-scaffold-multiagent-review
description: 이슈 #20 3자 AI 교차리뷰로 확정된 설계 결론과 남은 후속 작업 (2026-08-22)
metadata:
  type: project
---

2026-08-22 이슈 #20 에서 Claude·GPT(Codex)·Antigravity 세 에이전트가 교차리뷰해 확정한 아키텍처 결론. #20·#21 은 CLOSED, #21(core hardening)은 PR #23 으로 머지됨.

**확정 결론**: 중립 semantic core 유지 + 설치 시 선택한 하네스에 대해 검증된 native discovery/metadata 만 **정적 생성**(compile-time target emitter). 정책 본문을 범용 IR 로 의미 변환하지 않고, 미지원 capability 는 emulation 하지 않고 강등. 강제선은 하네스 밖(CI·git hook·sandbox).

**Why**: 완전 범용은 최소공약수(강제력 상실), 하네스별 완전 복제는 drift·죽은 어댑터. 논쟁 중 "정책 본문 바이트 동일 해시 검증"안이 나왔다가 **폐기** — 같은 바이트가 하네스별로 조건부/전량/미로드로 갈리는데 해시는 전부 통과하므로 틀린 것을 측정한다. 대체안이 **P0 reachability 검사**(각 하네스에서 P0 문장이 상시/조건부/미도달 중 어디에 있는지 정적 산출, 미도달 P0 있으면 실패).

**How to apply**: 남은 후속 작업 —
- a-1 지원 매트릭스 machine-readable manifest (하네스 × CLI버전 × capability × 로딩시점 × 바이트예산 × 실측일자 × trust상태). **어댑터 만료 규칙은 manifest 가 생긴 뒤에 켠다** — 지금 T2 인프라가 0이라 먼저 켜면 한 분기 뒤 전 어댑터 unsupported + 코드 잔존
- a-2 Codex spike / a-3 agy spike(1.1.17 headless 미로드 **원인 규명**) / a-4 enforcement coverage 표
- c 골든 스냅샷 테스트 — 현재 bats 에 `diff -r`/snapshot/해시 비교가 **0건**이라 "산출물 무변경 리팩터"를 검증할 수단이 없다. 리팩터 전 선행 필수
- emitter 산출물에 `harness/CLI버전/생성일자/capability등급` provenance 기록 (배포된 사용자 레포는 회수 불가하므로 최소한 `--update` 가 강등을 알려야 함)

하네스별 경로·계약 사실은 [[reference_harness-config-contracts]].
