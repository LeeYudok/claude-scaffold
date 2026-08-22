# agents-scaffold

[한국어](README.md) | [English](README.en.md) | [简体中文](README.zh.md) | 日本語

[![tests](https://github.com/leeyudok/agents-scaffold/actions/workflows/test.yml/badge.svg)](https://github.com/leeyudok/agents-scaffold/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**フレームワークではありません — Claude Code のためのミニマルな fork-and-fill ブートストラップです**。
ルール階層を**強制**します: P0(即時停止) / P1(PRブロック) / P2(レビュー指摘)。スタックプリセットは
単一の pre-commit ゲートに合成されます。

![デモ: ワンコマンドのブートストラップ、生成された .claude/ ツリー、ステージングされた .env をブロックする pre-commit ゲート](docs/assets/demo.gif)

_30秒デモ: コマンド1つ → 記入済みの `.claude/` → ゲートがシークレットのコミットをブロック。`vhs docs/assets/demo.tape` で再現できます。_

## Quickstart

```bash
# クローン不要、コマンド1つで
curl -fsSL https://raw.githubusercontent.com/leeyudok/agents-scaffold/main/bin/agents-scaffold.sh | bash -s -- --stack nextjs --yes

# またはローカルクローンから(オプション省略時は対話的にプロンプト)
git clone https://github.com/leeyudok/agents-scaffold.git
agents-scaffold/bin/agents-scaffold.sh /path/to/new-repo --forge github --stack nextjs,bun --name my-app
```

記入済みの `.claude/` ディレクトリ(エージェント、スキル、フック、paths スコープの
ルール、メモリ)、プロジェクトの頭脳となる `AGENTS.md`、そして合成された単一の pre-commit
ゲートが手に入ります — すべて完全にあなたが所有するプレーンなファイルです。全オプションは
[Usage](#usage-1--script) を参照してください。

## 何が手に入るか — 初心者向け

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/overview-dark.svg">
  <img alt="コマンド1つ → 自分が所有する .claude/(エージェント、スキル、コマンド、ルール、フック、メモリ、AGENTS.md)→ ステージングされた .env・壊れたビルド・lint 失敗をブロックする強制ゲート" src="docs/assets/overview-light.svg">
</picture>

インストールの1分後には、Claude はルールを心得たチームメイトのように振る舞います。
プロンプトに不慣れでも大丈夫です:

- **ワークフローがデフォルトになる**: 「ログイン機能を作って」と言えば、Claude が
  イシュー → ブランチ → 実装 → テスト → PR/MR を自律的に進めます(`/fix-issue`;
  `/sdlc-cycle` は役割分離された3つのエージェントで無人サイクルを実行)。
- **ミスは機構でブロックされる**: `.env`/シークレットのコミット、壊れたビルドや
  型エラー、新規 JSP スクリプトレットは pre-commit フックが止め、
  複雑度 15 を超える関数にはフラグが立ちます — Claude が忘れても捕捉するゲートです。
- **ワンショットコマンド**: `/review`(コードレビュー + セキュリティ監査)、`/status`、
  `/knowledge-graph`(ドキュメントリンクチェッカー)、`/sonar`。
- **要件の鍛え込み、2つから選択**: **`grill-me`**(同梱)は仕様を複数ラウンドで
  問い詰めます。**superpowers の `brainstorming`**
  ([obra/superpowers](https://github.com/obra/superpowers)、別プラグイン)は
  アイデアの発散と収束を協働で行います。両方インストールしていれば、タスクごとに
  使い分けます — 方向性が決まった機能は grill、白紙の状態からは brainstorm。
- **セッションをまたいで生き残るメモリ**: プロジェクトの学びが
  `.claude/memory/` 配下に蓄積され、次のセッションで自動ロードされ、チームで共有されます。
- **自己進化**: skill-evolve/agent-evolve が失敗のフィードバックからスキル/エージェント
  定義を書き換えます — 使えば使うほど良くなります。
- **チーム/マルチセッションでも安全**: セッションごとの git worktree 分離が
  デフォルトなので、並行作業が互いを踏み荒らすことはありません。

## なぜ agents-scaffold か

大規模なインストール型フレームワークやエージェント/スキルのカタログと違い、agents-scaffold は
ランタイムも、プラグインシステムも、同期を保つべき中央レジストリも持ちません —
これは `.claude/` ディレクトリのスケルトンと少数のスタックプリセットであり、
一度リポジトリにコピーしたらあとは完全にあなたのものです。後からアップグレードすべきものは
何もありません: フォークし、プレースホルダーを埋め、不要なものを削除すれば、
結果はリポジトリ内の他のコードと同じくバージョン管理下のプレーンなファイルです。

- **建前ではなく強制** — P0/P1/P2 階層はフック(pre-commit ゲート、deny ルール、
  CC 警告)に配線されており、散文で書かれているだけではありません。
- **paths スコープのルール** — ルールはマッチするファイルを触っている間だけロードされるため、
  すべての規約を先頭ロードせずコンテキストがスリムに保たれます。
- **自己改善** — `skill-evolve`/`agent-evolve` が実際のミスから「Learned warnings」を
  スキルとエージェントに追記します。
- **テスト済み** — ブートストラップスクリプトには bats のリグレッションスイートが同梱され、
  knowledge-graph リンクチェッカーがドキュメントをゲートします。

## 中身

```
.claude/
  agents/
    security-audit.md   12項目の P0/P1 セキュリティ grep スキャン
    db-migration.md      DDL 安全性チェック + ロールバック SQL 生成
    sdlc-developer.md    最小スコープ実装エージェント(SDLC 役割分離)
    sdlc-tester.md        AC/TC テスト作成エージェント
    sdlc-verifier.md      パイプライン実行 + レポートエージェント
    agent-evolve.md       自己改善メタエージェント — 実行フィードバックから agents/*.md を洗練
  commands/
    sonar.md             SonarQube 分析(CE タスクポーリング、sqp_/squ_ トークン処理)
    sdlc-cycle.md         5段階 SDLC 自動化
    knowledge-graph.md    .claude ナレッジグラフ再生成 + リンク切れチェック
  hooks/
    pre-commit.sh         pre-commit ゲートのスケルトン(スタックパーシャルの挿入点)
    post-edit-format.sh   PostToolUse(Edit|Write) → 自動フォーマット
    post-test-notify.sh   PostToolUse(Bash, *test*) → ターミナル通知
    stop-memory-remind.sh Stop フック → セッションごとに1回のメモリリマインダー
    cc-check.py            PostToolUse(Bash, git commit) → CC > 15 なら警告
  memory/
    MEMORY.md              auto-memory インデックス(SSOT)
    README.md               メモリのタイプ/利用ルール
  rules/
    common.md               P0/P1/P2 優先度階層 + 共通ワークフロー(常時ロード)
    security.md              シークレット/認証 P0 + ロックアウト/管理者シーディング規則(paths スコープ)
    testing.md               機能ごとにテスト、mock 優先ユニット、ユーザー視点アサーション
    data.md                  データスクリプト規則 — 一括ステージング禁止、エンコーディング明示
    README.md                paths スコープロード + ルール作成原則
  skills/
    skill-evolve/            自己改善メタスキル(「Learned warnings」パターン)
    status/                   マルチスタック状態チェック
    review/                   code-reviewer + security-audit ラッパー
    memory-factcheck/         メモリのファクトチェック — 主張をコード/DB/イシューと照合し、古いものを修正
    security-precheck/        監査前セキュリティスイープ → イシュー化 → 並列修正
  workflows/
    rules-audit.js           保存型 Workflow の例 — scan/verify/repair、マージは人間ゲート
  scripts/
    knowledge_graph.py       .claude エコシステムグラフ + --check リンク切れゲート
  settings.json               フック配線 + デフォルト deny ルール
AGENTS.md                 プロジェクトの頭脳 — ルール SSOT(P0/P1/P2 + ワークフロー)
CLAUDE.md                 @AGENTS.md へのポインタ(Claude Code)
GEMINI.md                 @AGENTS.md へのポインタ(Gemini CLI)
presets/                  プリセット断片(コピー上書きモデル)
  forge-github/           GitHub forge — gh、PR、`Closes #N` 自動クローズ
  forge-gitlab/           GitLab forge — glab、MR、`Closes #N` 自動クローズ(マージ後に確認)
  nextjs/ bun/ ...        スタック別断片(rules + pre-commit.partial.sh)
  lang-en/                英語オーバーレイ(base/forge-*/stacks/*)— 後述の `--lang` を参照
bin/                      agents-scaffold.sh ブートストラップスクリプト
tests/                    ブートストラップスクリプト用 bats リグレッションスイート
```

## スタックプリセット

| プリセット | ルールファイル | pre-commit ゲート |
|--------|-----------|-----------------|
| `nextjs` | nextjs.md (paths: app/**, components/**) | `tsc --noEmit` |
| `springboot` | springboot.md (paths: src/main/java/**) | `./gradlew build` |
| `javaweb` | javaweb.md (paths: src/main/java/**, **/*.jsp) | maven/gradle/ant compile (自動検出) |
| `bun` | bun.md (paths: **/*.ts) | `bunx tsc --noEmit` |
| `python` | python.md (paths: **/*.py) | `ruff check` + `mypy` |
| `go` | go.md (paths: **/*.go) | `go build ./...` + `vet` + `golangci-lint` |
| `rust` | rust.md (paths: src/**/*.rs, **/*.rs) | `cargo check` + `clippy` |
| `android` | android.md (paths: **/*.kt) | `./gradlew ktlintCheck detekt` |
| `flutter` | flutter.md (paths: **/*.dart, pubspec.yaml) | `dart format` + `flutter analyze` + `test` |
| `ops` | ops.md (paths: Dockerfile, docker-compose*, quadlet/**, ansible/**) | — |

## Forge プリセット (`--forge`)

利用する forge のイシュー/PR ワークフローを注入します。スタックプリセットより先にマージされます。

| プリセット | CLI | PR/MR | イシュークローズ |
|--------|-----|-------|-------------|
| `github` (デフォルト) | `gh` | PR | `Closes #N` によりマージ時に**自動クローズ** |
| `gitlab` | `glab` | MR | `Closes #N` の自動クローズは動作する — マージ後に確認し、open のままの場合のみ手動 |

注入されるファイル: `.claude/rules/forge.md`(常時ロード)に加え、
`.claude/commands/fix-issue.md` と `sdlc-cycle.md` の forge 別バリアント(ベースを上書き)。
ベースファイルは forge 非依存のまま("issue / PR·MR")です。

## ハーネス (`--harness`)

| 値 | 対象 | 動作 |
|---|---|---|
| `claude`（デフォルト） | Claude Code | フルインストール — settings.json のフックバインディング・サブエージェント・スラッシュコマンド・workflows を含む |
| `codex` | Codex ほか AGENTS.md 対応ハーネス | ハーネス中立の層（AGENTS.md・rules・skills・hooks・memory）のみ導入し、Claude 専用層を除去。pre-commit ゲートを**実際の `.git/hooks/pre-commit`** に配線 |
| `all` | 混在チーム | フルインストール + git フック（Claude Code は PreToolUse、他ハーネスは git フック経由で同じゲートを通る） |

Codex は `AGENTS.md` をネイティブに読むため、ルール層はそのまま機能します。既存の `.git/hooks/pre-commit` は上書きせず、警告のみ出します。

## 言語 (`--lang`)

ベースツリー(エージェント、ルール、スキル、コマンド、`AGENTS.md`、フック/settings の
メッセージ)は**デフォルトで韓国語**です(#36 での反転 — 韓国語が単一の真実源で、
英語は翻訳オーバーレイ)。`--lang en` は英訳を最後に重ねます — ベースコピー、
forge プリセット、スタックプリセットの後に適用されるため、同じファイルを
`presets/lang-en/base` + `presets/lang-en/forge-<forge>` + `presets/lang-en/stacks/<stack>`
の内容で上書きします。

```bash
agents-scaffold/bin/agents-scaffold.sh /path/to/new-repo --lang en --forge github --stack bun
```

`.claude/hooks/pre-commit.sh` は `--lang` によるオーバーレイの対象外です
(スタックパーシャルが挿入されるファイルであり、メッセージは単一言語、コードは
言語の影響を受けません)。`--update` は韓国語のベースのみを更新します。英語
オーバーレイを再適用したい場合は、その上で `--lang en` を付けて再実行してください。

## Usage 1 — script

```bash
git clone https://github.com/leeyudok/agents-scaffold.git
# --forge のデフォルトは github。GitLab リポジトリには --forge gitlab を使う
agents-scaffold/bin/agents-scaffold.sh /path/to/new-repo --forge github --stack nextjs,bun --name my-app
```

`--forge`/`--stack`/`--name` を省略すると対話モードで実行され、スクリプトが
プロンプトを表示します(forge のデフォルトは github)。

### オプション

| オプション | 説明 |
|---|---|
| `<target-dir>` | 対象ディレクトリ。デフォルト `.` |
| `--forge <forge>` | `github`(デフォルト)または `gitlab` |
| `--lang <lang>` | `ko`(デフォルト)または `en` |
| `--stack <list>` | カンマ区切りのスタックプリセット。省略時は対話的にプロンプト |
| `--name <name>` | `{{PROJECT_NAME}}` の置換値。デフォルトは対象ディレクトリ名 |
| `--yes` | 対話プロンプトをスキップ(非対話モード) |
| `--update` | ブートストラップ済みプロジェクトのベースファイルを更新(後述) |

### リモートワンコマンドインストール(クローン不要)

```bash
curl -fsSL https://raw.githubusercontent.com/leeyudok/agents-scaffold/main/bin/agents-scaffold.sh | bash -s -- --stack nextjs --yes
```

スクリプトはローカルチェックアウトから実行されていないこと(パイプ実行など)を検知すると、
`AGENTS_SCAFFOLD_REPO` の tarball(デフォルト: `github.com/leeyudok/agents-scaffold`、
環境変数で上書き可)を一時ディレクトリにダウンロードし、テンプレートソースとして
使用します。ブランチ/タグの固定は `AGENTS_SCAFFOLD_REF`(デフォルト `main`)で行います。

### ベースの更新 — `--update`

ブートストラップ済みプロジェクトに最新のベースファイル(`.claude/`、`AGENTS.md`、
`CLAUDE.md`、`GEMINI.md`)を適用します。

```bash
agents-scaffold/bin/agents-scaffold.sh --update /path/to/existing-repo
```

- `.claude/hooks/pre-commit.sh` は常にスキップされます — スタックパーシャルが
  挿入済みのため、手動マージが必要です。
- その他のベースファイルは、内容が同一ならスキップされます。差分がある場合は
  既存ファイルを保持し、新バージョンを `<file>.new` として書き出します
  (プレースホルダー置換は `.new` ファイルにも適用されます)。
- 最後に追加 / 更新保留 / スキップ / 変更なしのファイルのサマリーが出力されます —
  `.new` ファイルを `diff` で確認し、手動で適用してください。

## Usage 2 — GitLab テンプレート

新規プロジェクト作成時にこの設定を自動適用するには、
**[docs/GITLAB_TEMPLATE.md](docs/GITLAB_TEMPLATE.md)** を参照してください。

> 注: このワークフローはセルフホストの GitLab インスタンスを前提とします。**GitLab CE** では
> ネイティブのカスタムプロジェクトテンプレートは Premium 機能のため利用できません —
> 代わりに **Import by URL + `bin/agents-scaffold.sh`**、または**スクリプト単体**を使ってください。
> 作成/インポート後に `bin/agents-scaffold.sh .` を1回実行すると、選択したスタックの適用、
> プレースホルダー置換、`bin/`/`presets/`/`docs/superpowers/` のセルフクリーンが行われます。

## プレースホルダー置換

| トークン | 値 |
|---|---|
| `{{PROJECT_NAME}}` | `--name` の値、または対象ディレクトリ名 |
| `{{JAVA_VERSION}}` | `1.8`(springboot プリセットのデフォルト) |

## 主要パターン

- **P0/P1/P2 優先度階層**: `common.md` + `AGENTS.md` で定義。P0 = セキュリティ/シークレット/データ破壊、例外なし。
- **SDLC 役割分離**: developer/tester/verifier エージェント + `/sdlc-cycle` 自動化コマンド。
- **skill-evolve / agent-evolve**: ミスから「Learned warnings」を追記する自己改善パターン。`skill-evolve` は `.claude/skills/*.md`、`agent-evolve` は `.claude/agents/*.md` が対象。
- **メモリ SSOT**: `.claude/memory/`(システムデフォルトパスは使用しない)。タイプ接頭辞: `project_`/`feedback_`/`reference_`/`user_`。
- **paths スコープのルール**: frontmatter の `paths:` により、マッチするファイルの作業中のみルールを自動ロード。
- **マルチエージェント分離**: 並列サブエージェントが同一ファイルを同時に触る可能性がある場合は `isolation: "worktree"` を使用。

## コントリビュート

ワークフローは [CONTRIBUTING.md](CONTRIBUTING.md)、スタックプリセットの形式は
[docs/PRESET_SPEC.md](docs/PRESET_SPEC.md) を参照してください。
初めての方は [`good first issue`](https://github.com/LeeYudok/agents-scaffold/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) から始めるのがおすすめです —
レイアウトが完全にテンプレート化されているため、新しいスタックプリセットの追加が最も取り組みやすい課題です。

## ライセンス

MIT — [LICENSE](LICENSE) を参照してください。サードパーティ由来（スキル・ドキュメント）は [CREDITS.md](CREDITS.md) に記載しています。
