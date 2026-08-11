---
name: memory-factcheck
description: Fact-check an agent's persistent memory against ground truth — verify each memory's load-bearing claims against code, database, issue tracker and filesystem, correct the stale ones, and report dead ones as archive candidates. Use when memory grows past ~30 files, right after a big stack/infra change (library swap, version upgrade, server migration, schema drop), when two memories seem to contradict each other, or on a "clean up / audit my memory" request.
---

# Memory Fact-Check

Memory decays. A fact that was true when written becomes false as code, schema and
infrastructure move on. **Stale memory is worse than no memory** — an agent reads it and
confidently does the wrong thing.

This is **not** a structural hygiene pass. Orphan files, duplicate entries, index bloat,
broken internal links — those checks compare memory files *to each other*. This skill
compares each memory **to the world it describes**: the code, the database, the issue
tracker, the filesystem. A memory can be perfectly well-formed, correctly indexed, recently
touched — and completely false.

Automatic deletion is forbidden. Only a source-of-truth comparison can tell what is dead,
and losing an incident lesson is expensive. Hence semi-automatic: **correct freely, archive
only with approval, never delete.**

## 1. Locate and inventory

Find the memory set. Common locations, in order:

- a path declared by the project's agent instructions (`AGENTS.md` / `CLAUDE.md` — e.g.
  "memory SSOT is `.claude/memory/`"). A declared path wins over every default.
- `.claude/memory/` in the repo (team-shared, committed)
- the host's per-project memory dir (e.g. `~/.claude/projects/<slug>/memory/`)

Collect for each file: frontmatter (`name`/`description`/`type`), and last modification date
(`git log -1 --format=%cs -- <file>` for committed memory, `stat` otherwise). Note the index
file (`MEMORY.md`) if one exists — it is audited too, but it is an index, not a memory.

**Personal files are out of scope** — anything the project marks personal (`user_*.md` or
equivalent) belongs to its owner. Leave untouched.

**Reading many files**: dumping 50 memories into context at once blows the tool output cap
and wastes the budget. Concatenate to one scratch file with `########## <filename>` headers,
then page through it. Do not skim — a stale claim is usually one clause inside an otherwise
correct paragraph.

## 2. Extract load-bearing claims

Per file, pick the **1–3 claims that change what an agent would do**. Ignore prose, rationale
and background; a memory is only as stale as its actionable assertions.

Load-bearing looks like: "X lives at path P" · "table T has N rows" · "issue #N is still open"
· "feature F does not exist yet" · "library L is not installed" · "the fix for this is still
pending" · "run command C to verify".

## 3. Verify against the source of truth

Work **cheapest-and-highest-yield first**. In practice the ranking below holds: issue status
is one API call and catches the largest share of stale claims, because memories are written
mid-work and the work then finishes without anyone going back to edit the memory.

| Order | Claim type | How to verify |
| --- | --- | --- |
| 1 | **Issue/PR state** ("#N open", "waiting on #N", "decision pending") | forge CLI/API — `gh issue view N --json state` / `glab api projects/<enc>/issues/N`. Batch them in one loop |
| 2 | **Path/URL** (script locations, deploy paths, endpoints) | `ls`, `test -f`, `curl -s -o /dev/null -w '%{http_code}'` |
| 3 | **Code** (file/class/config exists, behaves a certain way) | `grep`/`Read` the current tree — *the code is the SoT, not the memory* |
| 4 | **Data/schema** (tables, columns, row counts) | read-only queries via the project's DB tool. Prefer catalog estimates first (`pg_class.reltuples`, `information_schema.columns`), exact `count(*)` only when the estimate is the disputed claim |
| 5 | **Runtime/host** (cron jobs, services, logs) | `ssh <host> 'ls …; crontab -l; tail <log>'` — a job's last log line dates the claim precisely |

Parallelize independent verifications. If a source is unreachable, say so explicitly in the
report — never silently downgrade "couldn't check" to "checked".

## 4. Classify

- **fresh** — every claim holds. Don't touch it.
- **stale** — some claim is outdated (moved path, changed number, closed issue, implemented
  gap). → **Correct the body now, with the measured value and the date.** Corrections are
  within autonomous scope; they are additive truth, not deletion.
- **dead** — the core premise is gone (library removed, feature retired, wholly superseded).
  → Mark as an archive **candidate** only.

## 5. Stale patterns worth hunting

Beyond "the number changed", these recur and are easy to miss:

- **Fixed-gap drift** — the memory documents a missing capability ("there is no startup
  reconcile", "no rate limiting yet") and it has since been built. This is the most dangerous
  class: the agent re-implements or re-reports work that already shipped. Check the linked
  issue *and* grep for the symbol.
- **Cross-memory contradiction** — two memories disagree (one says a script is the way to do
  X, another says that script was retired). At least one is stale by definition. Compare
  claims across files, not only file-by-file.
- **Scale drift** — "table T has ~8M rows" written months ago now off by 25%. Harmless as
  trivia, harmful when the memory derives advice from it (batch sizes, timeout budgets,
  "this query takes 19s").
- **Recipe rot** — the memory stores a command/query as a verified recipe, and the recipe no
  longer works at today's data volume or API version. **Re-run stored recipes**; a recipe you
  did not execute is unverified.
- **Progress-state drift** — a long-running job/backfill memory whose "current status" section
  is weeks behind, sometimes with two internally contradictory status sections stacked up.
  Date each section, keep the newest, mark superseded ones.
- **Identity mismatch** — `name`/`description` says one thing, the body says the opposite
  (e.g. a file named `*-via-toolX` whose body records that toolX was abandoned). Recall
  matches on description, so the file gets loaded for the wrong reason, or missed entirely.

## 6. Report, then apply

Report as a table before changing anything — file · class · one-line evidence · action:

| File | Class | Evidence | Action |
| --- | --- | --- | --- |
| `reference_x.md` | stale | script moved `scripts/` → `data/` | path corrected |
| `project_y.md` | stale | claims "#302 reconcile missing"; `JobRunHistoryReconciler` exists, #302 closed | rewritten as done |
| `project_z.md` | dead candidate | feature from #N removed in #M | awaiting approval |

Then:

1. **Apply corrections** to stale bodies — measured value + date, keeping the original
   observation where it still carries a lesson ("was 8M as of <date>, 9.9M as of <today>").
2. **Archive dead candidates only after explicit user approval**: `git mv` into
   `<memory>/archive/` and add `archived: <date> <reason>` to the frontmatter. Never `rm`.
3. **Sync the index** — reflect corrections, drop archived entries from `MEMORY.md`.
4. **Commit through the project's normal workflow** (issue → branch/worktree → PR/MR). Memory
   is team-shared content; it does not get direct-to-main commits.

## Judgment rules — stay conservative

- **Unverifiable ⇒ fresh.** If the source of truth is unreachable, leave the memory alone and
  say the check was skipped. Unknown is not dead.
- **Incident lessons stay fresh even when the code moves.** A memory recording *why something
  broke* exists to prevent recurrence, not to snapshot a call site. Correct its stale path
  references; do not retire the lesson because the file was renamed.
- **Report the drift, don't invent the cause.** If a count inverted or a number moved
  inexplicably, record the measurement and flag it as unexplained. A plausible story written
  into memory becomes tomorrow's false fact.
- **Prefer merge over create.** Two memories on one topic → propose merging into the existing
  one.
- **Non-obvious facts discovered by the audit itself become new memories** — the audit is
  itself a source of ground truth.

## Field notes

- Fresh timestamps prove nothing. A file committed this week can carry a claim that was
  already false when written; a file untouched for months can be perfectly true. Verify
  claims, never sort by date and trim the tail.
- `count(*)` on a large table may exceed the DB tool's statement timeout — that failure *is*
  a finding when the memory claims the query is fast.
- Quote globs when shelling out from zsh (`grep --include="*.java"`), or the shell eats them
  and the check silently returns nothing — a false "fresh".
- An issue being closed does not by itself prove the described work shipped. For fixed-gap
  claims, confirm with a grep for the symbol as well.
