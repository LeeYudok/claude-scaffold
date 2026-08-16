# claude-scaffold

[한국어](README.md) | [English](README.en.md) | 简体中文 | [日本語](README.ja.md)

[![tests](https://github.com/leeyudok/claude-scaffold/actions/workflows/test.yml/badge.svg)](https://github.com/leeyudok/claude-scaffold/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**这不是一个框架，而是一套极简的、fork 后按需填充的 Claude Code 引导脚手架**，
自带**强制执行**的规则分级：P0（立即中止）/ P1（阻断 PR）/ P2（评审提示）。各技术栈预设
会组合进单一的 pre-commit 门禁。

![演示：一条命令完成引导、生成的 .claude/ 目录树，以及 pre-commit 门禁拦截暂存的 .env](docs/assets/demo.gif)

_30 秒演示：一条命令 → 填充完毕的 `.claude/` → 门禁拦截了一次泄露密钥的提交。可用 `vhs docs/assets/demo.tape` 复现。_

## Quickstart

```bash
# 一条命令，无需 clone
curl -fsSL https://raw.githubusercontent.com/leeyudok/claude-scaffold/main/bin/claude-scaffold.sh | bash -s -- --stack nextjs --yes

# 或从本地克隆运行（省略选项时会进入交互式提问）
git clone https://github.com/leeyudok/claude-scaffold.git
claude-scaffold/bin/claude-scaffold.sh /path/to/new-repo --forge github --stack nextjs,bun --name my-app
```

你将得到一个填充完毕的 `.claude/` 目录（agents、skills、hooks、按路径作用域加载的
规则、memory）、一份作为项目大脑的 `AGENTS.md`，以及一个组合而成的 pre-commit
门禁——全部是完全归你所有的普通文件。完整选项见 [Usage](#usage-1--脚本)。

## 你会得到什么 — 写给新手

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/overview-dark.svg">
  <img alt="一条命令 → 一个归你所有的 .claude/（agents、skills、commands、rules、hooks、memory、AGENTS.md）→ 强制门禁拦截暂存的 .env、失败的构建和不通过的 lint" src="docs/assets/overview-light.svg">
</picture>

安装一分钟后，Claude 的表现就像一位熟知团队规则的同事。即使你刚接触
prompt 编写也没关系：

- **工作流即默认行为**：只要说"实现登录功能"，Claude 就会自行遵循
  issue → 分支 → 实现 → 测试 → PR/MR 的流程（`/fix-issue`；
  `/sdlc-cycle` 由三个职责分离的 agent 无人值守地跑完一个完整周期）。
- **错误由机制拦截**：提交 `.env`/密钥、构建失败/类型错误、新增 JSP
  scriptlet 都会被 pre-commit 钩子拦下，认知复杂度超过 15 的函数会被
  标记——即使 Claude 忘了规则，门禁也能兜底。
- **一键命令**：`/review`（代码评审 + 安全审计）、`/status`、
  `/knowledge-graph`（文档链接检查器）、`/sonar`。
- **需求打磨，两种方式任选**：**`grill-me`**（内置）对规格说明进行多轮
  拷问；**superpowers 的 `brainstorming`**
  （[obra/superpowers](https://github.com/obra/superpowers)，独立插件）
  以协作方式发散再收敛想法。两者都装好后按任务选用——已有方向的功能
  用 grill，一张白纸则用 brainstorm。
- **跨会话留存的记忆**：项目经验持续沉淀在 `.claude/memory/` 下，
  下次会话自动加载，并与团队共享。
- **自我进化**：skill-evolve/agent-evolve 会根据失败反馈重写 skill/agent
  定义——用得越多越好用。
- **团队/多会话安全**：默认按会话隔离 git worktree，并行工作互不
  踩踏。

## 为什么选择 claude-scaffold

与大型可安装框架或 agent/skill 目录不同，claude-scaffold 不附带运行时、
不带插件系统、也没有需要保持同步的中心化 registry——它只是一个 `.claude/`
目录骨架加上几个技术栈预设，复制进仓库一次之后就完全归你所有。日后没有
任何东西需要升级：fork 它、填好占位符、删掉不需要的部分，最终得到的就是
和仓库里其他代码一样纳入版本控制的普通文件。

- **强制执行，而非纸上谈兵** —— P0/P1/P2 分级接入了钩子机制
  （pre-commit 门禁、deny 规则、CC 警告），不只是写在文档里。
- **按路径作用域加载的规则** —— 规则只在你触碰匹配文件时才加载，
  上下文保持精简，而不是一开始就灌入全部约定。
- **自我改进** —— `skill-evolve`/`agent-evolve` 会把真实错误提炼成
  "Learned warnings" 追加到 skill 和 agent 里。
- **经过测试** —— 引导脚本附带 bats 回归测试套件，知识图谱链接
  检查器为文档把关。

## 内含什么

```
.claude/
  agents/
    security-audit.md   12 项 P0/P1 安全 grep 扫描
    db-migration.md      DDL 安全检查 + 回滚 SQL 生成
    sdlc-developer.md    最小范围实现 agent（SDLC 角色分离）
    sdlc-tester.md        AC/TC 测试编写 agent
    sdlc-verifier.md      流水线执行 + 报告 agent
    agent-evolve.md       自我改进元 agent —— 根据运行反馈打磨 agents/*.md
  commands/
    sonar.md             SonarQube 分析（CE 任务轮询、sqp_/squ_ 令牌处理）
    sdlc-cycle.md         5 阶段 SDLC 自动化
    knowledge-graph.md    重新生成 .claude 知识图谱 + 断链检查
  hooks/
    pre-commit.sh         pre-commit 门禁骨架（技术栈片段的接入点）
    post-edit-format.sh   PostToolUse(Edit|Write) → 自动格式化
    post-test-notify.sh   PostToolUse(Bash, *test*) → 终端通知
    stop-memory-remind.sh Stop 钩子 → 每会话一次的记忆提醒
    cc-check.py            PostToolUse(Bash, git commit) → CC > 15 时告警
  memory/
    MEMORY.md              auto-memory 索引（SSOT）
    README.md               记忆类型/使用规则
  rules/
    common.md               P0/P1/P2 优先级分级 + 通用工作流（始终加载）
    security.md              密钥/认证 P0 + 锁定/管理员初始化规则（按路径作用域）
    testing.md               每功能一测试、mock 优先的单元测试、用户视角断言
    data.md                  数据脚本规则 —— 禁止批量暂存、显式指定编码
    README.md                按路径作用域加载 + 规则编写原则
  skills/
    skill-evolve/            自我改进元 skill（"Learned warnings" 模式）
    status/                   多技术栈状态检查
    review/                   code-reviewer + security-audit 封装
    memory-factcheck/         记忆事实核查 —— 对照代码/DB/issue 验证并修正过期内容
    security-precheck/        审计前安全排查 → 拆分 issue → 并行修复
  workflows/
    rules-audit.js           存储式 Workflow 示例 —— 扫描/验证/修复，合并由人工把关
  scripts/
    knowledge_graph.py       .claude 生态图谱 + --check 断链门禁
  settings.json               钩子接线 + 默认 deny 规则
AGENTS.md                 项目大脑 —— 规则 SSOT（P0/P1/P2 + 工作流）
CLAUDE.md                 指向 @AGENTS.md 的指针（Claude Code）
GEMINI.md                 指向 @AGENTS.md 的指针（Gemini CLI）
presets/                  预设片段（复制覆盖模型）
  forge-github/           GitHub forge —— gh、PR、`Closes #N` 自动关闭
  forge-gitlab/           GitLab forge —— glab、MR、`Closes #N` 自动关闭（合并后需确认）
  nextjs/ bun/ ...        各技术栈片段（规则 + pre-commit.partial.sh）
  lang-en/                英文覆盖层（base/forge-*/stacks/*）—— 见下文 `--lang`
bin/                      claude-scaffold.sh 引导脚本
tests/                    引导脚本的 bats 回归测试套件
```

## 技术栈预设

| 预设 | 规则文件 | pre-commit 门禁 |
|--------|-----------|-----------------|
| `nextjs` | nextjs.md (paths: app/**, components/**) | `tsc --noEmit` |
| `springboot` | springboot.md (paths: src/main/java/**) | `./gradlew build` |
| `javaweb` | javaweb.md (paths: src/main/java/**, **/*.jsp) | maven/gradle/ant compile（自动检测） |
| `bun` | bun.md (paths: **/*.ts) | `bunx tsc --noEmit` |
| `python` | python.md (paths: **/*.py) | `ruff check` + `mypy` |
| `go` | go.md (paths: **/*.go) | `go build ./...` + `vet` + `golangci-lint` |
| `rust` | rust.md (paths: src/**/*.rs, **/*.rs) | `cargo check` + `clippy` |
| `android` | android.md (paths: **/*.kt) | `./gradlew ktlintCheck detekt` |
| `ops` | ops.md (paths: Dockerfile, docker-compose*, quadlet/**, ansible/**) | — |

## Forge 预设（`--forge`）

注入与你所用 forge 匹配的 issue/PR 工作流。在技术栈预设之前合并。

| 预设 | CLI | PR/MR | issue 关闭 |
|--------|-----|-------|-------------|
| `github`（默认） | `gh` | PR | 合并时通过 `Closes #N` **自动关闭** |
| `gitlab` | `glab` | MR | `Closes #N` 自动关闭有效 —— 合并后需确认，仍处于 open 时才手动关闭 |

注入的文件：`.claude/rules/forge.md`（始终加载），以及
`.claude/commands/fix-issue.md` 和 `sdlc-cycle.md` 的 forge 变体（覆盖基础版本）。
基础文件保持 forge 中立（"issue / PR·MR"）。

## 语言（`--lang`）

基础目录树（agents、rules、skills、commands、`AGENTS.md`、钩子/settings
消息）**默认为韩语**（#36 反转——韩语是事实来源，英语是翻译出的覆盖层）。
`--lang en` 会把英文翻译叠加在最上层，且最后应用——在基础复制、forge 预设、
技术栈预设之后——用 `presets/lang-en/base` +
`presets/lang-en/forge-<forge>` + `presets/lang-en/stacks/<stack>` 的内容
覆盖同名文件。

```bash
claude-scaffold/bin/claude-scaffold.sh /path/to/new-repo --lang en --forge github --stack bun
```

`.claude/hooks/pre-commit.sh` 永远不会被 `--lang` 覆盖（它是技术栈片段
拼接进去的文件——消息只有单一语言，代码不受语言影响）。`--update`
只刷新韩语基础文件；若需要重新应用英文覆盖层，请在其后再带
`--lang en` 运行一次。

## Usage 1 — 脚本

```bash
git clone https://github.com/leeyudok/claude-scaffold.git
# --forge 默认为 github；GitLab 仓库请用 --forge gitlab
claude-scaffold/bin/claude-scaffold.sh /path/to/new-repo --forge github --stack nextjs,bun --name my-app
```

省略 `--forge`/`--stack`/`--name` 即进入交互模式——脚本会依次询问
（forge 默认为 github）。

### 选项

| 选项 | 说明 |
|---|---|
| `<target-dir>` | 目标目录。默认 `.` |
| `--forge <forge>` | `github`（默认）或 `gitlab` |
| `--lang <lang>` | `ko`（默认）或 `en` |
| `--stack <list>` | 逗号分隔的技术栈预设列表。省略时进入交互式提问 |
| `--name <name>` | `{{PROJECT_NAME}}` 的替换值。默认 = 目标目录名 |
| `--yes` | 跳过交互式提问（非交互模式） |
| `--update` | 刷新已引导项目的基础文件（见下文） |

### 远程一键安装（无需 clone）

```bash
curl -fsSL https://raw.githubusercontent.com/leeyudok/claude-scaffold/main/bin/claude-scaffold.sh | bash -s -- --stack nextjs --yes
```

当脚本检测到自己并非从本地检出运行时（例如管道执行），会将
`CLAUDE_SCAFFOLD_REPO` 的 tarball（默认：
`github.com/leeyudok/claude-scaffold`，可通过环境变量覆盖）下载到临时目录，
并将其作为模板来源。用 `CLAUDE_SCAFFOLD_REF` 固定分支/标签
（默认 `main`）。

### 更新基础文件 — `--update`

将最新的基础文件（`.claude/`、`AGENTS.md`、`CLAUDE.md`、
`GEMINI.md`）应用到已完成引导的项目。

```bash
claude-scaffold/bin/claude-scaffold.sh --update /path/to/existing-repo
```

- `.claude/hooks/pre-commit.sh` 始终被跳过——技术栈片段已被拼接
  进去，需要手动合并。
- 其他基础文件内容相同时跳过；有差异时保留现有文件，新版本写为
  `<file>.new`（占位符替换同样作用于 `.new` 文件）。
- 结束时打印新增 / 待更新 / 跳过 / 未变更文件的汇总——用 `diff`
  查看 `.new` 文件后手动应用。

## Usage 2 — GitLab 模板

若想在创建新项目时自动应用这套配置，
请参阅 **[docs/GITLAB_TEMPLATE.md](docs/GITLAB_TEMPLATE.md)**。

> 注意：该工作流假定使用自托管 GitLab 实例。在 **GitLab CE** 上，
> 原生的自定义项目模板属于 Premium 功能、不可用——
> 请改用 **Import by URL + `bin/claude-scaffold.sh`** 或**仅用脚本**。
> 创建/导入后运行一次 `bin/claude-scaffold.sh .`，即可应用所选
> 技术栈、替换占位符，并自清理 `bin/`/`presets/`/`docs/superpowers/`。

## 占位符替换

| 令牌 | 值 |
|---|---|
| `{{PROJECT_NAME}}` | `--name` 的值，或目标目录名 |
| `{{JAVA_VERSION}}` | `1.8`（springboot 预设默认值） |

## 关键模式

- **P0/P1/P2 优先级分级**：定义于 `common.md` + `AGENTS.md`。P0 = 安全/密钥/数据破坏，无一例外。
- **SDLC 角色分离**：developer/tester/verifier 三个 agent + `/sdlc-cycle` 自动化命令。
- **skill-evolve / agent-evolve**：从错误中提炼 "Learned warnings" 并追加的自我改进模式。`skill-evolve` 作用于 `.claude/skills/*.md`，`agent-evolve` 作用于 `.claude/agents/*.md`。
- **Memory SSOT**：`.claude/memory/`（不使用系统默认路径）。类型前缀：`project_`/`feedback_`/`reference_`/`user_`。
- **按路径作用域加载的规则**：frontmatter `paths:` 使规则仅在处理匹配文件时自动加载。
- **多 agent 隔离**：并行 subagent 可能同时触碰同一文件时，使用 `isolation: "worktree"`。

## 贡献

工作流见 [CONTRIBUTING.md](CONTRIBUTING.md)，
技术栈预设格式见 [docs/PRESET_SPEC.md](docs/PRESET_SPEC.md)。
初来乍到？从 [`good first issue`](https://github.com/LeeYudok/claude-scaffold/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) 开始——
新增一个技术栈预设是最容易上手的任务，因为其结构已完全模板化。

## License

MIT —— 见 [LICENSE](LICENSE)。
