# claude-scaffold

[한국어](README.md) | English

[![tests](https://github.com/leeyudok/claude-scaffold/actions/workflows/test.yml/badge.svg)](https://github.com/leeyudok/claude-scaffold/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Not a framework — a minimal, fork-and-fill bootstrap for Claude Code** with
**enforced** rule tiers: P0 (halt) / P1 (PR-block) / P2 (review). Stack presets
compose into a single pre-commit gate.

![Demo: one-command bootstrap, the generated .claude/ tree, and the pre-commit gate blocking a staged .env](docs/assets/demo.gif)

_30-second demo: one command → a filled `.claude/` → the gate blocks a secret commit. Reproduce with `vhs docs/assets/demo.tape`._

## Quickstart

```bash
# one command, no clone required
curl -fsSL https://raw.githubusercontent.com/leeyudok/claude-scaffold/main/bin/claude-scaffold.sh | bash -s -- --stack nextjs --yes

# or from a local clone (prompts interactively when options are omitted)
git clone https://github.com/leeyudok/claude-scaffold.git
claude-scaffold/bin/claude-scaffold.sh /path/to/new-repo --forge github --stack nextjs,bun --name my-app
```

You get a filled-in `.claude/` directory (agents, skills, hooks, paths-scoped
rules, memory), an `AGENTS.md` project brain, and a single composed pre-commit
gate — plain files you own outright. Full options: see [Usage](#usage-1--script).

## What you get — for beginners

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/overview-dark.svg">
  <img alt="One command → a .claude/ you own (agents, skills, commands, rules, hooks, memory, AGENTS.md) → enforced gates blocking staged .env, broken builds, failing lint" src="docs/assets/overview-light.svg">
</picture>

One minute after install, Claude behaves like a teammate who knows the rules. Even if
you're new to prompting:

- **The workflow is the default**: say "build the login feature" and Claude follows
  issue → branch → implementation → tests → PR/MR on its own (`/fix-issue`;
  `/sdlc-cycle` runs an unattended cycle with three role-separated agents).
- **Mistakes are blocked by machinery**: committing `.env`/secrets, broken
  builds/type errors, or new JSP scriptlets is stopped by the pre-commit hook, and
  functions over complexity 15 get flagged — gates that catch things even when
  Claude forgets.
- **One-shot commands**: `/review` (code review + security audit), `/status`,
  `/knowledge-graph` (doc link checker), `/sonar`.
- **Requirements hardening, your pick of two**: **`grill-me`** (bundled) interrogates
  a spec over multiple rounds; **superpowers' `brainstorming`**
  ([obra/superpowers](https://github.com/obra/superpowers), separate plugin)
  diverges and converges on ideas collaboratively. With both installed, pick per
  task — grill a feature that already has direction, brainstorm a blank page.
- **Memory that survives sessions**: project learnings accumulate under
  `.claude/memory/`, auto-load next session, and are shared with the team.
- **Self-evolving**: skill-evolve/agent-evolve rewrite skill/agent definitions from
  failure feedback — it gets better the more you use it.
- **Team/multi-session safe**: per-session git worktree isolation is the default, so
  parallel work never tramples each other.

## Why claude-scaffold

Unlike large installable frameworks or agent/skill catalogs, claude-scaffold ships
no runtime, no plugin system, and no central registry to keep in sync — it is
a `.claude/` directory skeleton plus a handful of stack presets that you copy
into a repo once and then own outright. There is nothing to upgrade later:
you fork it, fill in the placeholders, delete what you don't need, and the
result is plain files under version control like any other code in the repo.

- **Enforced, not aspirational** — the P0/P1/P2 tiers are wired into hooks
  (pre-commit gate, deny rules, CC warnings), not just written down in prose.
- **Paths-scoped rules** — a rule loads only while you touch matching files,
  so context stays lean instead of front-loading every convention.
- **Self-improving** — `skill-evolve`/`agent-evolve` append "Learned warnings"
  to skills and agents from real mistakes.
- **Tested** — the bootstrap script ships with a bats regression suite, and a
  knowledge-graph link checker gates the docs.

## What's inside

```
.claude/
  agents/
    security-audit.md   12-item P0/P1 security grep scan
    db-migration.md      DDL safety check + rollback SQL generation
    sdlc-developer.md    minimal-scope implementation agent (SDLC role split)
    sdlc-tester.md        AC/TC test-writing agent
    sdlc-verifier.md      pipeline execution + report agent
    agent-evolve.md       self-improving meta agent — refines agents/*.md from run feedback
  commands/
    sonar.md             SonarQube analysis (CE task polling, sqp_/squ_ token handling)
    sdlc-cycle.md         5-stage SDLC automation
    knowledge-graph.md    regenerate the .claude knowledge graph + broken-link check
  hooks/
    pre-commit.sh         pre-commit gate skeleton (stack partial entry point)
    post-edit-format.sh   PostToolUse(Edit|Write) → auto-format
    post-test-notify.sh   PostToolUse(Bash, *test*) → terminal notification
    stop-memory-remind.sh Stop hook → once-per-session memory reminder
    cc-check.py            PostToolUse(Bash, git commit) → warn if CC > 15
  memory/
    MEMORY.md              auto-memory index (SSOT)
    README.md               memory type/usage rules
  rules/
    common.md               P0/P1/P2 priority tiers + common workflow (always loaded)
    security.md              secrets/auth P0 + lockout/admin-seeding rules (paths-scoped)
    testing.md               test-per-feature, mock-first units, user-perspective assertions
    data.md                  data-script rules — no bulk staging, explicit encodings
    README.md                paths-scoped loading + rule-authoring principles
  skills/
    skill-evolve/            self-improving meta skill ("Learned warnings" pattern)
    status/                   multi-stack status check
    review/                   code-reviewer + security-audit wrapper
    memory-factcheck/         memory fact-check — verify claims against code/DB/issues, correct stale
    security-precheck/        pre-audit security sweep → issues → parallel fixes
  workflows/
    rules-audit.js           stored Workflow example — scan/verify/repair with human merge gate
  scripts/
    knowledge_graph.py       .claude ecosystem graph + --check broken-link gate
  settings.json               hook wiring + default deny rules
AGENTS.md                 project brain — rule SSOT (P0/P1/P2 + workflow)
CLAUDE.md                 pointer to @AGENTS.md (Claude Code)
GEMINI.md                 pointer to @AGENTS.md (Gemini CLI)
presets/                  preset fragments (copy-overwrite model)
  forge-github/           GitHub forge — gh, PRs, `Closes #N` auto-close
  forge-gitlab/           GitLab forge — glab, MRs, `Closes #N` auto-close (verify after merge)
  nextjs/ bun/ ...        per-stack fragments (rules + pre-commit.partial.sh)
  lang-en/                English overlay (base/forge-*/stacks/*) — see `--lang` below
bin/                      claude-scaffold.sh bootstrap script
tests/                    bats regression suite for the bootstrap script
```

## Stack presets

| Preset | Rule file | pre-commit gate |
|--------|-----------|-----------------|
| `nextjs` | nextjs.md (paths: app/**, components/**) | `tsc --noEmit` |
| `springboot` | springboot.md (paths: src/main/java/**) | `./gradlew build` |
| `javaweb` | javaweb.md (paths: src/main/java/**, **/*.jsp) | maven/gradle/ant compile (auto-detect) |
| `bun` | bun.md (paths: **/*.ts) | `bunx tsc --noEmit` |
| `python` | python.md (paths: **/*.py) | `ruff check` + `mypy` |
| `go` | go.md (paths: **/*.go) | `go build ./...` + `vet` + `golangci-lint` |
| `rust` | rust.md (paths: src/**/*.rs, **/*.rs) | `cargo check` + `clippy` |
| `android` | android.md (paths: **/*.kt) | `./gradlew ktlintCheck detekt` |
| `ops` | ops.md (paths: Dockerfile, docker-compose*, quadlet/**, ansible/**) | — |

## Forge presets (`--forge`)

Injects the issue/PR workflow for your forge. Merged before stack presets.

| Preset | CLI | PR/MR | Issue close |
|--------|-----|-------|-------------|
| `github` (default) | `gh` | PR | **auto-closed** on merge via `Closes #N` |
| `gitlab` | `glab` | MR | `Closes #N` auto-close works — verify post-merge, manual only if still open |

Injected files: `.claude/rules/forge.md` (always loaded) plus forge variants of
`.claude/commands/fix-issue.md` and `sdlc-cycle.md` (overwrite the base). Base
files stay forge-neutral ("issue / PR·MR").

## Language (`--lang`)

The base tree (agents, rules, skills, commands, `AGENTS.md`, hook/settings
messages) is **Korean by default** (#36 inversion — Korean is the source of
truth, English is the translated overlay). `--lang en` layers the English
translation on top, applied last — after the base copy, forge preset, and
stack presets — so it overrides the same files with `presets/lang-en/base` +
`presets/lang-en/forge-<forge>` + `presets/lang-en/stacks/<stack>` content.

```bash
claude-scaffold/bin/claude-scaffold.sh /path/to/new-repo --lang en --forge github --stack bun
```

`.claude/hooks/pre-commit.sh` is never overlaid by `--lang` (it's the file
stack partials get spliced into — single-language messages, code unaffected
by language). `--update` only refreshes the Korean base; re-run with
`--lang en` on top if you need the English overlay reapplied.

## Usage 1 — script

```bash
git clone https://github.com/leeyudok/claude-scaffold.git
# --forge defaults to github; use --forge gitlab for GitLab repos
claude-scaffold/bin/claude-scaffold.sh /path/to/new-repo --forge github --stack nextjs,bun --name my-app
```

Omit `--forge`/`--stack`/`--name` to run interactively — the script will prompt
(forge defaults to github).

### Options

| Option | Description |
|---|---|
| `<target-dir>` | Target directory. Default `.` |
| `--forge <forge>` | `github` (default) or `gitlab` |
| `--lang <lang>` | `ko` (default) or `en` |
| `--stack <list>` | Comma-separated stack presets. Prompts interactively when omitted |
| `--name <name>` | `{{PROJECT_NAME}}` substitution value. Default = target directory name |
| `--yes` | Skip interactive prompts (non-interactive mode) |
| `--update` | Refresh base files of an already-bootstrapped project (see below) |

### Remote one-command install (no clone)

```bash
curl -fsSL https://raw.githubusercontent.com/leeyudok/claude-scaffold/main/bin/claude-scaffold.sh | bash -s -- --stack nextjs --yes
```

When the script detects it is not running from a local checkout (e.g. piped
execution), it downloads the `CLAUDE_SCAFFOLD_REPO` tarball (default:
`github.com/leeyudok/claude-scaffold`, override via env) into a temporary directory and
uses it as the template source. Pin a branch/tag with `CLAUDE_SCAFFOLD_REF`
(default `main`).

### Updating the base — `--update`

Applies the latest base files (`.claude/`, `AGENTS.md`, `CLAUDE.md`,
`GEMINI.md`) to an already-bootstrapped project.

```bash
claude-scaffold/bin/claude-scaffold.sh --update /path/to/existing-repo
```

- `.claude/hooks/pre-commit.sh` is always skipped — stack partials were spliced
  into it, so it needs manual merging.
- Other base files are skipped when identical; when they differ, the existing
  file is preserved and the new version is written as `<file>.new`
  (placeholder substitution applies to `.new` files too).
- A summary of added / pending-update / skipped / unchanged files is printed at
  the end — review `.new` files with `diff` and apply manually.

## Usage 2 — GitLab template

To have this configuration applied automatically when creating a new project,
see **[docs/GITLAB_TEMPLATE.md](docs/GITLAB_TEMPLATE.md)**.

> Note: this workflow assumes a self-hosted GitLab instance. On **GitLab CE**,
> native custom project templates are a Premium feature and unavailable —
> use **Import by URL + `bin/claude-scaffold.sh`** or **the script alone** instead.
> After creating/importing, run `bin/claude-scaffold.sh .` once to apply the
> chosen stacks, substitute placeholders, and self-clean `bin/`/`presets/`/`docs/superpowers/`.

## Placeholder substitution

| Token | Value |
|---|---|
| `{{PROJECT_NAME}}` | `--name` value, or the target directory name |
| `{{JAVA_VERSION}}` | `1.8` (springboot preset default) |

## Key patterns

- **P0/P1/P2 priority tiers**: defined in `common.md` + `AGENTS.md`. P0 = security/secrets/data destruction, no exceptions.
- **SDLC role split**: developer/tester/verifier agents + the `/sdlc-cycle` automation command.
- **skill-evolve / agent-evolve**: a self-improvement pattern that appends "Learned warnings" from mistakes. `skill-evolve` targets `.claude/skills/*.md`, `agent-evolve` targets `.claude/agents/*.md`.
- **Memory SSOT**: `.claude/memory/` (the system default path is not used). Type prefixes: `project_`/`feedback_`/`reference_`/`user_`.
- **Paths-scoped rules**: frontmatter `paths:` auto-loads a rule only while working on matching files.
- **Multi-agent isolation**: when parallel subagents may touch the same file concurrently, use `isolation: "worktree"`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and
[docs/PRESET_SPEC.md](docs/PRESET_SPEC.md) for the stack preset format.
New here? Start with a [`good first issue`](https://github.com/LeeYudok/claude-scaffold/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) —
adding a new stack preset is the most approachable one, since the layout is fully templated.

## License

MIT — see [LICENSE](LICENSE).
