---
name: fix-issue
argument-hint: [issue-number]
---

이슈 #$ARGUMENTS 를 처리한다(이슈 우선 워크플로):

1. 이슈 내용 확인 (forge CLI — GitHub `gh issue view`, GitLab `glab issue view`)
2. 관련 소스 파일 탐색
3. 브랜치 생성: `git checkout -b fix/issue-$ARGUMENTS-<요약>`
4. 최소 수정 구현 + 회귀 테스트 작성
5. 빌드/테스트 그린 확인(`./gradlew test` 또는 `npm test`)
6. 커밋(`#$ARGUMENTS` 참조) → push → PR/MR 생성 → 머지
7. 이슈 클로즈 — forge 규약에 따름(`.claude/rules/forge.md` 참조)

> forge 별 구체 명령은 forge 프리셋이 이 파일을 덮어쓴다. `--forge` 로 선택.
