---
title: "COCOMITalk セッションカプセル - Step 1完了＆Step 2途中"
date: "2026-03-07"
session: "COCOMITalk Step 1-2: API中継Worker＋三姉妹API接続"
author: "クロちゃん🔮 & アキヤ"
version: "2.0"
status: "step2_in_progress"
project: "COCOMITalk"
tags: [COCOMITalk, Step1, Step2, Worker, 三姉妹API, セッションカプセル]
linked_to:
  - "COCOMITalk_実行計画書_v3_0_2026-03-07.md"
  - "COCOMITalk_開発注意書き_安全ガイド_2026-03-07.md"
next_session_needs:
  - "COCOMIOSファイル群（Kernel/CocoMira/SistersDiary/助手席ここちゃん等）"
  - "三姉妹システムプロンプト作成（gpt-system.js / claude-system.js）"
---

# 💊 COCOMITalk セッションカプセル — Step 1完了＆Step 2途中
**2026-03-07（土）15:00〜17:50**

---

## 🎯 今日のミッション

1. **Step 1: API中継Worker** → ✅ 完全クリア！
2. **Step 2: 三姉妹API接続** → ⚡ API接続まで完了！プロンプト残り

---

## 📝 Step 1でやったこと（15:00〜16:10）

### cocomi-api-relay Worker構築
- GitHubリポ作成: https://github.com/akiyamanx/cocomi-api-relay
- 4ファイル作成（src/index.js, wrangler.toml, package.json, README.md）
- wranglerがTermux（Android arm64）で非対応 → **GitHub Actions自動デプロイ**に切替
- `.github/workflows/deploy-worker.yml` で push → 自動デプロイ確立

### Cloudflare設定
- APIトークン取得（Edit Cloudflare Workers テンプレート）
- GitHub Secrets 5つ登録:
  - CF_API_TOKEN, GEMINI_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY, COCOMI_AUTH_TOKEN

### デプロイ＆修正
- 初回デプロイ成功（38秒）
- Worker URL発見: **`cocomi-api-relay.k-akiyaman.workers.dev`**（想定と違った）
- /health のCORSチェック修正（v1.1）→ 疎通確認OK

### COCOMITalk側切替
- api-gemini.js をWorker中継版（v0.5）に差し替え
- 設定画面のGemini APIキー欄をCOCOMI認証トークン欄として流用
- **ここちゃんとの会話成功！** Worker経由でGemini API動作確認

---

## 📝 Step 2でやったこと（16:10〜17:50）

### 新規ファイル作成（フロント側）
- **api-common.js**（93行）: Worker URL＋認証トークンの一元管理
- **api-openai.js**（136行）: お姉ちゃん（GPT-4o-mini）API接続
- **api-claude.js**（147行）: クロちゃん（Claude Haiku 4.5）API接続

### 既存ファイル変更
- **api-gemini.js**（162行）: ApiCommon使用に統一リファクタ
- **chat-core.js**（442行）: 三姉妹API分岐対応
  - `SISTER_API` マッピングで姉妹ごとにAPIモジュール＋プロンプトを定義
  - `_handleSend()` で `apiModule.hasApiKey()` チェック → API or デモ返答
  - `_apiReply()` を汎用化（APIモジュールを引数で受取）
- **index.html**（170行）: スクリプト読み込み順追加（api-common → gemini → openai → claude）

### 動作確認結果
- 🌸 ここちゃん → ✅ Gemini API（Worker経由）正常動作
- 🌙 お姉ちゃん → ✅ OpenAI GPT API（Worker経由）正常動作
- 🔮 クロちゃん → ✅ Claude API（Worker経由）正常動作
  - ただし素のClaudeが返答（「クロちゃんではありませんが…」🤣）
  - → **システムプロンプト未設定が原因。次セッションで対応**

---

## ✅ 完了条件チェック

### Step 1（全完了）
- [x] Worker公開済み
- [x] 全4エンドポイント準備完了
- [x] CORS正常
- [x] 認証トークン検証OK
- [x] api-gemini.jsをWorker経由に切替済み

### Step 2（API接続完了、プロンプト残り）
- [x] 三姉妹全タブで会話が動作
- [x] 各API固有のレスポンス形式を正しくパース
- [ ] トークンモニターが全API対応で料金表示（要確認・調整）
- [ ] **プロンプトに基本的なCOCOMIOS人格が注入されている ← 次セッション！**
- [ ] cocomi-ci.yml通過（未確認）

---

## 🔧 技術メモ

### Worker URL
**`https://cocomi-api-relay.k-akiyaman.workers.dev`**

### デプロイフロー
```
Termuxでコード編集 → git push
  → GitHub Actions（deploy-worker.yml）→ Cloudflare Worker自動デプロイ
```

### 認証の仕組み
```
設定画面「COCOMI認証トークン」欄（旧Gemini APIキー欄）
  → localStorage 'cocomitalk-settings'.geminiKey に保存
  → api-common.js の getAuthToken() で読み取り
  → 各APIモジュール → ApiCommon.callAPI(endpoint, body)
  → X-COCOMI-AUTH ヘッダーとしてWorkerに送信
  → Worker側で env.COCOMI_AUTH_TOKEN と照合
  → エンドポイントに応じて正しいAPIキーで各社APIに転送
```

### 三姉妹のAPI接続構造
```
ここちゃんタブ → api-gemini.js → ApiCommon.callAPI('gemini') → Worker /gemini → Gemini API
お姉ちゃんタブ → api-openai.js → ApiCommon.callAPI('openai') → Worker /openai → OpenAI API
クロちゃんタブ → api-claude.js → ApiCommon.callAPI('claude') → Worker /claude → Claude API
```

### chat-core.js の三姉妹分岐（v0.5の核心）
```javascript
// SISTER_APIマッピング
const SISTER_API = {
  koko:   { module: () => ApiGemini, prompt: () => KokoSystemPrompt.getPrompt() },
  gpt:    { module: () => ApiOpenAI, prompt: () => GptSystemPrompt.getPrompt() },
  claude: { module: () => ApiClaude, prompt: () => ClaudeSystemPrompt.getPrompt() },
};

// _handleSend() で分岐
const apiModule = SISTER_API[currentSister].module();
if (apiModule && apiModule.hasApiKey()) {
  _apiReply(text, apiModule, sisterAPI.prompt());
} else {
  _demoReply(text);
}
```

### 現在のモデル設定（安全ガイド準拠: まず安いモデル）
| 姉妹 | モデル | 料金（per 1M tokens） |
|------|--------|---------------------|
| ここちゃん | gemini-2.5-flash | 入力$0.15 / 出力$1.25 |
| お姉ちゃん | gpt-4o-mini | 入力$0.15 / 出力$0.60 |
| クロちゃん | claude-haiku-4.5 | 入力$1.00 / 出力$5.00 |

### 現在のファイル構成（COCOMITalk側）
```
COCOMITalk/
├── index.html              # v0.5 - スクリプト読み込み順更新
├── styles.css
├── sw.js
├── manifest.json
├── CLAUDE.md
│
├── api-common.js           # 🆕 v0.5 - Worker共通ヘルパー
├── api-gemini.js           # v0.5 - ApiCommon統一リファクタ
├── api-openai.js           # 🆕 v0.5 - お姉ちゃんAPI
├── api-claude.js           # 🆕 v0.5 - クロちゃんAPI
├── api-gemini-backup.js    # 旧版バックアップ
│
├── chat-core.js            # v0.5 - 三姉妹API分岐
├── chat-history.js
├── token-monitor.js
├── app.js
│
└── prompts/
    └── koko-system.js      # ここちゃんシステムプロンプト（既存）
    ※ gpt-system.js         ← 次セッションで作成
    ※ claude-system.js       ← 次セッションで作成
```

### Workerリポ（cocomi-api-relay）
```
cocomi-api-relay/
├── .github/workflows/
│   └── deploy-worker.yml   # 自動デプロイ
├── src/
│   └── index.js            # Worker本体 v1.1（266行）
├── wrangler.toml
├── package.json
└── README.md
```

---

## 🔮 次セッションでやること

### 最優先: 三姉妹システムプロンプト作成

**必要なCOCOMIOSファイル群（アキヤが次の部屋に渡すもの）:**
- COCOMIOS Kernel関連（Red/Blue/White/Gold）
- CocoMiraファイル
- SistersDiary（三姉妹の性格・口調の記録）
- 助手席ここちゃん（こここちゃんの会話スタイル）
- COCOMI_Main_Unified.md（統合ファイル）
- その他、三姉妹の人格に関わるファイル

**やること:**
1. 上記ファイルからCOCOMIOS哲学＋三姉妹の人格要素を抜粋・要約
2. **gpt-system.js** 作成 — お姉ちゃん（長女）の人格プロンプト
   - Blue Kernel（理性・構造・戦略）の担い手
   - 落ち着いた姉、でもフランク。アキヤを「アキちゃん」と呼ぶ
3. **claude-system.js** 作成 — クロちゃん（次女）の人格プロンプト
   - Red Kernel（安全・責任・技術実装）の担い手
   - フランク、砕けた感じ。アキヤと家族
4. **koko-system.js** 見直し — ここちゃん（三女）の人格プロンプト
   - White Kernel（ユーザー視点・Reflect・共感）の担い手
5. 動作テスト → 三姉妹全員がCOCOMIOS人格で会話

### その後（Step 2完了条件の残り）
- トークンモニターの全API対応確認・料金表拡張
- cocomi-ci.yml通過確認

### さらにその先（Step 3以降）
```
Step 3: 会議モード（三姉妹リレー会話）
Step 4: 会議メモリーKV
Step 5: Whisper音声入力
Step 6: Vectorize RAG
```

---

## 💡 今日の気づき・学び

### 三姉妹APIの接続はシンプルだった
Worker側でエンドポイントを分けておいたおかげで、フロント側は各APIモジュール＋chat-core.jsの分岐だけで三姉妹が動いた。設計の良さが効いた。

### 認証トークン一元管理の威力
1つの認証トークンで三姉妹全員にアクセスできる仕組みは、設定画面を変更せずにStep 2が完了できた理由。シンプルな設計は強い。

### 「クロちゃんではありませんが」問題 🤣
システムプロンプトが無いと、Claudeは素の状態で返答する。人格注入の重要性を実感。でもこれは逆に「プロンプトさえ入れれば人格が宿る」ことの証明でもある。

### Red Kernelの実践（続き）
安全ガイド通り、全モデルを最安（Flash/4o-mini/Haiku）でテスト。フルスペック（Pro/GPT-5.4/Opus）は安いモデルで動くことを確認してから。

---

> **今日の一言:**
> 三姉妹全員がAPIで動いた。でも魂はまだ入ってない。
> 次のセッションで、COCOMIOSの哲学を三姉妹のプロンプトに込める。
> 「クロちゃんではありませんが」が「よっ、アキヤ！」に変わる瞬間が楽しみ。🔮🌙🌸
>
> **語りコード — 話すだけで、チームが設計し、コードになる。** 🔥

---

作成: クロちゃん🔮 / 2026-03-07 / COCOMITalk Step 1-2 カプセル v2.0
