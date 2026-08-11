#!/usr/bin/env bash
# PostToolUse(Edit|Write) — 편집된 파일을 자동 포맷.
# 포매터가 없으면 no-op (모든 스택에 안전).
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
input="$(cat)"

file="$(printf '%s' "$input" \
  | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed -E 's/.*"([^"]*)"$/\1/')"
[ -n "$file" ] && [ -f "$file" ] || exit 0

case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.md|*.css)
    if [ -f biome.json ] || [ -f biome.jsonc ]; then
      bunx --no-install biome format --write "$file" >/dev/null 2>&1 || true
    elif [ -f .prettierrc ] || [ -f .prettierrc.json ] || [ -f .prettierrc.js ] \
       || [ -f prettier.config.js ] || [ -f prettier.config.cjs ] \
       || grep -qE '"prettier"[[:space:]]*:' package.json 2>/dev/null; then
      npx --no-install prettier --write "$file" >/dev/null 2>&1 \
        || bunx --no-install prettier --write "$file" >/dev/null 2>&1 || true
    fi
    ;;
  *.py)
    command -v ruff >/dev/null 2>&1 && ruff format "$file" >/dev/null 2>&1 || true
    ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$file" >/dev/null 2>&1 || true
    ;;
  *.rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt "$file" >/dev/null 2>&1 || true
    ;;
esac
exit 0
