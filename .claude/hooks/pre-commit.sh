#!/usr/bin/env bash
# Pre-commit verification. Exits 2 to block the commit on failure.
# Stack presets append build/test verification to the STACK CHECKS section below.
set -euo pipefail

# --- Common: first line of defense against leaking secrets ---
staged=$(git diff --cached --name-only)
if printf '%s\n' "$staged" | grep -qE '(^|/)\.env($|\.)'; then
  echo "Blocked: a .env-type file is staged. Commit is not allowed." >&2
  exit 2
fi

# --- STACK CHECKS (presets append here) ---

echo "pre-commit 통과"
exit 0
