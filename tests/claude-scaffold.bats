#!/usr/bin/env bats
# claude-scaffold.sh 회귀 테스트 (이슈 #12)
#
# 실행: bats tests/claude-scaffold.bats
# 로컬 설치: brew install bats-core (또는 https://github.com/bats-core/bats-core)
#
# 각 테스트는 REPO_ROOT/bin/claude-scaffold.sh 를 BATS_TEST_TMPDIR 안의
# 격리된 타겟에 대해 실행한다. 원본 레포는 절대 건드리지 않는다
# (in-place self-clean 테스트만 예외 — 반드시 레포를 임시 복사한 사본을 대상으로 함).
#
# ⚠️ 알려진 환경 이슈 (이슈 #12 조사 중 발견, bin/claude-scaffold.sh 는 수정하지 않음
#    — #10/#13 병렬 작업 범위): macOS 기본 시스템 bash(/bin/bash, 3.2, set -u 하에서
#    "IFS=',' read -a arr <<< \"\"" 로 만든 빈 배열 참조 시 "unbound variable" 로 죽는
#    구버전 버그 있음) 로 bin/claude-scaffold.sh 를 실행하면 --stack 을 지정하지 않은
#    호출(예: base copy 전용 실행)이 90번째 줄 `for s in "${STACK_ARR[@]}"` 에서
#    실패한다. bash>=4 (CI ubuntu 기본, 또는 `brew install bash` 후 PATH 우선순위 조정)
#    에서는 재현되지 않는다. 이 테스트 스위트는 CI/최신 bash 기준으로 통과하도록
#    작성했다 — 로컬에서 실행 전 `PATH="/opt/homebrew/bin:$PATH"` 로 brew bash 를
#    우선시킬 것. 근본 수정(예: `"${STACK_ARR[@]:-}"` 가드)은 별도 이슈로 보고.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO_ROOT/bin/claude-scaffold.sh"
}

# --- 1) 베이스 복사 ---

# 테스트 이름은 ASCII 로 유지한다 — bats-core 가 비-ASCII(한글) 테스트명에서
# 로케일/CI 환경에 따라 내부 이름 인코딩이 어긋나 "unknown test name" 으로
# 깨지는 사례가 있어(로컬 macOS ko_KR.UTF-8 환경에서 실측 재현) 회피한다.

@test "base copy creates .claude AGENTS.md CLAUDE.md GEMINI.md" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --yes
  [ "$status" -eq 0 ]
  [ -d "$BATS_TEST_TMPDIR/.claude" ]
  [ -f "$BATS_TEST_TMPDIR/AGENTS.md" ]
  [ -f "$BATS_TEST_TMPDIR/CLAUDE.md" ]
  [ -f "$BATS_TEST_TMPDIR/GEMINI.md" ]
}

# --- 2) 스택 1개 머지 ---

@test "one stack (bun) merge: rules copied + partial inserted right after marker" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --stack bun --yes
  [ "$status" -eq 0 ]
  [ -f "$BATS_TEST_TMPDIR/.claude/rules/bun.md" ]

  hook="$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh"
  [ -f "$hook" ]

  marker_line="$(grep -n '# --- STACK CHECKS' "$hook" | head -1 | cut -d: -f1)"
  [ -n "$marker_line" ]
  next_line="$((marker_line + 1))"
  next_content="$(sed -n "${next_line}p" "$hook")"
  # bun partial 의 첫 줄(주석 헤더)이 마커 바로 다음 줄이어야 함
  first_partial_line="$(head -1 "$REPO_ROOT/presets/bun/.claude/hooks/pre-commit.partial.sh")"
  [ "$next_content" = "$first_partial_line" ]
}

# --- 3) 스택 2개 머지 (#6 회귀) ---

@test "two stacks (bun,python) merge: both gates exist before exit 0 (#6 regression)" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --stack bun,python --yes
  [ "$status" -eq 0 ]

  hook="$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh"
  [ -f "$hook" ]

  exit0_line="$(grep -n '^exit 0$' "$hook" | tail -1 | cut -d: -f1)"
  [ -n "$exit0_line" ]

  bun_line="$(grep -n 'bun (TypeScript) typecheck gate' "$hook" | head -1 | cut -d: -f1)"
  python_line="$(grep -n 'Python lint + typecheck gate' "$hook" | head -1 | cut -d: -f1)"

  [ -n "$bun_line" ]
  [ -n "$python_line" ]
  [ "$bun_line" -lt "$exit0_line" ]
  [ "$python_line" -lt "$exit0_line" ]

  # 두 partial 모두 exit 2 (차단) 만 쓰고 exit 0 으로 훅을 조기 종료하지 않는지 확인
  # (partial 자체는 exit 0 을 포함하지 않아야 함 — #6 재발 방지)
  ! grep -q '^exit 0$' "$REPO_ROOT/presets/bun/.claude/hooks/pre-commit.partial.sh"
  ! grep -q '^exit 0$' "$REPO_ROOT/presets/python/.claude/hooks/pre-commit.partial.sh"
}

# --- 4) 마커 없는 커스텀 base -> append fallback ---

@test "custom base without marker: partial appended at end (fallback)" {
  mkdir -p "$BATS_TEST_TMPDIR/.claude/hooks"
  cat > "$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh" <<'EOF'
#!/usr/bin/env bash
# 커스텀 base — STACK CHECKS 마커 없음
set -euo pipefail
echo "custom pre-commit"
exit 0
EOF

  # cp -R "$SRC/.claude" "$TARGET/.claude" 는 대상 .claude 가 이미 있으면
  # 그 안에 중첩(target/.claude/.claude/...)되므로, 스택 머지 단계가 참조하는
  # target/.claude/hooks/pre-commit.sh 는 위에서 만든 커스텀 파일 그대로 남는다.
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --stack bun --yes
  [ "$status" -eq 0 ]

  hook="$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh"
  [ -f "$hook" ]
  # 마커가 여전히 없고, bun 게이트 헤더가 파일에 존재(append 됨)
  ! grep -qF '# --- STACK CHECKS' "$hook"
  grep -q 'bun (TypeScript) typecheck gate' "$hook"
  # append 이므로 커스텀 원본 내용도 그대로 유지
  grep -q 'custom pre-commit' "$hook"
}

# --- 5) {{PROJECT_NAME}} 치환 ---

@test "PROJECT_NAME placeholder substitution via --name, no .bak left" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --name my-cool-project --yes
  [ "$status" -eq 0 ]

  grep -q 'my-cool-project' "$BATS_TEST_TMPDIR/AGENTS.md"
  ! grep -q '{{PROJECT_NAME}}' "$BATS_TEST_TMPDIR/AGENTS.md"

  # .bak 파일이 하나도 남지 않아야 함
  bak_count="$(find "$BATS_TEST_TMPDIR" -name '*.bak' | wc -l | tr -d ' ')"
  [ "$bak_count" -eq 0 ]
}

@test "--name with sed metacharacters (& / \\) substitutes literally (#32)" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --name 'foo&bar/baz\qux' --yes
  [ "$status" -eq 0 ]

  grep -qF 'foo&bar/baz\qux' "$BATS_TEST_TMPDIR/AGENTS.md"
  ! grep -q '{{PROJECT_NAME}}' "$BATS_TEST_TMPDIR/AGENTS.md"
  # '&' 가 매치 원문({{PROJECT_NAME}})으로 재확장되지 않아야 함
  ! grep -qF 'foo{{PROJECT_NAME}}bar' "$BATS_TEST_TMPDIR/AGENTS.md"
}

# --- 6) 알 수 없는 스택 ---

@test "unknown stack prints warning and continues (no abort)" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --stack totally-unknown-stack --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"Warning"* ]]
  [[ "$output" == *"totally-unknown-stack"* ]]
  # 베이스는 정상적으로 완료됨
  [ -d "$BATS_TEST_TMPDIR/.claude" ]
  [ -f "$BATS_TEST_TMPDIR/AGENTS.md" ]
}

# --- 7) --yes 비대화 모드 ---

@test "--yes non-interactive mode succeeds without stdin prompt" {
  run bash -c "\"$SCRIPT\" \"$BATS_TEST_TMPDIR\" --yes < /dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" != *"stack>"* ]]
  [ -d "$BATS_TEST_TMPDIR/.claude" ]
}

# --- 8) in-place self-clean ---

@test "in-place self-clean removes bin presets docs/superpowers (run against repo copy)" {
  copy="$BATS_TEST_TMPDIR/repo-copy"
  cp -R "$REPO_ROOT" "$copy"

  # 원본 레포는 훼손되지 않아야 하므로 사본 경로로만 실행
  run "$copy/bin/claude-scaffold.sh" "$copy" --yes
  [ "$status" -eq 0 ]

  [ ! -d "$copy/bin" ]
  [ ! -d "$copy/presets" ]
  [ ! -d "$copy/docs/superpowers" ]

  # 원본은 그대로 존재해야 함
  [ -d "$REPO_ROOT/bin" ]
  [ -d "$REPO_ROOT/presets" ]
  [ -d "$REPO_ROOT/docs/superpowers" ]
}

# --- 9) 실행권한 ---

@test "hooks/*.sh get executable permission" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --stack bun --yes
  [ "$status" -eq 0 ]

  for f in "$BATS_TEST_TMPDIR/.claude/hooks/"*.sh; do
    [ -x "$f" ]
  done
}

# --- 10) --lang en / ko / invalid (이슈 #22, #36 반전: 베이스=한국어, en=오버레이) ---
#
# fixture 사본으로 오버레이 동작 자체만 검증한다 (실콘텐츠와 독립).

@test "--lang en overlays presets/lang-en/base onto target (fixture)" {
  copy="$BATS_TEST_TMPDIR/repo-copy-lang-en"
  cp -R "$REPO_ROOT" "$copy"

  mkdir -p "$copy/presets/lang-en/base/.claude/rules"
  echo "ENGLISH DUMMY COMMON RULES" > "$copy/presets/lang-en/base/.claude/rules/common.md"

  target="$BATS_TEST_TMPDIR/lang-en-target"
  mkdir -p "$target"
  run "$copy/bin/claude-scaffold.sh" "$target" --lang en --yes
  [ "$status" -eq 0 ]

  [ -f "$target/.claude/rules/common.md" ]
  grep -q "ENGLISH DUMMY COMMON RULES" "$target/.claude/rules/common.md"
}

@test "--lang ko (default) does not apply lang-en overlay (fixture)" {
  copy="$BATS_TEST_TMPDIR/repo-copy-lang-default"
  cp -R "$REPO_ROOT" "$copy"

  mkdir -p "$copy/presets/lang-en/base/.claude/rules"
  echo "ENGLISH DUMMY COMMON RULES" > "$copy/presets/lang-en/base/.claude/rules/common.md"

  target="$BATS_TEST_TMPDIR/lang-default-target"
  mkdir -p "$target"
  run "$copy/bin/claude-scaffold.sh" "$target" --yes
  [ "$status" -eq 0 ]

  [ -f "$target/.claude/rules/common.md" ]
  ! grep -q "ENGLISH DUMMY COMMON RULES" "$target/.claude/rules/common.md"
}

@test "--lang fr is rejected with exit 1" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --lang fr --yes
  [ "$status" -eq 1 ]
}

# --- 11) ported assets (issue #24) ---

@test "base copy includes ported skills, workflows, scripts, commands, rules" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --yes
  [ "$status" -eq 0 ]

  [ -f "$BATS_TEST_TMPDIR/.claude/skills/memory-factcheck/SKILL.md" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/skills/security-precheck/SKILL.md" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/workflows/README.md" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/workflows/rules-audit.js" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/scripts/knowledge_graph.py" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/commands/knowledge-graph.md" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/rules/security.md" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/rules/testing.md" ]
  [ -f "$BATS_TEST_TMPDIR/.claude/rules/data.md" ]
}

@test "PROJECT_NAME is substituted inside workflow js and script py" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --name graphproj --yes
  [ "$status" -eq 0 ]

  ! grep -rq '{{PROJECT_NAME}}' "$BATS_TEST_TMPDIR/.claude"
  grep -q 'graphproj' "$BATS_TEST_TMPDIR/.claude/scripts/knowledge_graph.py"
  grep -q 'graphproj' "$BATS_TEST_TMPDIR/.claude/workflows/rules-audit.js"
}

@test "--lang en overlays ported files with real English content" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --lang en --yes
  [ "$status" -eq 0 ]

  # en overlay must differ from the Korean base file
  ! diff -q "$REPO_ROOT/.claude/skills/memory-factcheck/SKILL.md" \
      "$BATS_TEST_TMPDIR/.claude/skills/memory-factcheck/SKILL.md" >/dev/null
  ! diff -q "$REPO_ROOT/.claude/workflows/rules-audit.js" \
      "$BATS_TEST_TMPDIR/.claude/workflows/rules-audit.js" >/dev/null
  ! diff -q "$REPO_ROOT/.claude/skills/grill-me/SKILL.md" \
      "$BATS_TEST_TMPDIR/.claude/skills/grill-me/SKILL.md" >/dev/null
  # knowledge_graph.py is a code file — never overlaid (no en counterpart may exist)
  [ ! -f "$REPO_ROOT/presets/lang-en/base/.claude/scripts/knowledge_graph.py" ]
}

# --- 12) knowledge-graph link gate (issue #24) ---
# Forces every relative link in AGENTS.md / rules/README / SKILL.md files to
# resolve on a freshly bootstrapped target, in both languages.

@test "knowledge_graph.py --check exits 0 on a fresh en scaffold" {
  command -v python3 >/dev/null || skip "python3 not installed"
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --name scratch --lang en --yes
  [ "$status" -eq 0 ]

  run python3 "$BATS_TEST_TMPDIR/.claude/scripts/knowledge_graph.py" --check
  [ "$status" -eq 0 ]
}

@test "knowledge_graph.py --check exits 0 on a fresh ko (default) scaffold" {
  command -v python3 >/dev/null || skip "python3 not installed"
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --name scratch --yes
  [ "$status" -eq 0 ]

  run python3 "$BATS_TEST_TMPDIR/.claude/scripts/knowledge_graph.py" --check
  [ "$status" -eq 0 ]
}

# --- publish-github.sh (#26) ---
# The publish script must produce a fresh-history tree without internal-only
# files (.gitlab-ci.yml) and abort when internal references remain.

# Copies the current working tree (tracked state) into an isolated scratch repo
# committed as main, so the script under test never touches the real repo.
setup_publish_repo() {
  PUB_REPO="$BATS_TEST_TMPDIR/pubrepo"
  mkdir -p "$PUB_REPO"
  (cd "$REPO_ROOT" && tar -cf - --exclude='.git' --exclude='./.git' .) | tar -xf - -C "$PUB_REPO"
  git -C "$PUB_REPO" init -q -b main
  git -C "$PUB_REPO" -c user.name=test -c user.email=test@example.com add -A
  git -C "$PUB_REPO" -c user.name=test -c user.email=test@example.com commit -qm init
}

@test "publish-github.sh: publish tree drops internal-only files, guard passes" {
  setup_publish_repo
  cd "$PUB_REPO"

  # 개발자 셸의 PUBLISH_* export 에 영향받지 않게 격리(#39)
  run env -u PUBLISH_NAME -u PUBLISH_EMAIL bash scripts/publish-github.sh
  [ "$status" -eq 0 ]

  # main keeps internal-only files; publish/github must not contain them (#39: 가드 스크립트 자신 포함)
  git cat-file -e main:.gitlab-ci.yml
  git cat-file -e main:scripts/publish-github.sh
  run git ls-tree -r --name-only publish/github
  [ "$status" -eq 0 ]
  [[ "$output" != *".gitlab-ci.yml"* ]]
  [[ "$output" != *"publish-github.sh"* ]]

  # fresh history: single parentless commit (%p 가 비어 있어야 함)
  run git log publish/github --format='%ae %p'
  [ "$status" -eq 0 ]
  [[ "$output" == *"@users.noreply.github.com"* ]]
  [[ "$output" != *" "?*[0-9a-f]* ]] || [ "$(git rev-list --count publish/github)" -eq 1 ]

  # author/committer name uses the public handle, not an internal one (#34)
  run git log publish/github --format='%an %cn'
  [ "$status" -eq 0 ]
  [ "$output" = "leeyudok leeyudok" ]
}

@test "publish-github.sh: guard aborts when an internal reference remains" {
  setup_publish_repo
  cd "$PUB_REPO"

  # split so this test file itself never contains the literal internal string
  echo "internal host: dok""sam" > leak.txt
  git -c user.name=test -c user.email=test@example.com add leak.txt
  git -c user.name=test -c user.email=test@example.com commit -qm leak

  run bash scripts/publish-github.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"leak.txt"* ]]
}

@test "publish-github.sh: guard catches private/public IP ranges (#39)" {
  setup_publish_repo
  cd "$PUB_REPO"

  # 이 테스트 파일 자체가 가드에 걸리지 않게 IP 를 조립식으로 생성
  printf 'db host: 10.%s\n' '1.2.3' > ipleak.txt
  git -c user.name=test -c user.email=test@example.com add ipleak.txt
  git -c user.name=test -c user.email=test@example.com commit -qm ipleak

  run bash scripts/publish-github.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"ipleak.txt"* ]]
}

# --- 14) forge preset merge (#33) ---

@test "--forge github merges GitHub forge.md rule" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --forge github --yes
  [ "$status" -eq 0 ]
  grep -q 'Forge 워크플로 — GitHub' "$BATS_TEST_TMPDIR/.claude/rules/forge.md"
}

@test "--forge gitlab merges GitLab forge.md rule and commands" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --forge gitlab --yes
  [ "$status" -eq 0 ]
  grep -q 'Forge 워크플로 — GitLab' "$BATS_TEST_TMPDIR/.claude/rules/forge.md"
  # forge-gitlab preset also overrides the sdlc-cycle/fix-issue commands
  diff -q "$REPO_ROOT/presets/forge-gitlab/.claude/commands/fix-issue.md" \
      "$BATS_TEST_TMPDIR/.claude/commands/fix-issue.md"
}

@test "--forge gitlab --lang en applies English forge overlay" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --forge gitlab --lang en --yes
  [ "$status" -eq 0 ]
  # en overlay must differ from the Korean forge preset file
  ! diff -q "$REPO_ROOT/presets/forge-gitlab/.claude/rules/forge.md" \
      "$BATS_TEST_TMPDIR/.claude/rules/forge.md" >/dev/null
}

@test "unknown --forge is rejected with exit 1" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --forge bitbucket --yes
  [ "$status" -eq 1 ]
}

# --- 15) --update mode (#33, mechanics from issue #13) ---

@test "--update re-adds deleted base file, stages .new for local edits, skips pre-commit.sh" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --yes
  [ "$status" -eq 0 ]

  # simulate drift: base file deleted + base file locally edited
  rm "$BATS_TEST_TMPDIR/.claude/rules/security.md"
  echo "local customization" >> "$BATS_TEST_TMPDIR/.claude/rules/data.md"

  run "$SCRIPT" "$BATS_TEST_TMPDIR" --update --yes
  [ "$status" -eq 0 ]

  # deleted file re-added
  [ -f "$BATS_TEST_TMPDIR/.claude/rules/security.md" ]
  [[ "$output" == *"+ .claude/rules/security.md"* ]]

  # locally-edited file untouched, refreshed copy staged as .new
  grep -q 'local customization' "$BATS_TEST_TMPDIR/.claude/rules/data.md"
  [ -f "$BATS_TEST_TMPDIR/.claude/rules/data.md.new" ]
  ! grep -q 'local customization' "$BATS_TEST_TMPDIR/.claude/rules/data.md.new"

  # pre-commit.sh is never overwritten (stack partials may be spliced in)
  [[ "$output" == *"pre-commit.sh"*"skipped"* ]]
  [ ! -f "$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh.new" ]
}

@test "--update leaves placeholder-free identical files unchanged (no .new spam)" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --yes
  [ "$status" -eq 0 ]
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --update --yes
  [ "$status" -eq 0 ]
  # no-op 업데이트는 .new 를 만들지 않아야 한다 — 플레이스홀더 든 파일 포함(#39).
  # 예외: forge 프리셋이 덮어쓴 commands/ 2개는 base 와 다른 게 정상(--update 는 forge 미인지).
  [ ! -f "$BATS_TEST_TMPDIR/.claude/rules/security.md.new" ]
  [ ! -f "$BATS_TEST_TMPDIR/AGENTS.md.new" ]
  stray="$(find "$BATS_TEST_TMPDIR" -name '*.new' ! -path '*/.claude/commands/*' | wc -l | tr -d ' ')"
  [ "$stray" -eq 0 ]
}

# --- 16) preset partial invariant (#33) ---
# PRESET_SPEC.md mandates: a pre-commit.partial.sh must never call `exit 0`
# (it is spliced mid-hook; exit 0 would skip every later stack's gate — issue #6).

@test "no pre-commit.partial.sh in any preset contains exit 0" {
  local found=0 p
  while IFS= read -r p; do
    if grep -vE '^[[:space:]]*#' "$p" | grep -nE '(^|[^[:alnum:]_])exit[[:space:]]+0([^0-9]|$)'; then
      echo "exit 0 found in: $p"
      found=1
    fi
  done < <(find "$REPO_ROOT/presets" -name 'pre-commit.partial.sh')
  [ "$found" -eq 0 ]
}

# --- 17) 바이너리 내성 (#37) ---
# 유닛테스트 실행 등이 .claude 트리에 __pycache__(.pyc)를 남겨도 스캐폴드가
# 죽지 않아야 한다 (macOS sed illegal byte sequence 회귀).

@test "scaffold survives .pyc binary inside base .claude tree" {
  copy="$BATS_TEST_TMPDIR/repo-copy-pyc"
  cp -R "$REPO_ROOT" "$copy"
  mkdir -p "$copy/.claude/scripts/__pycache__"
  printf '\x00\x01\x02\xff\xfe' > "$copy/.claude/scripts/__pycache__/x.cpython-313.pyc"

  target="$BATS_TEST_TMPDIR/pyc-target"
  mkdir -p "$target"
  run "$copy/bin/claude-scaffold.sh" "$target" --yes
  [ "$status" -eq 0 ]
  grep -q 'pyc-target' "$target/AGENTS.md"
  # untracked 바이너리는 아예 복사되지 않아야 한다(#39 git ls-files 기반 복사)
  [ ! -e "$target/.claude/scripts/__pycache__" ]
}

# --- 18) javaweb 프리셋 (#38) ---

@test "javaweb stack merges rules and splices partial after marker" {
  run "$SCRIPT" "$BATS_TEST_TMPDIR" --stack javaweb --yes
  [ "$status" -eq 0 ]
  grep -q 'Java + JSP' "$BATS_TEST_TMPDIR/.claude/rules/javaweb.md"
  ! grep -q '{{JAVA_VERSION}}' "$BATS_TEST_TMPDIR/.claude/rules/javaweb.md"
  grep -q 'javaweb' "$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh"
  # 파셜이 마커 뒤, 베이스 exit 0 앞에 삽입됐는지
  marker_line="$(grep -n 'STACK CHECKS' "$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh" | head -1 | cut -d: -f1)"
  javaweb_line="$(grep -n 'javaweb: maven compile' "$BATS_TEST_TMPDIR/.claude/hooks/pre-commit.sh" | head -1 | cut -d: -f1)"
  [ "$javaweb_line" -gt "$marker_line" ]
}

@test "javaweb JSP gate blocks newly added scriptlets, allows EL/JSTL (#40)" {
  target="$BATS_TEST_TMPDIR/jspgate"
  mkdir -p "$target"
  run "$SCRIPT" "$target" --stack javaweb --yes
  [ "$status" -eq 0 ]

  cd "$target"
  git init -q -b main
  git config user.name t; git config user.email t@e.c

  # EL/JSTL + 지시자/주석만 있는 JSP → 통과
  mkdir -p src/main/webapp
  cat > src/main/webapp/ok.jsp <<'JSP'
<%@ page pageEncoding="UTF-8" %>
<%-- comment --%>
<c:out value="${user.name}"/>
JSP
  git add src/main/webapp/ok.jsp
  run bash .claude/hooks/pre-commit.sh
  [ "$status" -eq 0 ]

  # 신규 스크립틀릿 추가 → exit 2 차단
  cat > src/main/webapp/bad.jsp <<'JSP'
<% String id = request.getParameter("id"); %>
JSP
  git add src/main/webapp/bad.jsp
  run bash .claude/hooks/pre-commit.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"스크립틀릿"* ]]
}
