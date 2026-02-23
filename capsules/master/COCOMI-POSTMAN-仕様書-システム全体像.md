<!-- dest: capsules/master -->
# 📮 COCOMI Postman — システム仕様書
# 最終更新: 2026-02-23 v1.0
# 作成: アキヤ & クロちゃん（Claude Opus 4.6）

---

## 🏗️ COCOMIPostmanとは

COCOMI Postmanは、アキヤがスマホ（LINE）から一言送るだけで、
タブレットのClaude Codeがコードを書いて、テスト（CI）を通して、
完了通知までしてくれる **全自動AI開発パイプライン** です。

「語りコード（KatariCode）」— Tell, and it's built.
ノーコードの手軽さ × フルコードの自由度。
語るだけでAIがフルコードを書く、新しい開発方式。

---

## 🌐 システム構成図

```
┌─────────────┐    LINE     ┌──────────────────┐
│  📱 スマホ   │ ─────────→ │ ☁️ Cloudflare     │
│  (LINE)     │ ←───────── │   Worker v1.4     │
│  アキヤ     │   返信通知  │  (cocomi-worker)  │
└─────────────┘            └────────┬─────────┘
                                    │ GitHub API
                                    ▼
                           ┌──────────────────┐
                           │  📦 GitHub        │
                           │  cocomi-postman   │
                           │  リポジトリ       │
                           └────────┬─────────┘
                                    │ git pull
                                    ▼
┌─────────────┐  Claude    ┌──────────────────┐
│ 🎨 claude.ai │  Code実行  │  📋 タブレット    │
│ クロちゃん   │ ─設計───→ │  Termux          │
│ (設計担当)  │            │  postman.sh v2.0 │
└─────────────┘            │  Claude Code     │
                           └────────┬─────────┘
                                    │ git push
                                    ▼
                           ┌──────────────────┐
                           │  ✅ GitHub Actions │
                           │  cocomi-ci.yml    │
                           │  CI/CD テスト     │
                           └────────┬─────────┘
                                    │ LINE通知
                                    ▼
                           ┌──────────────────┐
                           │  📱 LINE通知      │
                           │  結果レポート     │
                           └──────────────────┘
```

---

## 🔧 使用サービス・ツール一覧

| サービス/ツール | 用途 | 備考 |
|---|---|---|
| **LINE Messaging API** | アキヤとの通信窓口 | Webhook受信＆返信 |
| **Cloudflare Workers** | LINE Webhook処理 | worker.js v1.4デプロイ中 |
| **GitHub** | コード保管＆中継 | cocomi-postmanリポジトリ |
| **GitHub Actions** | CI/CDテスト | cocomi-ci.yml（全7リポ共通） |
| **GitHub Pages** | アプリ公開 | maintenance-map-ap等 |
| **Termux** | タブレットのLinux環境 | シェルスクリプト実行 |
| **Claude Code** | AI実装エンジン | Termux上で動作 |
| **claude.ai** | 設計＆指示書作成 | クロちゃん（設計担当） |
| **Obsidian** | ドキュメント管理 | アキヤのナレッジベース |
| **Galaxy スマホ** | LINE操作＆音声入力 | メイン操作デバイス |
| **Galaxy タブレット** | 開発実行環境 | Termux + Claude Code |

---

## 📂 リポジトリ構成

**GitHubリポジトリ: akiyamanx/cocomi-postman**

```
~/cocomi-postman/
├── postman.sh          ← タブレット本店メイン v2.0
├── post.sh             ← スマホ支店メイン v1.6
├── config.json         ← 全体設定（※.gitignore、GitHubにはない）
├── config.example.json ← config.jsonの雛形 v2.0
├── CLAUDE.md           ← Claude Code用ルールブック v1.1
├── cocomi-repo-setup.sh← 新リポCI自動セットアップ v1.0
│
├── core/               ← 本店の分割モジュール
│   ├── executor.sh     ← 実行エンジン v2.0
│   ├── step-runner.sh  ← ステップ実行エンジン v2.0.2
│   ├── retry.sh        ← リトライ＆自動継続 v1.5
│   └── notifier.sh     ← LINE通知 v1.4
│
├── missions/           ← 指示書（プロジェクト別）
│   ├── cocomi-postman/ ← Postman自身の指示書
│   ├── genba-pro/      ← 現場Pro設備くん
│   ├── culo-chan/       ← CULOchanKAIKEIpro
│   ├── maintenance-map/← メンテナンスマップ
│   └── postman/        ← その他
│
├── capsules/           ← カプセル保管庫
│   ├── daily/          ← 日次DIFF（思い出・開発・引き継ぎ）
│   ├── master/         ← MASTERカプセル（追記方式）
│   ├── plans/          ← 企画書
│   └── ideas/          ← アイデア保管
│       ├── app/        ← アプリ関連
│       ├── business/   ← ビジネス・事業系
│       ├── cocomi/     ← COCOMIシステム改善
│       └── other/      ← 分類不明
│
├── reports/            ← 完了レポート（プロジェクト別）
├── errors/             ← エラーレポート
├── ideas/              ← アイデアメモ（post.sh用）
├── inbox/              ← 未分類ファイルの受け皿
├── templates/          ← テンプレート集
├── logs/               ← 実行ログ
└── auto-mode/          ← 自動モード設定
```

---

## 🔑 環境変数・シークレット

### Cloudflare Worker（環境変数）
| 変数名 | 内容 |
|---|---|
| LINE_CHANNEL_SECRET | LINE署名検証用シークレット |
| LINE_CHANNEL_ACCESS_TOKEN | LINE APIアクセストークン |
| GITHUB_TOKEN | GitHub Personal Access Token |

### GitHub Actions Secrets（各リポジトリ共通）
| シークレット名 | 内容 |
|---|---|
| LINE_CHANNEL_ACCESS_TOKEN | LINE通知用トークン |
| LINE_USER_ID | アキヤのLINE UserID |

### タブレット config.json
config.example.jsonをコピーして実際の値を入れる。
LINEトークンやパスなどの機密情報を含むため.gitignoreで除外。

---

## 📋 対応プロジェクト一覧

| プロジェクトID | アプリ名 | GitHubリポ | 概要 |
|---|---|---|---|
| genba-pro | 現場Pro設備くん | GenbaProSetsubikunN | 施工管理アプリ |
| culo-chan | CULOchanKAIKEIpro | CULOchanKAIKEIpro | 会計・見積アプリ |
| maintenance-map | メンテナンスマップ | maintenance-map-ap | メンテルート管理 |
| cocomi-postman | COCOMI Postman | cocomi-postman | 開発パイプライン本体 |
| cocomi-family | COCOMIファミリー | cocomi-family | COCOMIシステム全体 |

---

## 🌊 全体の処理フロー

### パターン1: テキスト指示（簡単な修正）
```
アキヤがLINEで「genba-pro: ログイン画面の色を青に変えて」と送信
  ↓
Worker受信 → プロジェクト名と指示を分離
  ↓
missions/genba-pro/M-LINE-0223-1500-ログイン画面の色を青に変えて.md を生成
  ↓
GitHub push → タブレットが git pull で検知
  ↓
Claude Code が指示書を読んで実装 → git push
  ↓
GitHub Actions CI テスト → LINE通知
```

### パターン2: ファイル指示書（複雑な修正・マルチステップ）
```
クロちゃんが <!-- dest: missions/cocomi-postman --> 付き指示書を作成
  ↓
アキヤがLINEでファイル送信
  ↓
Worker受信 → destタグ読み取り → missions/cocomi-postman/ に配置
  ↓
GitHub push → タブレットが git pull で検知
  ↓
step-runner.sh がStep 1/N を実行 → CI合格 → 自動でStep 2/N へ
  ↓
全ステップ完了 → 完了レポート生成 → LINE通知
```

### パターン3: カプセル・アイデア保管
```
アキヤがLINEで「思い出カプセル_DIFF_総合_xxx.md」を送信
  ↓
Worker受信 → ファイル名キーワード「DIFF_総合」にマッチ
  ↓
capsules/daily/ に自動配置 → GitHub push → LINE返信で確認
```

---

## 📌 バージョン履歴

| バージョン | 日付 | 主な変更 |
|---|---|---|
| Worker v1.0 | 2026-02-20 | テキスト指示→GitHub push基本機能 |
| Worker v1.1 | 2026-02-22 | ファイル受信＆カプセル自動保管 |
| Worker v1.2 | 2026-02-22 | sanitizeForFilename強化 |
| Worker v1.3 | 2026-02-23 | destタグルーティング＆アイデア一覧 |
| Worker v1.4 | 2026-02-23 | フォルダ一覧＆中身確認コマンド（Trees API） |
| Postman v2.0 | 2026-02-22 | ステップ実行対応 |
| step-runner v2.0.2 | 2026-02-22 | CI合格で自動次ステップ |
| notifier v1.4 | 2026-02-22 | ステップ進捗＆完了通知 |
| cocomi-ci.yml | 2026-02-21 | 全7リポ共通CI＆LINE通知 |
