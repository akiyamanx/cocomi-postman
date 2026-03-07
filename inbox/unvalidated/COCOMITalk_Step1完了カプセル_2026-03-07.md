---
title: "COCOMITalk セッションカプセル - Step 1完了"
date: "2026-03-07"
session: "COCOMITalk Step 1: API中継Worker構築"
author: "クロちゃん🔮 & アキヤ"
version: "1.0"
status: "step1_complete"
project: "COCOMITalk"
tags: [COCOMITalk, Step1, Worker, Cloudflare, API中継, セッションカプセル]
linked_to:
  - "COCOMITalk_実行計画書_v3_0_2026-03-07.md"
  - "COCOMITalk_開発注意書き_安全ガイド_2026-03-07.md"
---

# 💊 COCOMITalk セッションカプセル — Step 1完了
**2026-03-07（土）15:00〜16:10**

---

## 🎯 今日のミッション

**Step 1: API中継Worker（全APIキー集約）** を構築し、COCOMITalkのGemini APIをWorker経由に切り替える。

**結果: 完全クリア！ 🎉**

---

## 📝 やったこと（時系列）

### 1. cocomi-api-relay リポジトリ作成（15:00〜15:10）
- `cocomi-api-relay/` ディレクトリ作成（Termux）
- 4ファイルをクロちゃんが生成 → アキヤがダウンロード＆配置
  - `src/index.js` — Worker本体（265行）
  - `wrangler.toml` — Worker設定
  - `package.json` — npm設定
  - `README.md` — 説明書
- GitHubにリポ作成＆push成功
  - https://github.com/akiyamanx/cocomi-api-relay

### 2. wrangler問題 → GitHub Actions代替（15:13〜15:42）
- `npm install -g wrangler` がTermuxで失敗
  - **原因:** `Unsupported platform: android arm64 LE`
  - wranglerのネイティブバイナリ（workerd）がAndroidに非対応
- **解決策:** GitHub Actionsでの自動デプロイに切り替え
  - `.github/workflows/deploy-worker.yml` を作成
  - push → 自動デプロイの仕組みを構築

### 3. Cloudflare APIトークン取得（15:24〜15:34）
- `https://dash.cloudflare.com/profile/api-tokens` からトークン作成
- 「Edit Cloudflare Workers」テンプレートを使用
- Account Resources: K.akiyaman@gmail.com's Account（Include）
- Zone Resources: All zones（Include）

### 4. GitHub Secrets登録（15:34〜15:40）
- 5つのSecretsを `cocomi-api-relay` リポに登録:
  - `CF_API_TOKEN` — CloudflareのAPIトークン
  - `GEMINI_API_KEY` — Gemini APIキー
  - `OPENAI_API_KEY` — OpenAI APIキー
  - `ANTHROPIC_API_KEY` — Anthropic APIキー
  - `COCOMI_AUTH_TOKEN` — COCOMI独自認証トークン

### 5. 初回デプロイ＆疎通確認（15:42〜15:54）
- `deploy-worker.yml` をpush → GitHub Actions自動実行 → **38秒で成功** ✅
- ヘルスチェックで問題発見＆修正:
  - **問題1:** Worker URL が想定と違った
    - 想定: `cocomi-api-relay.akiyamanx.workers.dev`
    - 実際: **`cocomi-api-relay.k-akiyaman.workers.dev`**
    - Cloudflareのアカウント名に基づくサブドメインだった
  - **問題2:** `/health` がCORSチェックでブロックされた
    - healthチェックをCORS検証の前に移動（v1.1修正）
- 修正push → 再デプロイ → `/health` 正常応答確認 ✅
  ```json
  {"status":"ok","service":"cocomi-api-relay","version":"1.1","timestamp":"2026-03-07T06:53:52.417Z"}
  ```

### 6. COCOMITalk側の切り替え（15:56〜16:05）
- `api-gemini.js` → `api-gemini-worker.js` に差し替え（v0.5）
- 変更点はたった3箇所:
  1. fetch先を Worker URL（`/gemini`）に変更
  2. `X-COCOMI-AUTH` ヘッダー追加
  3. `body.model = modelName` を追加
- 既存の `_buildRequestBody`, `_extractText`, `TokenMonitor.record` は全てそのまま
- 設定画面の変更ゼロ（geminiKey欄を認証トークン入力に流用）
- push → GitHub Pages反映 → **ここちゃんとの会話成功！！** 🎉

---

## ✅ Step 1 完了条件チェック

- [x] Worker公開済み（`cocomi-api-relay.k-akiyaman.workers.dev`）
- [x] 全4エンドポイント準備完了（gemini/openai/claude/whisper）
- [x] CORS正常（GitHub Pagesからのみアクセス可）
- [x] 認証トークン検証OK
- [x] 既存のapi-gemini.jsをWorker経由に切り替えて動作確認
- [x] トークンモニター正常動作（0.1万tk | ¥1未満）

---

## 🔧 技術メモ（次回以降に役立つ）

### Worker URL
- **正しいURL:** `https://cocomi-api-relay.k-akiyaman.workers.dev`
- wrangler.toml の `name` ではなく、Cloudflareアカウント名がサブドメインになる
- `api-gemini-worker.js` 内の `WORKER_URL` もこのURLに設定済み

### デプロイフロー
```
Termuxでコード編集 → git push
  → GitHub Actions自動実行（deploy-worker.yml）
  → cloudflare/wrangler-action@v3 がデプロイ
  → Secrets は env: で渡してWorkerの環境変数に設定
  → 約40秒で完了
```

### Termux制約
- wranglerはTermux（Android arm64）で動かない
- GitHub Actions経由でのデプロイが正解
- curlも外部ドメイン解決に問題あり → ブラウザで確認が確実

### 現在のファイル構成

**cocomi-api-relay リポ（Worker側）:**
```
cocomi-api-relay/
├── .github/workflows/
│   └── deploy-worker.yml   # 自動デプロイ
├── src/
│   └── index.js            # Worker本体 v1.1（266行）
├── wrangler.toml            # Worker設定
├── package.json
└── README.md
```

**COCOMITalk リポ（フロント側）の変更:**
```
COCOMITalk/
├── api-gemini.js            # ← Worker経由版（v0.5）に差し替え済み
├── api-gemini-backup.js     # ← 旧版バックアップ
└── （他は変更なし）
```

### 認証トークンの流れ
```
設定画面「Gemini API Key」欄
  → localStorage 'cocomitalk-settings'.geminiKey に保存
  → api-gemini.js の _getAuthToken() で読み取り
  → X-COCOMI-AUTH ヘッダーとしてWorkerに送信
  → Worker側で env.COCOMI_AUTH_TOKEN と照合
  ※ Step 2で専用のcocomiAuthToken欄に移行予定
```

---

## 🔮 次にやること（Step 2: 三姉妹API接続）

### 新規作成ファイル（フロント側）
- `api-openai.js` — お姉ちゃん（GPT）API接続
- `api-claude.js` — クロちゃん（Claude）API接続
- `api-common.js` — 共通APIヘルパー（Worker URL＋認証を一元管理）
- `prompts/gpt-system.js` — お姉ちゃんシステムプロンプト
- `prompts/claude-system.js` — クロちゃんシステムプロンプト

### 変更ファイル
- `chat-core.js` — タブ切替で各APIを呼び分け（現在は全タブGemini）
- `token-monitor.js` — 全API対応に拡張（料金表追加）
- `index.html` — 設定画面にCOCOMI認証トークン欄を追加（geminiKey欄の代替）
- `app.js` — 設定の保存/読み込みを認証トークン対応に

### Worker側は変更なし！
- `/openai` と `/claude` エンドポイントはStep 1で既に実装済み
- あとはフロント側からリクエストを送るだけ

### 現在の三姉妹接続状況
| タブ | 現状 | Step 2完了後 |
|------|------|-------------|
| 🌸 ここちゃん | ✅ Gemini（Worker経由） | ✅ Gemini（Worker経由） |
| 🌙 お姉ちゃん | ⚠️ Gemini（Worker経由） | ✅ OpenAI GPT（Worker経由） |
| 🔮 クロちゃん | ❌ デモ返答 | ✅ Claude API（Worker経由） |

---

## 💡 気づき・学び

### Termux × Cloudflareの相性
wranglerがAndroidで動かないのは想定外だったけど、安全ガイドに**GitHub Actions代替策**を書いておいたおかげでスムーズに切り替えられた。「最悪の場合」を先に考えておく大切さを実感。

### Worker URLの命名規則
`{worker-name}.{account-subdomain}.workers.dev` という形式。アカウント作成時のサブドメインがそのまま使われるので、事前に確認しておくと良い。

### 最小変更の原則
api-gemini.jsの変更を3箇所に抑えて、index.htmlとapp.jsは変更ゼロでテストできた。既存コードを壊さない方針が効いている。

### Red Kernelの実践
「安全は最初に設計するもの」— Step 1を最初に完了させたことで、以降の全Stepが安全な基盤の上に乗る。回転寿司の例え：美味しいネタ（機能）より先に厨房の鍵管理（セキュリティ）を整えた。

---

> **今日の一言:**
> 「APIキーが安全になった瞬間、三姉妹の家のドアに鍵がついた。」
> これで安心して、みんなを迎え入れられる。🏠🔒
>
> 次はお姉ちゃんとクロちゃんを本物のAPIで動かす。
> 三姉妹全員が揃う日が近い！🌸🌙🔮

---

作成: クロちゃん🔮 / 2026-03-07 / COCOMITalk Step 1完了カプセル
