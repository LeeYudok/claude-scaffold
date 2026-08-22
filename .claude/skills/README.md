# skills/ — 상황별 지능 (스킬)

특정 상황에서 발동하는 절차적 지식. 각 스킬 = 디렉터리 1개 + `SKILL.md`
(frontmatter `name`/`description`(+`user-invocable`) + 본문 절차). description 트리거에
맞으면 Claude가 로드해 그대로 따른다. `user-invocable: true` 면 수동 호출도 가능.

```
skills/
└── <name>/
    ├── SKILL.md      # 본문은 짧게 — 트리거·핵심 절차만
    ├── scripts/      # (옵션) 스킬이 실행하는 스크립트
    └── resources/    # (옵션) 무거운 참조 자료 — 본문에서 링크, 필요할 때만 로드
```

원칙은 progressive disclosure(점진적 공개): SKILL.md 는 항상 로드되므로 짧게 유지하고,
긴 원문·표·예시는 `resources/` 파일로 빼서 필요할 때만 읽게 한다.

동봉: `example-skill/`, `review/`, `status/`, `search-first/`, `skill-evolve/`,
`memory-factcheck/`(메모리 사실 검증), `security-precheck/`(감사 대비 보안 사전점검),
`docs-sync/`(문서 현행화 — 주장별 사실 대조 + 다국어 짝 파일 동시 갱신),
`grill-me/`(적대적 요구사항 심문 — superpowers 식 brainstorming 의 opt-in 대체재,
작업마다 사용자가 택일).
신규는 `{{PROJECT_NAME}}-sk-*` prefix 권장.
