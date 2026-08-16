# vhs docs/assets/demo.tape  (run from the repo root)
# Regenerates docs/assets/demo.gif — bootstrap, resulting tree, secret-commit gate.

Output docs/assets/demo.gif

Set FontSize 15
Set Width 960
Set Height 560
Set Padding 16
Set TypingSpeed 35ms
Set Theme "Catppuccin Mocha"
Set Shell bash

Hide
Type `SCAFFOLD="$PWD/bin/claude-scaffold.sh"; claude-scaffold.sh(){ "$SCAFFOLD" "$@"; }; work="$(mktemp -d)"; cd "$work"; export PS1='$ '; clear`
Enter
Show

Type "# 1) Bootstrap Claude Code guardrails into a repo — one command"
Enter
Sleep 800ms
Type "mkdir demo-app && claude-scaffold.sh demo-app --forge github --stack nextjs --yes"
Enter
Sleep 4s

Type "# 2) What you get: a filled .claude/ you own"
Enter
Sleep 800ms
Type "tree demo-app/.claude -L 2 --noreport"
Enter
Sleep 4s

Type "# 3) The pre-commit gate blocks secret leaks — even if the AI forgets"
Enter
Sleep 800ms
Type "cd demo-app && git init -q && echo 'API_KEY=oops' > .env && git add -f .env"
Enter
Sleep 1s
Type "bash .claude/hooks/pre-commit.sh"
Enter
Sleep 4s
