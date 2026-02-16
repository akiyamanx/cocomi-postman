# CLAUDE.md — COCOMI Postman

> このファイルはClaude Codeが作業開始時に自動で読み込むルールブックです。
> プロジェクト: COCOMI Postman（郵便屋さんアプリ）
> 最終更新: 2026-02-17

---

## 🏗️ プロジェクト概要

COCOMI Postmanは、COCOMIファミリーの全プロジェクト開発を加速するための「郵便屋さん」システムです。
スマホ（司令官）→ GitHub（郵便局）→ タブレット（実行部隊）の3ノード構成。
シェルスクリプト（bash）で構築します。

## 📐 共通コーディングルール

### ファイル管理
- 1ファイル500行以内。超える場合は役割ごとに分割する
- 変更したファイルにはバージョン番号と日本語コメントを入れる
  - 例: `# v0.1追加 - ミッション受信機能`
- 各ファイルの先頭に「このファイルは何をするか」を日本語コメントで記載する
  - 例: `# このファイルは: スマホからの指示書をGitHub経由で受信する`

### コーディング規約
- シェルスクリプトは bash で記述（#!/bin/bash）
- 変数名は英語のスネークケース（例: mission_dir, report_file）
- 関数名は英語のスネークケース（例: send_mission, check_inbox）
- エラーハンドリングを必ず入れる（set -e は使わず、個別にチェック）
- ユーザー向けメッセージは日本語で表示する

### Git ルール
- コミットメッセージは日本語で書く
  - 例: `git commit -m "Phase A: CLAUDE.md初期設置"`
- mainブランチに直接pushする（個人開発のため）

## 📂 ディレクトリ構成

```
cocomi-postman/
├── CLAUDE.md               ← このファイル
├── README.md               ← プロジェクト説明
├── core/                   ← 郵便屋さん本体
│   ├── post.sh             ← スマホ支店スクリプト（Phase B）
│   ├── postman.sh          ← タブレット支店メインスクリプト（Phase B）
│   ├── receiver.sh         ← GitHub受信＆監視
│   ├── executor.sh         ← Claude Code実行制御
│   └── reporter.sh         ← レポート生成
├── missions/               ← 指示書（プロジェクト別）
│   ├── genba-pro/          ← 設備くん向け
│   ├── culo-chan/           ← CULOchan向け
│   └── postman/            ← Postman自身向け
├── reports/                ← 完了レポート（プロジェクト別）
├── errors/                 ← エラーレポート
├── ideas/                  ← アイデアメモ
├── project-maps/           ← プロジェクトマップ（自動生成）
├── templates/              ← テンプレート集
│   ├── missions/           ← 指示書テンプレート
│   ├── claude-md/          ← CLAUDE.mdテンプレート
│   └── reports/            ← レポートテンプレート
├── dev-capsules/           ← 開発カプセル保管
├── logs/                   ← 全作業ログ
└── auto-mode/              ← 自動モード用（Phase D）
```

## 🔨 技術スタック

- **言語:** bash（シェルスクリプト）
- **実行環境:** Termux（Android）
- **通信:** git push / git pull（GitHub経由）
- **AI実行:** Claude Code（`claude -p` コマンド）
- **将来のAPI:** GitHub API, Claude API, Gemini API（Phase C以降）

## ⚠️ 注意事項

- 既存コードを壊さず追加する形で実装する
- 改善提案がある場合はコメントで理由を書いてから変更する
- Termux環境（Android）で動作することを前提にする
- PC専用のコマンドや機能は使わない
