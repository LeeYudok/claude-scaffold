# agents/ — AI teammates (subagent definitions)

Task-specialized subagents. Each agent = one markdown file. Frontmatter:

| Field | Purpose |
|---|---|
| `name` | Agent name |
| `description` | When to delegate (auto-selection criteria) |
| `tools` | Accessible tools (comma-separated) |
| `model` | `sonnet`/`opus`/`haiku` |
| `memory` | `user`/`project`/`local` — cross-session context learning |
| `maxTurns` | Max turns before stopping |

Recommend the `{{PROJECT_NAME}}-ag-*` prefix for newly created agents. Bundled example: `code-reviewer.md`.
