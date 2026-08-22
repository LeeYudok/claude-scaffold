#!/usr/bin/env bash
# ==============================================================================
# Compile-time Generator for Agents Scaffold (Track B Implementation)
# ==============================================================================
# Generates native activation manifests for selected harnesses without distorting
# the semantic core (AGENTS.md). Enforces Out-of-Band git hooks.

set -e

HARNESSES=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --harness) HARNESSES="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$HARNESSES" ]; then
    echo "Usage: ./agents-scaffold.sh --harness <claude|codex|agy|all>"
    exit 1
fi

echo "🚀 Compiling Native Manifests for Harnesses: $HARNESSES..."

# 1. Base Setup (Semantic Core validation)
if [ ! -f "AGENTS.md" ]; then
    echo "❌ Error: Semantic Core (AGENTS.md) not found."
    exit 1
fi

# 2. Out-of-Band Enforcement Wiring
echo "🔒 Wiring Out-of-Band Enforcement (Git Hooks)..."
mkdir -p .git/hooks
cp hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# 3. Harness Native Compilation (Thin Activation Manifests)
IFS=',' read -ra H_ARRAY <<< "$HARNESSES"
for h in "${H_ARRAY[@]}"; do
    if [ "$h" == "all" ] || [ "$h" == "claude" ]; then
        echo "⚡ Generating Claude Native Adapter (Thin Manifest)..."
        mkdir -p .claude/agents .claude/skills .claude/rules
        
        # Only discovery metadata, no semantic translation
        cat << 'EOF' > .claude/settings.json
{
  "rules": ["AGENTS.md"],
  "note": "Semantic core maintained in AGENTS.md. This is a thin activation manifest."
}
EOF
    fi

    if [ "$h" == "all" ] || [ "$h" == "codex" ]; then
        echo "⚡ Generating Codex Native Adapter (Thin Manifest)..."
        mkdir -p .codex/agents .agents/skills
        
        cat << 'EOF' > .codex/config.toml
# Thin Activation Manifest for Codex
# Semantics are preserved in AGENTS.md
core_instructions = "AGENTS.md"
EOF
        # Initialize empty hooks to enforce reliance on out-of-band git hooks
        echo '{"hooks": []}' > .codex/hooks.json
    fi

    if [ "$h" == "all" ] || [ "$h" == "agy" ]; then
        echo "⚡ Generating AGY Experimental Adapter (Thin Manifest)..."
        mkdir -p .gemini/skills
        
        # Point to core rules to respect AGY progressive disclosure
        cat << 'EOF' > .gemini/config.json
{
  "core_rules": "AGENTS.md",
  "status": "experimental",
  "note": "Native hierarchical discovery covers .agents/, explicit pointing for root."
}
EOF
    fi
done

echo "✅ Scaffolding complete! Out-of-band gates are active."
exit 0
