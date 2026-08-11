# skills/ — situational intelligence (skills)

Procedural knowledge triggered in specific situations. Each skill = 1 directory + `SKILL.md`
(frontmatter `name`/`description` (+`user-invocable`) + procedural body). When the description
trigger matches, Claude loads it and follows it as-is. `user-invocable: true` also allows manual
invocation.

```
skills/
└── <name>/
    └── SKILL.md
```

Included: `example-skill/`, `review/`, `status/`, `search-first/`, `skill-evolve/`,
`memory-factcheck/` (memory fact-check vs code/DB/issues), `security-precheck/` (pre-audit security sweep),
`grill-me/` (adversarial requirements interrogation — opt-in alternative to
superpowers-style brainstorming; the user picks one per task).
New skills should use the `{{PROJECT_NAME}}-sk-*` prefix.
