---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/src/test/**"
  - "tests/**"
  - "**/*_test.go"
  - "**/*_test.py"
  - "**/test_*.py"
---

# 테스트 규칙

## P1
- **새 기능엔 최소 1개 테스트 동반** (단위 또는 통합). `[규율]`
- **커밋·머지 전 전체 테스트 Green 확인**. `[자동강제: pre-commit 스택 게이트 + CI —
  부분 강제: 훅이 감지한 스택만 게이트, 나머지는 직접 실행]`

## 백엔드
- 풀 컨텍스트 통합 테스트보다 **mock 기반 단위 테스트 우선**(예: `@SpringBootTest` 대신
  Mockito) — 빌드 속도·환경 의존 제거.
- 정상 케이스 + **예외 시나리오**(잘못된 입력·대상 없음) 모두 작성.
- 기대 동작이 드러나는 서술형 테스트 이름.

## 프론트
- 라우터/내비게이션 레이어는 mock 필수(예: `next/navigation` 에 `vi.mock`).
- 필요한 provider 는 테스트 래퍼로 제공(예: `QueryClientProvider` + `retry: false`).
- **사용자 관점 어설션**: 실제 보이는 텍스트/role 로 검증(`getByRole`/`findByText`),
  원시값이 아니라 포맷 적용 후 표기로 어설션.
- 같은 내용이 데스크톱/모바일 양쪽에 렌더되는 반응형 화면은 `getAllBy*` 사용 —
  `getByText` 는 중복 매칭 실패.
