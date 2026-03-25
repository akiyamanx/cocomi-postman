CLAUDE.md — COCOMI Postman プロジェクトルール
このファイルはClaude Codeが自動で読み込むルールブックです
最終更新: 2026-03-25 v1.4
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
│   ├── executor.sh     ← 実行エンジン v2.2
│   ├── step-runner.sh  ← ステップ実行エンジン v2.0.2
│   ├── retry.sh        ← リトライ＆自動継続エンジン v1.9（proot /tmp解決）
│   ├── logger.sh       ← ログ＆履歴 v1.0
│   ├── project-manager.sh ← プロジェクト管理 v1.0
│   ├── settings.sh     ← 設定管理 v1.0
│   ├── config-helper.py ← 設定ヘルパー v1.0
│   └── notifier.sh     ← LINE通知 v1.4
├── missions/           ← 指示書（プロジェクト別フォルダ）
├── reports/            ← 完了レポート
├── errors/             ← エラーレポート
├── capsules/           ← カプセル保管庫（LINE→Worker→GitHub自動保存）
│   ├── daily/          ← 日次DIFF
│   ├── master/         ← MASTER（追記方式）
│   ├── plans/          ← 企画書
│   └── ideas/          ← アイデア保管（app/business/cocomi/other）
├── ideas/              ← アイデアメモ（post.sh用、プロジェクト別）
├── projects/           ← プロジェクト登録簿（JSON）
├── project-maps/       ← プロジェクトマップ
├── logs/               ← 実行ログ
├── dev-capsules/       ← 開発カプセル（DIFF_DEV）保管
├── templates/          ← テンプレート集
├── auto-mode/          ← 自動モード設定
└── test-app/           ← CLAUDE.mdルール動作確認用テストアプリ
📝 config.json について
config.jsonにはLINEトークンやGitHubパスなど機密情報が含まれる。
.gitignoreで除外済みなのでGitHubにはpushされない。
新環境セットアップ時はconfig.example.jsonをコピーして値を埋める:
  cp config.example.json config.json
  # config.jsonを編集して実際のトークンやパスを入れる
🔧 開発ルール
post.sh はスマホで動くので軽量に保つ
postman.sh は機能が増えたらcore/に分割する
テンプレートは templates/ 以下で管理
git操作のエラーハンドリングを必ず入れる
Termux /tmp権限対策: proot -b $PREFIX/tmp:/tmp でClaude Codeを起動（retry.sh v1.9で自動化）
  prootが未インストールの場合: pkg install proot
  フォールバック: TMPDIR=~/tmp 前置（Bash系ツールは動作しない可能性あり）
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

## ファイル命名ルール

### 基本原則
ファイル名を見ただけで「何の内容か」が想像できる名前をつけること。
機械的なIDだけの名前は禁止。必ず内容の要約を含める。

### レポートファイル（reports/配下）
形式: R-{ミッションID}-{プロジェクト名}-{内容要約}.md
要約は日本語で、何をやったかが15文字以内でわかるように。

良い例:
- R-CONFIG-UPDATE.md
- R-LINE-0223-cocomi-postman-config更新とCLAUDE修正.md
- R-001-genba-pro-ログイン画面の色変更.md
- R-STEP-001-culo-chan-ドロップダウンバグ修正.md

悪い例（内容がわからない）:
- R-001-20260220-1121.md
- R-STEP-001-step-execution.md

### カプセルファイル（capsules/配下）

#### daily/（日次DIFF）
形式: {日付}_DIFF{種別}_{内容要約}.md
種別は「総合」「DEV」のどちらか。
内容要約にその日の主な作業内容を20文字以内で書く。

良い例:
- 2026-02-23_DIFF総合_Worker-v1.4開発とフォルダ機能.md
- 2026-02-23_DIFF-DEV_destタグルーティング実装.md
- 2026-02-22_DIFF総合_ステップ実行テスト成功.md

悪い例:
- 2026-02-22_思い出カプセル_DIFF_総合_02.md（「02」だけでは内容不明）
- 2026-02-22_開発カプセル_DIFF_DEV_postman_02.md

#### master/（MASTERカプセル）
形式: MASTER_{テーマ}_v{番号}.md
テーマにはどのシステム・アプリの記録かを書く。

良い例:
- MASTER_Postmanシステム仕様_v5.md
- MASTER_CULOchan開発記録_v3.md

悪い例:
- MASTER_v5.md（何のMASTERかわからない）

#### plans/（企画書）
形式: 企画書_{テーマ名}.md
テーマ名で何の企画かわかるように。

良い例:
- 企画書_COCOMI画像生成_Live2Dパイプライン.md
- 企画書_LINEリッチメニュー開発ナビ.md

#### ideas/（アイデア）
形式: {日付}_{カテゴリ}_{アイデア概要}.md

良い例:
- 2026-02-23_app_写真に手書きメモ重ねる機能.md
- 2026-02-23_cocomi_LINE音声入力対応.md

### ミッション指示書（missions/配下）
形式: M-{テーマ名}.md  または  M-LINE-{MMDD}-{HHmm}-{内容要約}.md
テキスト指示から自動生成する場合も、内容要約を必ず含める。

良い例:
- M-CONFIG-UPDATE.md
- M-NAMING-RULES.md
- M-LINE-0223-1500-ログイン画面の色を青に変更.md

悪い例:
- M-LINE-0223-1500.md（内容がわからない）

### 仕様書・取説（capsules/master/配下）
形式: {アプリ/システム名}-{文書種別}-{テーマ}.md

良い例:
- COCOMI-POSTMAN-仕様書-システム全体像.md
- COCOMI-POSTMAN-仕様書-Worker.md
- COCOMI-POSTMAN-取扱説明書.md
