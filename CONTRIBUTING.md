# Contributing to claude-scaffold

claude-scaffold is a minimal `.claude/` bootstrap template, not a running
application — most contributions are Markdown (rules, agent/skill
definitions) and small shell scripts (hooks, `bin/claude-scaffold.sh`,
`presets/*/.claude/hooks/pre-commit.partial.sh`). The same workflow discipline
still applies: issue first, scoped branch, one focused commit set, review.

## Workflow

1. **Issue first.** File a GitLab issue before starting work, except for
   trivial typo fixes. Note the issue number — it must appear in the branch
   name, every commit, and the merge request.
2. **Branch naming**: `type/issue-<N>-<slug>`, where `type` is one of
   `feat`, `fix`, `chore`, `docs`. Example: `docs/issue-14-contributing-spec`.
   Never commit directly to `main` or `develop`.
3. **Commit messages** must include the issue number, e.g.
   `docs: add preset spec (#14)`. Keep unrelated changes in separate commits
   even within the same branch/MR.
4. **Pre-commit gate.** `.claude/hooks/pre-commit.sh` runs on every commit in
   consuming repos (this template repo itself has no stack applied, so the
   gate is effectively the secret-leak check only). If you're testing a
   preset's `pre-commit.partial.sh`, verify it against a real bootstrapped
   repo — see [docs/PRESET_SPEC.md](docs/PRESET_SPEC.md).
5. **Merge request.** Open an MR against `main` with `Closes #<N>` in the
   description. This GitLab instance does not auto-close issues on merge
   (GitLab 19 work-items limitation) — after merging, add a note and close
   the issue manually (`glab issue note` + `glab issue close`, or the GitLab
   web UI equivalent).
6. **Review.** At minimum, a second pair of eyes on any change to
   `bin/claude-scaffold.sh`, `.claude/hooks/pre-commit.sh`, or any
   `pre-commit.partial.sh` — these are load-bearing for every repo that
   bootstraps from this template.

## What to change where

- **Core skeleton** (`.claude/agents/`, `.claude/commands/`, `.claude/hooks/`,
  `.claude/rules/common.md`, `.claude/skills/`, `AGENTS.md`, `CLAUDE.md`,
  `GEMINI.md`): applies to every consuming repo regardless of stack. Changes
  here have the widest blast radius — keep them stack-agnostic.
- **Stack presets** (`presets/<stack>/`): opt-in, applied only when a repo
  selects that stack via `bin/claude-scaffold.sh --stack <name>`. See
  [docs/PRESET_SPEC.md](docs/PRESET_SPEC.md) for the required layout.
- **Bootstrap script** (`bin/claude-scaffold.sh`): the only piece of logic that
  copies files, applies presets, and substitutes placeholders. Changes here
  affect every mode of consumption (script, GitLab import, in-place
  self-clean) — test all three before proposing a change.

## Contributing a new stack preset

1. Read [docs/PRESET_SPEC.md](docs/PRESET_SPEC.md) in full — it defines the
   required directory layout, `paths:` frontmatter rules, and the
   `pre-commit.partial.sh` contract (in particular: **never call `exit 0`**
   inside a partial — see the "Why partials must not `exit 0`" section, which
   documents a real regression from issue #6).
2. Create `presets/<stack>/.claude/rules/<stack>.md` and, if the stack has an
   automatable build/lint/test step, `presets/<stack>/.claude/hooks/pre-commit.partial.sh`.
   A preset without a meaningful automated gate (e.g. `ops`) may omit the
   partial entirely.
3. Add a row to the stack preset table in `README.md` and `README.en.md`
   (rule file + pre-commit gate description).
4. Bootstrap a scratch repo with `bin/claude-scaffold.sh /tmp/scratch --stack
   <your-stack> --name scratch` (or the repo's designated scratchpad
   directory) and confirm:
   - the rule file lands at `.claude/rules/<stack>.md` with correct
     frontmatter `paths:`,
   - the partial is appended into `.claude/hooks/pre-commit.sh` after the
     `# --- STACK CHECKS` marker,
   - a deliberate build/lint failure in the scratch repo makes
     `git commit` exit non-zero, and a passing build commits cleanly,
   - combining your new stack with at least one existing stack still runs
     both gates (regression check for the issue #6 class of bug).
5. Open an issue, then a branch/MR per the workflow above.

## Style

- Documentation is written in standard, professional English (or Korean for
  `README.en.md`) — no emoji as icons or decoration, per this project's
  visual conventions.
- Shell scripts: `set -euo pipefail` at the top, POSIX-compatible where
  practical since presets run under whatever shell the consuming repo's CI
  provides.
