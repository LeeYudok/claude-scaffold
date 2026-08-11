---
name: status
description: See project status at a glance. Checks Git status, build, tests, recent issues, and branch status all at once. Use before starting work or when checking on status.
allowed-tools: Bash, Read
---

# Project Status Check

## Execution order (in parallel)

### 1. Git status
```bash
git status --short
git log --oneline -5
git branch -a | grep -v remotes | head -10
```

### 2. Build status (stack detection)
```bash
# if package.json exists
[ -f package.json ] && (
  echo "=== TypeScript ===" && (bunx tsc --noEmit 2>&1 | tail -5 || npx tsc --noEmit 2>&1 | tail -5)
  echo "=== Build ===" && (bun run build 2>&1 | tail -5 || npm run build 2>&1 | tail -5)
) || true

# if go.mod exists
[ -f go.mod ] && echo "=== Go build ===" && go build ./... 2>&1 | tail -5 || true

# if Cargo.toml exists
[ -f Cargo.toml ] && echo "=== Cargo check ===" && cargo check 2>&1 | tail -5 || true

# if build.gradle exists
[ -f build.gradle ] || [ -f build.gradle.kts ] && echo "=== Gradle ===" && ./gradlew compileJava 2>&1 | tail -5 || true
```

### 3. Test status
```bash
# most recent test results (if any)
find . -name "*.xml" -path "*/test-results/*" -newer package.json 2>/dev/null | head -3
```

### 4. Open issues (GitLab)
```bash
command -v glab >/dev/null && glab issue list --state=opened -P 1 --per-page 5 2>/dev/null || true
```

### 5. Process status (pm2/ports)
```bash
command -v pm2 >/dev/null && pm2 list 2>/dev/null | head -20 || true
```

## Output format

```
## Project Status — {{PROJECT_NAME}} (YYYY-MM-DD HH:MM:SS)

### Git
Branch: feature/issue-42-xxx
Changes: 3 modified, 1 untracked
Recent commit: abc1234 fix: ...

### Build
TypeScript: ✅ no errors / ❌ N errors
Build: ✅ succeeded / ❌ failed

### Issues (open)
#42 [feature] ...
#38 [bug] ...

### Next steps
- (remaining TODO comments or outstanding work on the current branch)
```

## Learned warnings

(Notes discovered during execution accumulate here)
