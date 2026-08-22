#!/usr/bin/env bash
# ==============================================================================
# Out-of-Band P0 Enforcement Gate (Track B)
# ==============================================================================
# This script enforces Mechanical P0 constraints that LLMs cannot bypass.
# It is wired automatically by agents-scaffold.sh during compile time.

echo "🛡️ Running Out-of-Band P0 Enforcement Gate..."

# 1. Mechanical P0: Block .env files from being staged
if git diff --cached --name-only | grep -q "\.env"; then
    echo "❌ [P0 VIOLATION] Staging .env files is strictly prohibited."
    echo "❌ Please run 'git reset HEAD <file>' to unstage it."
    exit 1
fi

# 2. Syntax / Linting Gates (Placeholder for actual AST/Lint checkers)
# echo "Checking syntax..."

echo "✅ Out-of-Band P0 Gates Passed."
exit 0
