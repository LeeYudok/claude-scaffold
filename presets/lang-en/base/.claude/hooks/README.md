# hooks/ — Automation rules (hook scripts)

The harness runs these automatically on events (before/after tool calls, etc.). "Always/every time do X" automation must live here to be enforced.
The `hooks` block in `settings.json` wires events to scripts.

**Exit code convention**: `exit 2` = block the action, `exit 0` = allow.

Included: `pre-commit.sh` — pre-commit verification skeleton. Stack presets (e.g. springboot) append build verification.
Scripts need execute permission (`chmod +x`).

## instinct-lite (session observation → habit extraction)

A lightweight version of ECC continuous-learning-v2. No background observer — just two hooks:

- `observe-lite.sh` (PostToolUse, Bash|Edit|Write) — compactly logs tool calls to
  `.claude/memory/observations/<session>.jsonl` (secret masking, 2MB cap per session, auto-pruned after 7 days, not committed).
- `stop-memory-remind.sh` (Stop) — reminds once per session to save memory. If the observation log has
  20+ lines, it also prompts extraction of recurring patterns (repeated error fixes, user corrections, repeated workflows)
  into `instinct_*.md` memories.

See [../memory/README.md](../memory/README.md) for the instinct format.
