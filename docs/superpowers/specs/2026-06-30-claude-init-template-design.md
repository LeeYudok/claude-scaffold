# claude-scaffold 템플릿 — 설계 (2026-06-30, 이슈 #1)

## 목적

새 레포를 만들 때마다 `.claude/` 협업 구성을 손으로 다시 짜지 않도록, **부트스트랩 템플릿**을 한 곳(`<group>/claude-scaffold`)에 둔다. 두 경로로 소비한다:

1. **스크립트** — `bin/claude-scaffold.sh <target-dir>` 실행 → 베이스 + 선택 스택 프리셋 복사 + 플레이스홀더 치환.
2. **GitLab 프로젝트 템플릿** — 그룹 템플릿으로 등록 → "Create from template" → 생성 후 `bin/claude-scaffold.sh` 1회 실행으로 마무리(스택 적용·치환·self-clean).

## 비목표 (YAGNI)

- 멀티워커 `CURRENT_TASK_{user}.md` 패턴 — 1인/소규모엔 과함, 제외.
- `docs/MANUAL/*` 대량 문서 분리 — 템플릿엔 불필요.
- npm 퍼블리시·바이너리 배포 — 셸 스크립트로 충분.

## 레이아웃

```
claude-scaffold/
├── README.md                      # 용도·사용법(스크립트/템플릿 두 경로)
├── bin/
│   └── claude-scaffold.sh             # 부트스트랩 엔트리
├── presets/                       # 스택별 조각(스크립트가 선택 복사)
│   ├── nextjs/
│   │   └── .claude/rules/nextjs.md         # paths: app/**,components/**
│   └── springboot/
│       ├── .claude/rules/springboot.md     # paths: src/main/java/**
│       └── .claude/hooks/pre-commit.partial.sh  # ./gradlew 검증 조각
├── CLAUDE.md                      # {{PROJECT_NAME}} 브레인 + memory SSOT 오버라이드 + @import
└── .claude/                       # 베이스 페이로드(스택무관, 바로 동작)
    ├── README.md
    ├── settings.json              # 방어 deny, hooks 배선, model
    ├── agents/{README.md, code-reviewer.md}
    ├── commands/{README.md, fix-issue.md}
    ├── hooks/{README.md, pre-commit.sh}
    ├── memory/{README.md, MEMORY.md}
    ├── rules/{README.md, common.md}
    └── skills/{README.md, example-skill/SKILL.md}
```

## 컴포넌트 사양

### bin/claude-scaffold.sh
- 인자: `<target-dir>`(기본 `.`), 옵션 `--stack nextjs,springboot`(미지정 시 대화형 프롬프트), `--name <project>`.
- 동작:
  1. 베이스 `.claude/` + `CLAUDE.md`를 target에 복사(기존 파일 있으면 덮어쓰기 전 확인).
  2. 선택 스택별 `presets/<stack>/` 내용을 target에 머지(rule 추가, `pre-commit.partial.sh`는 `.claude/hooks/pre-commit.sh`에 append).
  3. 플레이스홀더 치환: `{{PROJECT_NAME}}`(→ --name 또는 target 디렉터리명), `{{JAVA_VERSION}}`(springboot 선택 시 `1.8`).
  4. `.sh` 실행권한 부여.
  5. **self-clean**: target이 곧 claude-scaffold 자신일 때(GitLab 템플릿 경로)면 `bin/`·`presets/`·`docs/superpowers/`를 제거하고 자기 자신도 정리.
- 순수 bash + 표준 유틸(cp/sed/find)만. 외부 의존 없음.

### .claude/settings.json (베이스, 실동작)
- `permissions.deny`: `Read(.env)`, `Read(.env.*)`, `Bash(rm -rf *)`, `Bash(git push --force *)`.
- `permissions.allow`: **비움**(self-permission은 하드 게이트 — 각 레포에서 직접 추가).
- `hooks`: PreToolUse(Bash, git commit 시 pre-commit.sh) / PostToolUse(Edit|Write) 배선.
- `model`: `claude-sonnet-4-6`. `autoMemoryEnabled`: 미설정(기본).

### .claude/rules/common.md (베이스, paths 없음 → 세션 시작 시 로드)
- 이슈 우선 워크플로, git 동사 즉시 실행, 방어 deny 근거, 대화 MZ톤/산출물 표준톤, memory SSOT 컨벤션 요약.

### presets/nextjs/.claude/rules/nextjs.md (paths: app/**,components/**)
- functional + hooks, shadcn/ui, Tailwind dark-first, next/image, cn(), no prop drilling.

### presets/springboot/.claude/rules/springboot.md (paths: src/main/java/**)
- **Java 8(1.8) = Spring Boot 2.7.x** 명시, 레이어드(controller/service/repository), lombok, bean validation, 생성자 주입, **Gradle** 빌드.
- `pre-commit.partial.sh`: `./gradlew -q compileJava test` 실패 시 exit 2(block).

### .claude/agents/code-reviewer.md (베이스, 실동작)
- frontmatter: name/description/tools(Read,Glob,Grep,Bash)/model(sonnet)/memory(project).
- git diff 읽고 CRITICAL/WARNING/SUGGESTION 보고, 보안·품질 체크.

### .claude/commands/fix-issue.md, .claude/hooks/pre-commit.sh, skills/example-skill/SKILL.md
- 가이드 표준형 + 조직 워크플로(이슈 close 수동 등) 반영한 제너릭 골격.

## 컨벤션

- skill/agent 신규 생성 시 프로젝트 prefix 네임스페이스(`<repo>-sk-*`, `<repo>-ag-*`).
- 메모리 SSOT = 레포 `.claude/memory/`(시스템 기본 경로 미사용), 타입접두 project_/feedback_/reference_/user_.
- `user_*.md`만 gitignore, 그 외 팀 공유.

## 검증

- `bin/claude-scaffold.sh`를 빈 임시 디렉터리에 실행 → `.claude/` 구조·치환·실행권한 확인.
- nextjs/springboot 각각 선택 시 해당 rule이 들어오고 paths frontmatter 유효(YAML) 확인.
- settings.json JSON 유효성, rule md frontmatter 파싱 가능 확인.
