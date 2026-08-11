# skills/ — 상황별 지능 (스킬)

특정 상황에서 발동하는 절차적 지식. 각 스킬 = 디렉터리 1개 + `SKILL.md`
(frontmatter `name`/`description`(+`user-invocable`) + 본문 절차). description 트리거에
맞으면 Claude가 로드해 그대로 따른다. `user-invocable: true` 면 수동 호출도 가능.

```
skills/
└── <name>/
    └── SKILL.md
```

동봉: `example-skill/`, `review/`, `status/`, `search-first/`, `skill-evolve/`,
`memory-factcheck/`(메모리 사실 검증), `security-precheck/`(감사 대비 보안 사전점검),
`grill-me/`(적대적 요구사항 심문 — superpowers 식 brainstorming 의 opt-in 대체재,
작업마다 사용자가 택일).
신규는 `{{PROJECT_NAME}}-sk-*` prefix 권장.
