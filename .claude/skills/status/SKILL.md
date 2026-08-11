---
name: status
description: 프로젝트 상태 한눈에 보기. Git 상태·빌드·테스트·최근 이슈·브랜치 현황을 한 번에 조회. 작업 시작 전 또는 상태 점검 시 사용.
allowed-tools: Bash, Read
---

# 프로젝트 상태 조회

## 실행 순서 (병렬로)

### 1. Git 상태
```bash
git status --short
git log --oneline -5
git branch -a | grep -v remotes | head -10
```

### 2. 빌드 상태 (스택 감지)
```bash
# package.json 있으면
[ -f package.json ] && (
  echo "=== TypeScript ===" && (bunx tsc --noEmit 2>&1 | tail -5 || npx tsc --noEmit 2>&1 | tail -5)
  echo "=== 빌드 ===" && (bun run build 2>&1 | tail -5 || npm run build 2>&1 | tail -5)
) || true

# go.mod 있으면
[ -f go.mod ] && echo "=== Go build ===" && go build ./... 2>&1 | tail -5 || true

# Cargo.toml 있으면
[ -f Cargo.toml ] && echo "=== Cargo check ===" && cargo check 2>&1 | tail -5 || true

# build.gradle 있으면
[ -f build.gradle ] || [ -f build.gradle.kts ] && echo "=== Gradle ===" && ./gradlew compileJava 2>&1 | tail -5 || true
```

### 3. 테스트 현황
```bash
# 가장 최근 테스트 결과 (있으면)
find . -name "*.xml" -path "*/test-results/*" -newer package.json 2>/dev/null | head -3
```

### 4. 미완료 이슈 (GitLab)
```bash
command -v glab >/dev/null && glab issue list --state=opened -P 1 --per-page 5 2>/dev/null || true
```

### 5. 프로세스 상태 (pm2/포트)
```bash
command -v pm2 >/dev/null && pm2 list 2>/dev/null | head -20 || true
```

## 출력 형식

```
## 프로젝트 상태 — {{PROJECT_NAME}} (YYYY-MM-DD HH:MM:SS)

### Git
브랜치: feature/issue-42-xxx
변경: 3 modified, 1 untracked
최근 커밋: abc1234 fix: ...

### 빌드
TypeScript: ✅ 에러 없음 / ❌ N개 에러
빌드: ✅ 성공 / ❌ 실패

### 이슈 (오픈)
#42 [feature] ...
#38 [bug] ...

### 다음 할 일
- (현재 브랜치 기준 TODO 코멘트나 남은 작업)
```

## Learned warnings

(실행 중 발견한 주의사항이 여기에 누적됩니다)
