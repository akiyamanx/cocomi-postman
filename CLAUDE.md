CLAUDE.md — COCOMI Postman プロジェクトルール
このファイルはClaude Codeが自動で読み込むルールブックです
最終更新: 2026-02-18 v1.0
🏗️ プロジェクト概要
COCOMI Postman — COCOMIファミリーの全プロジェクト開発を加速するAI開発パイプライン

スマホ支店（post.sh）: アキヤが使う司令官ツール
タブレット支店（postman.sh）: Claude Code実行を管理する本店
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
├── postman.sh          ← タブレット支店（本店）メイン
├── post.sh             ← スマホ支店メイン
├── config.json         ← 全体設定
├── CLAUDE.md           ← このファイル
├── core/               ← 本店の分割モジュール（将来）
├── projects/           ← プロジェクト登録簿（JSON）
├── missions/           ← 指示書（プロジェクト別フォルダ）
├── reports/            ← 完了レポート
├── errors/             ← エラーレポート
├── ideas/              ← アイデアメモ
├── project-maps/       ← プロジェクトマップ
├── logs/               ← 実行ログ
├── templates/          ← テンプレート集
└── auto-mode/          ← 自動モード設定（将来）
🔧 開発ルール
post.sh はスマホで動くので軽量に保つ
postman.sh は機能が増えたらcore/に分割する
テンプレートは templates/ 以下で管理
git操作のエラーハンドリングを必ず入れる
<!-- Step Execution v2.0 test - Step 2 completed -->
