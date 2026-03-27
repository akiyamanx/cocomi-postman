CLAUDE.md — COCOMI Postman プロジェクトルール
このファイルはClaude Codeが自動で読み込むルールブックです
最終更新: 2026-03-27 v1.5
🏗️ プロジェクト概要
COCOMI Postman — COCOMIファミリーの全プロジェクト開発を加速するAI開発パイプライン

スマホ支店（post.sh）: アキヤが使う司令官ツール
タブレット支店（postman.sh）: Claude Code実行を管理する本店
Cloudflare Worker（cocomi-worker）: LINE Webhook受信→GitHub push
GitHub: 郵便局（全通信を中継）
設計: クロちゃん（Claude Opus / claude.ai）
実装: Claude Code（Termux）
📐 コーディングルール
シェルスクリプト
各ファイルは500行以内（超えそうならsource分割）
ファイル先頭に日本語コメントで役割を記載
変更箇所にバージョン番号と日本語コメント
コミットメッセージは日本語で絵文字付き
JSON設定ファイル
_commentフィールドで説明を入れる
日本語の値はそのまま日本語で
📂 ファイル構成
~/cocomi-postman/
├── postman.sh          ← タブレット支店（本店）メイン v2.5
├── post.sh             ← スマホ支店メイン v1.7
├── config.json         ← 全体設定（※.gitignore除外、GitHubにはpushしない）
├── config.example.json ← config.jsonの雛形（これを見てconfig.jsonを作る）
├── CLAUDE.md           ← このファイル
├── cocomi-repo-setup.sh ← 新リポCI自動セットアップ v1.0
├── core/               ← 本店の分割モジュール
│   ├── executor.sh     ← 実行エンジン v2.3
│   ├── step-runner.sh  ← ステップ実行エンジン v3.0
│   ├── step-pattern.sh ← ステップパターン実行エンジン v1.0（条件分岐＋エスカレーション）
│   ├── escalation.sh   ← エスカレーション機能 v1.0（Brave Search＋三姉妹会議）
│   ├── retry.sh        ← リトライ＆自動継続エンジン v1.9（proot /tmp解決）
│   ├── logger.sh       ← ログ＆履歴 v1.0
│   ├── project-manager.sh ← プロジェクト管理 v1.0
│   ├── settings.sh     ← 設定管理 v1.0
│   ├── config-helper.py ← 設定ヘルパー v1.0
│   └── notifier.sh     ← LINE通知 v1.4
├── missions/           ← 指示書（プロジェクト別フォルダ）
├── reports/            ← 完了レポート
├── errors/             ← エラーレポート
├── capsules/           ← カプセル保管庫
├── ideas/              ← アイデアメモ
├── projects/           ← プロジェクト登録簿
├── project-maps/       ← プロジェクトマップ
├── logs/               ← 実行ログ
├── dev-capsules/       ← 開発カプセル保管
├── templates/          ← テンプレート集
├── auto-mode/          ← 自動モード設定
└── test-app/           ← テストアプリ
📝 config.json について
config.jsonにはLINEトークンやGitHubパスなど機密情報が含まれる。
.gitignoreで除外済みなのでGitHubにはpushされない。
新環境セットアップ時はconfig.example.jsonをコピーして値を埋める:
  cp config.example.json config.json
🔧 開発ルール
post.sh はスマホで動くので軽量に保つ
postman.sh は機能が増えたらcore/に分割する
テンプレートは templates/ 以下で管理
git操作のエラーハンドリングを必ず入れる
Termux /tmp権限対策: proot -b $PREFIX/tmp:/tmp でClaude Codeを起動（retry.sh v1.9で自動化）
  prootが未インストールの場合: pkg install proot
  参考: https://github.com/anthropics/claude-code/issues/18342

## 🔐 Claude Code 3層セキュリティ（v1.4追加）

Claude Codeには3つのセキュリティレイヤーがある:

Layer 1（/tmp権限）: Node.jsが/tmpにアクセスする問題 → proot -b で解決済み
Layer 2（Tool permissions）: Bashツール使用可否 → settings.jsonで全開放済み
Layer 3（Built-in sandbox）: Bashでのファイルシステム変更はハードコードでブロック → 突破不可、仕様

重要: Layer 3により mkdir/rm/cp 等のBashコマンドはブロックされるが、Write/Editツールは自由に使える。
コード修正タスクはWrite/Editで完結させること。ファイル作成もWriteで行う。

## 📬 MCP経由パイプライン（v1.4追加）

指示書の受け取りから実行までの流れ:
1. クロちゃん（claude.ai）がMCP github_push_fileで missions/ に指示書をpush
2. タブレットのpostman.sh自動モードがgit pullで指示書を検出
3. retry.sh がproot方式でClaude Codeを起動
4. Claude Codeが指示書を読んでWrite/Editで実行
5. 完了後postman.shがgit push → クロちゃんがMCPでレポート確認

指示書のルール:
- 先頭に <!-- mission: プロジェクトID --> が必須
- ファイル名: M-{テーマ名}.md
- Write/Editで完結するタスクを書く（Bash書き込み系は避ける）

## 🔀 ステップパターン指示書（v1.5追加）

アキヤ発案の条件分岐型指示書。「ダメだったら次のパターン」を実現する。

### 記法
```markdown
### Step 1/4: まずこのアプローチを試す
<!-- on-fail: next -->
<!-- on-success: step-3 -->
（Claude Codeへの指示）

### Step 2/4: 別のアプローチを試す（フォールバック）
<!-- on-fail: next -->
<!-- on-success: step-3 -->

### Step 3/4: Brave Searchで解決策を検索
<!-- on-fail: next -->
<!-- type: search -->
<!-- query: 検索キーワード -->

### Step 4/4: 三姉妹会議に問題を投げる
<!-- on-fail: stop -->
<!-- type: meeting -->
<!-- grade: standard -->
```

### メタデータタグ一覧
| タグ | 値 | 説明 |
|------|-----|------|
| on-fail | next / stop / step-N | 失敗時の遷移先（デフォルト: stop） |
| on-success | next / step-N | 成功時の遷移先（デフォルト: next） |
| type | execute / search / meeting | ステップの種類（デフォルト: execute） |
| query | 検索文字列 | type: search 時のBrave Search検索クエリ |
| grade | lite / standard / full | type: meeting 時の会議グレード（デフォルト: standard） |

### 動作の流れ
- on-fail: タグがある指示書は自動でパターンモードになる
- on-fail: タグがない従来の指示書はそのまま一本道で実行（後方互換）
- type: search はcocomi-api-relay経由でBrave Search APIを叩く
- type: meeting はcocomi-api-relay経由で三姉妹会議を開催する
- 検索/会議の結果は次のステップに自動注入される

### 実装ファイル
- core/step-runner.sh v3.0 — has_step_pattern()判定
- core/step-pattern.sh v1.0 — 条件分岐付き実行ループ
- core/escalation.sh v1.0 — Brave Search＋三姉妹会議

## ファイル命名ルール

### 基本原則
ファイル名を見ただけで「何の内容か」が想像できる名前をつけること。
機械的なIDだけの名前は禁止。必ず内容の要約を含める。

### レポートファイル（reports/配下）
形式: R-{ミッションID}-{プロジェクト名}-{内容要約}.md

### カプセルファイル（capsules/配下）
daily/: {日付}_DIFF{種別}_{内容要約}.md
master/: MASTER_{テーマ}_v{番号}.md
plans/: 企画書_{テーマ名}.md
ideas/: {日付}_{カテゴリ}_{アイデア概要}.md

### ミッション指示書（missions/配下）
形式: M-{テーマ名}.md
