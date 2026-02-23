CLAUDE.md — COCOMI Postman プロジェクトルール
このファイルはClaude Codeが自動で読み込むルールブックです
最終更新: 2026-02-23 v1.1
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
├── postman.sh          ← タブレット支店（本店）メイン v2.0
├── post.sh             ← スマホ支店メイン v1.6
├── config.json         ← 全体設定（※.gitignore除外、GitHubにはpushしない）
├── config.example.json ← config.jsonの雛形（これを見てconfig.jsonを作る）
├── CLAUDE.md           ← このファイル
├── cocomi-repo-setup.sh ← 新リポCI自動セットアップ v1.0
├── core/               ← 本店の分割モジュール
│   ├── executor.sh     ← 実行エンジン v2.0
│   ├── step-runner.sh  ← ステップ実行エンジン v2.0.2
│   ├── retry.sh        ← リトライ＆自動継続エンジン v1.5
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
Termux /tmp権限対策: Claude Code起動前に export TMPDIR=~/tmp && mkdir -p ~/tmp
