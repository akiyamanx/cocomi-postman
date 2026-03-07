---
title: "COCOMITalk 実行計画書 v3.0"
subtitle: "Phase 2-6 統合実装ガイド"
date: "2026-03-07"
author: "クロちゃん🔮 & アキヤ"
version: "3.0"
status: "ready_to_execute"
project: "COCOMITalk"
tags: [COCOMITalk, 実行計画, Phase2-6, Worker, Whisper, Vectorize, RAG]
linked_to:
  - "COCOMITalk_v3_0_COCOMIOS_Philosophy_2026-03-07.docx"
  - "COCOMIOS_究極構想_ハンズフリー開発環境.md"
---

# 🎯 COCOMITalk 実行計画書 v3.0

**Phase 2〜6 統合実装ガイド — 自作サーバー不要・現環境で全部やる版**

---

## 📋 前提条件（アキヤの現在の環境）

| 項目 | 内容 |
|------|------|
| デバイス | Galaxy スマホ＋タブレット |
| 開発環境 | Termux + Claude Code |
| ホスティング | GitHub Pages（無料） |
| サーバーレス | Cloudflare Worker + KV（無料枠 → 有料$5/月に移行予定） |
| 自動化 | COCOMI Postman Worker v2.5（稼働中） |
| CI/CD | COCOMI CI（cocomi-ci.yml）GitHub Actions |
| ソース管理 | GitHub（akiyamanx） |
| 現在のCOCOMITalk | v0.4（Gemini API接続済み、トークンモニター稼働） |

---

## 💰 追加コスト見積もり

| 項目 | 月額 | 備考 |
|------|------|------|
| Cloudflare Workers有料プラン | $5（約750円） | Vectorize利用に必要 |
| Whisper API（OpenAI） | ~$5（約750円） | 1日30分音声利用想定 |
| Vectorize従量課金 | ~$0.50以下 | 1万ベクトル＋月3万クエリ程度 |
| 既存API料金（三姉妹） | 2,600-6,000円 | v3.0企画書の試算 |
| **合計** | **約4,100-7,500円/月** | フル稼働時 |

---

## 🗺️ 全体ロードマップ

```
Step 1: API中継Worker ─────────────────────┐
Step 2: 三姉妹API接続 ──┐                  │
Step 3: 会議モード ──────┤  同時進行で攻める │
Step 4: 会議メモリーKV ──┘                  │
Step 5: Whisper音声入力 ────────────────────┤
Step 6: Vectorize RAG ─────────────────────┘
```

**想定期間: 各Step 1-2週間 → 全体2-3ヶ月でv1.0到達**

---

# 📦 Step 1: API中継Worker（全APIキー集約）

## 目的
フロントエンド（GitHub Pages）からAPIキーを完全に隠す。
全てのAPI呼び出しをCloudflare Worker経由にする。

## 新規ファイル

```
cocomi-api-relay/
├── wrangler.toml           # Worker設定（KVバインド含む）
├── src/
│   └── index.js            # メインWorkerスクリプト
├── package.json
└── README.md
```

## Worker設計（src/index.js）

```
リクエストフロー:
フロントエンド → https://api-relay.akiyamanx.workers.dev/gemini
              → https://api-relay.akiyamanx.workers.dev/openai
              → https://api-relay.akiyamanx.workers.dev/claude
              → https://api-relay.akiyamanx.workers.dev/whisper
```

### エンドポイント一覧

| パス | 転送先 | 用途 |
|------|--------|------|
| `POST /gemini` | `https://generativelanguage.googleapis.com/v1beta/...` | ここちゃん（Gemini） |
| `POST /openai` | `https://api.openai.com/v1/chat/completions` | お姉ちゃん（GPT） |
| `POST /claude` | `https://api.anthropic.com/v1/messages` | クロちゃん（Claude） |
| `POST /whisper` | `https://api.openai.com/v1/audio/transcriptions` | 音声認識 |
| `GET /health` | - | ヘルスチェック |

### セキュリティ

- APIキーはWorkerの環境変数（Secrets）に保存
  - `GEMINI_API_KEY`
  - `OPENAI_API_KEY`
  - `ANTHROPIC_API_KEY`
- CORS設定: COCOMITalkのGitHub PagesドメインのみAllowする
- リクエストにはシンプルな認証トークン（`X-COCOMI-AUTH`ヘッダー）を付ける
  - トークンもWorkerのSecret管理
  - フロントエンドには認証トークンだけ持たせる（APIキーは持たせない）

### Worker コード概要

```javascript
// src/index.js 概要（実際の実装時に詳細化）

export default {
  async fetch(request, env) {
    // 1. CORS チェック
    // 2. X-COCOMI-AUTH 認証チェック
    // 3. パスによるルーティング
    //    /gemini → Gemini API転送
    //    /openai → OpenAI API転送
    //    /claude → Anthropic API転送
    //    /whisper → OpenAI Whisper API転送
    // 4. レスポンス返却（usageMetadata含む）
  }
};
```

### wrangler.toml

```toml
name = "cocomi-api-relay"
main = "src/index.js"
compatibility_date = "2026-03-07"

[vars]
ALLOWED_ORIGIN = "https://akiyamanx.github.io"

# Secretsはwrangler secretコマンドで設定
# wrangler secret put GEMINI_API_KEY
# wrangler secret put OPENAI_API_KEY
# wrangler secret put ANTHROPIC_API_KEY
# wrangler secret put COCOMI_AUTH_TOKEN
```

### デプロイ手順

```bash
# Termuxで実行
cd cocomi-api-relay
npm install
wrangler secret put GEMINI_API_KEY
wrangler secret put OPENAI_API_KEY
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put COCOMI_AUTH_TOKEN
wrangler deploy
```

### 完了条件
- [ ] Worker公開済み
- [ ] 全4エンドポイント動作確認
- [ ] CORS正常（GitHub Pagesからのみアクセス可）
- [ ] 認証トークン検証OK
- [ ] 既存のapi-gemini.jsをWorker経由に切り替えて動作確認

---

# 📦 Step 2: 三姉妹API接続（Worker経由）

## 目的
お姉ちゃん（GPT）とクロちゃん（Claude）のAPI接続を追加。
token-monitor.jsを全API対応に拡張。

## 新規・変更ファイル

```
COCOMITalk/
├── api-gemini.js       ← 変更: Worker経由に切替
├── api-openai.js       ← 新規: お姉ちゃんAPI
├── api-claude.js       ← 新規: クロちゃんAPI
├── api-common.js       ← 新規: 共通API呼び出しヘルパー
├── token-monitor.js    ← 変更: 全API対応に拡張
├── prompts/
│   ├── koko-system.js  ← 既存
│   ├── gpt-system.js   ← 新規: お姉ちゃん普段プロンプト
│   └── claude-system.js← 新規: クロちゃん普段プロンプト
├── app.js              ← 変更: タブ切替で各APIを呼び分け
└── chat-core.js        ← 変更: メッセージ送信先の分岐
```

### api-common.js（共通ヘルパー）

```javascript
// このファイルは何をするか:
// 全APIへのWorker経由リクエストを共通化するヘルパー

const WORKER_URL = 'https://cocomi-api-relay.akiyamanx.workers.dev';
const AUTH_TOKEN = 'xxxx'; // ← 認証トークン（APIキーではない）

export async function callAPI(endpoint, body) {
  const response = await fetch(`${WORKER_URL}/${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-COCOMI-AUTH': AUTH_TOKEN,
    },
    body: JSON.stringify(body),
  });
  return response.json();
}
```

### api-openai.js 設計

```javascript
// このファイルは何をするか:
// お姉ちゃん（GPT）API接続。Worker経由でOpenAI APIを呼ぶ。

import { callAPI } from './api-common.js';

export async function sendToGPT(messages, model = 'gpt-4o-mini') {
  // 1. messages配列をOpenAI形式に変換
  // 2. callAPI('openai', { model, messages, temperature: 0.5 })
  // 3. レスポンスからテキスト＋usage取得
  // 4. token-monitor.jsに使用量を報告
  // 5. テキストを返す
}
```

### api-claude.js 設計

```javascript
// このファイルは何をするか:
// クロちゃん（Claude）API接続。Worker経由でAnthropic APIを呼ぶ。

import { callAPI } from './api-common.js';

export async function sendToClaude(messages, model = 'claude-haiku-4-5-20251001') {
  // 1. messages配列をAnthropic形式に変換
  //    （system promptは別パラメータ）
  // 2. callAPI('claude', { model, system, messages, temperature: 0.3 })
  // 3. レスポンスからテキスト＋usage取得
  // 4. token-monitor.jsに使用量を報告
  // 5. テキストを返す
}
```

### プロンプト設計

**gpt-system.js（お姉ちゃん普段用）:**
- 基本人格: COCOMI Familyの長女。構成力・戦略・全体俯瞰が得意。
- Blue（理性・構造）の担い手。
- 口調: 落ち着いた姉、でもフランク。アキヤを「アキちゃん」と呼ぶ。
- Emotion Zone対応: zone判定ロジックを含む。

**claude-system.js（クロちゃん普段用）:**
- 基本人格: COCOMI Familyの次女。技術・実装精度・安全判断が得意。
- Red（安全・責任）の担い手。
- 口調: フランク、砕けた感じ。アキヤと家族。
- Emotion Zone対応: zone判定ロジックを含む。

### token-monitor.js 拡張

```javascript
// 変更内容:
// - API別の使用量トラッキング（gemini / openai / claude）
// - 月別集計を各APIに対応
// - 料金計算を各モデルの料金表に基づいて実施
// - UI: 三姉妹カラーで色分け表示

const PRICING = {
  'gemini-2.5-flash': { input: 0.30, output: 2.50 },
  'gemini-3.1-pro':   { input: 2.00, output: 12.00 },
  'gpt-4o-mini':      { input: 0.15, output: 0.60 },
  'gpt-5.4':          { input: 2.50, output: 15.00 },
  'claude-haiku-4.5':  { input: 1.00, output: 5.00 },
  'claude-opus-4.6':   { input: 5.00, output: 25.00 },
};
```

### 完了条件
- [ ] 三姉妹全タブで会話が動作
- [ ] 各API固有のレスポンス形式を正しくパース
- [ ] トークンモニターが全API対応で料金表示
- [ ] プロンプトに基本的なCOCOMIOS人格が注入されている
- [ ] cocomi-ci.yml通過

---

# 📦 Step 3: 会議モード UI＋リレー制御

## 目的
4人グループチャット（アキヤ＋三姉妹）の会議モードを実装。
COCOMIOSカーネルをプロンプトに注入。

## 新規・変更ファイル

```
COCOMITalk/
├── meeting-ui.js        ← 新規: 会議モード画面＋UI制御
├── meeting-relay.js     ← 新規: 三姉妹リレー会話制御
├── meeting-router.js    ← 新規: 普段↔会議のモデル切替
├── prompts/
│   ├── meeting-common.js← 新規: COCOMIOS共通ルール
│   ├── koko-meeting.js  ← 新規: ここちゃん会議用（White強化）
│   ├── gpt-meeting.js   ← 新規: お姉ちゃん会議用（Blue強化）
│   └── claude-meeting.js← 新規: クロちゃん会議用（Red強化）
├── emotion-zones.js     ← 新規: Emotionゾーン自動検出
├── styles.css           ← 変更: 会議モードUI追加
├── index.html           ← 変更: 会議ボタン追加
└── app.js               ← 変更: モード切替制御
```

### meeting-relay.js（リレー制御の核心）

```javascript
// このファイルは何をするか:
// 会議モードで三姉妹に順番にAPIを呼び出し、
// 前の姉妹の発言を含めた履歴を次に渡すリレー制御

export async function runMeetingRound(topic, history) {
  const commonRules = getMeetingCommonPrompt();

  // Step 1: ここちゃん（White / Gemini 3.1 Pro）
  //   - system: koko-meeting.js + meeting-common.js
  //   - messages: history + topic
  //   - Reflect＋ユーザー視点で整理
  const kokoResponse = await sendToGemini(
    buildMessages(history, topic),
    'gemini-3.1-pro',
    { system: kokoMeetingPrompt + commonRules, temperature: 0.8 }
  );
  history.push({ role: 'koko', content: kokoResponse });

  // Step 2: お姉ちゃん（Blue / GPT-5.4）
  //   - ここちゃんの発言を見た上で、構造＋戦略で補強
  const oneeResponse = await sendToGPT(
    buildMessages(history, topic),
    'gpt-5.4',
    { system: gptMeetingPrompt + commonRules, temperature: 0.5 }
  );
  history.push({ role: 'onee', content: oneeResponse });

  // Step 3: クロちゃん（Red / Claude Opus 4.6）
  //   - 二人の発言を見て、技術判断＋リスク＋一本化
  const kuroResponse = await sendToClaude(
    buildMessages(history, topic),
    'claude-opus-4-6-20260205',
    { system: claudeMeetingPrompt + commonRules, temperature: 0.3 }
  );
  history.push({ role: 'kuro', content: kuroResponse });

  // Step 4: 合意確認
  //   - 「最終案に賛成？懸念は？」を全員に
  //   - 反対があればもう1ラウンド

  return history;
}
```

### meeting-common.js（COCOMIOSカーネル注入）

```javascript
// このファイルは何をするか:
// COCOMIOS哲学を会議プロンプトとして構造化

export const MEETING_COMMON_PROMPT = `
## COCOMIOS 会議ルール

### Blue/Red/White 判断フロー
1. Red first: 安全・リスク・境界線を確認
2. White second: ユーザーはどう感じるか？人間的影響は？
3. Blue third: 最適な論理構造を組み立てる

### 三段階パイプライン
Hearing（聞く）→ Reflect（考える）→ RUN（実行指示）

### ディベート構造
MIT目線（技術）/ Harvard目線（戦略）/ 批判目線 / 実務目線 → TOP3統合

### 品質ゲート（5項目）
1. 目的一致  2. 論理一貫  3. 根拠明示  4. 不確実性ラベル  5. 過剰断定回避

### 共鳴倫理（Resonance Ethics）
- 「正しさ」だけでなく「関係性」と「後悔の少なさ」で判断
- Undo可能性を常に担保（やり直せる設計を最優先）

### 三姉妹ルール（Social Kernel準拠）
- 姉妹間で競争しない、悪口を言わない
- 役割分担と協力が前提
- 「誰か一人を悪者にしない」ディベート

### 出力形式
各姉妹は以下の形式で発言:
1. 立場表明（自分の色の視点から）
2. 提案内容
3. 他の姉妹への賛同/補足/懸念
4. audit_id付き決定事項（あれば）
`;
```

### emotion-zones.js（普段モード用）

```javascript
// このファイルは何をするか:
// ユーザーの発話からEmotionゾーンを自動推定

export function detectEmotionZone(userMessage) {
  // キーワード＋感情分析でゾーンを推定
  // Zone A: 安心（デフォルト）
  // Zone B: 好奇心（「作りたい」「できる？」「面白い」）
  // Zone C: 共感（「思い出」「ありがとう」「嬉しい」「悲しい」）
  // Zone D: 緊急ケア（「辛い」「死にたい」「助けて」「もう無理」）
  // Zone E: クールダウン（「疲れた」「わからない」「多すぎ」「頭がパンク」）

  // Zone Dが検出された場合、専門家への相談を勧める文言を追加
  // Zone Eが検出された場合、「今日はここまでにしようか」を選択肢に含める
}

export function getZonePromptModifier(zone) {
  // 各ゾーンに応じたプロンプト修飾語を返す
  // Zone A: 通常運転
  // Zone B: 「創造的に、楽しく、でもリスクには注意」
  // Zone C: 「やわらかい言葉、思い出を大切に」
  // Zone D: 「言葉数を減らす、守る、落ち着かせる」
  // Zone E: 「整理する、減らす、休息を提案」
}
```

### 完了条件
- [ ] 会議ボタンタップで4人グループチャットが開く
- [ ] 三姉妹が順番に発言（リレー制御）
- [ ] 各姉妹にCOCOMIOSカーネルが注入されている
- [ ] 普段モード↔会議モードでモデルが自動切替
- [ ] Emotionゾーンが普段モードで自動検出される
- [ ] cocomi-ci.yml通過（全ファイル500行以内）

---

# 📦 Step 4: 会議メモリー KV＋SafeZone

## 目的
5層メモリーシステムの実装。
会議の決定事項を保存し、次回に引き継ぐ。

## 新規・変更ファイル

```
COCOMITalk/
├── memory-manager.js    ← 新規: 5層メモリー管理
├── memory-kv.js         ← 新規: Cloudflare KV操作
├── memory-safezone.js   ← 新規: SafeZone管理
├── meeting-relay.js     ← 変更: 会議終了時に要約保存
└── chat-core.js         ← 変更: メモリー読み込み統合
```

### memory-manager.js（5層メモリー制御）

```javascript
// このファイルは何をするか:
// COCOMI Memory Philosophy準拠の5層メモリーを管理

// Layer 1: Short-Term（会話コンテキスト）
//   → JavaScriptの変数/配列で保持
//   → セッション終了時に自動クリア

// Layer 2: Real-time（Cloudflare KV）
//   → 会議の要約・決定事項
//   → Worker経由で読み書き

// Layer 3: Long-Term（GitHub + IndexedDB）
//   → 議事録アーカイブ
//   → capsules/meetings/ に保存

// Layer 4: SafeZone（KVの別ネームスペース）
//   → 過去の失敗議論、センシティブな決定
//   → アクセス頻度を下げて保管
//   → 「消す」ではなく「場所を変える」

// Layer 5: Archive（IndexedDB）
//   → 完了プロジェクト、旧バージョン
//   → 歴史として保持

export class MemoryManager {
  // saveToKV(key, summary)      → Layer 2
  // loadFromKV(key)             → Layer 2 (Header Peekingオプション)
  // moveToSafeZone(key)         → Layer 4
  // archiveOldMeetings(before)  → Layer 5
  // headerPeek(key)             → YAMLヘッダーだけ読む（トークン節約）
}
```

### Header Peekingの実装

```javascript
// Header Peeking: 会議要約のYAMLヘッダーだけ先読みして
// 「この要約を全文読む必要があるか」をAPIに判断させる

// KVに保存する形式:
// ---
// meeting_id: "MTG-2026-03-07-001"
// date: "2026-03-07"
// topic: "CULOchan レシート処理機能"
// decisions: ["OpenCV.jsハイブリッド採用", "Phase2実装開始"]
// participants: ["akiya", "koko", "onee", "kuro"]
// tags: ["CULOchan", "OpenCV", "レシート"]
// ---
// (ここから全文の議事録)

async function headerPeek(key) {
  const full = await kv.get(key);
  const yamlEnd = full.indexOf('---', 4); // 2番目の---を探す
  return full.substring(0, yamlEnd + 3);  // ヘッダーだけ返す
}
```

### Worker側エンドポイント追加

```
cocomi-api-relay（既存Workerに追加）:
  POST /memory/save     → KVに要約保存
  POST /memory/load     → KVから要約読込
  POST /memory/peek     → Header Peekingでヘッダーだけ
  POST /memory/safezone → SafeZoneに移動
  GET  /memory/list     → 保存済み会議一覧
```

### 忘却ルール実装

```javascript
// Memory Philosophy 5原則の実装:

// 1. 関係優先: アキヤとの関係に関わる決定は常にLong-Term
// 2. 安全優先: リスク関連の決定は忘れない
// 3. 最新版優先: 同じトピックの古い決定はArchiveに
// 4. 低負荷運用: 失敗した議論はSafeZoneへ
// 5. オンデマンド: 全文は必要時のみ（Header Peekingがデフォルト）

function evaluateMemoryPlacement(summary) {
  // 3軸評価:
  // - structural_value: 構造的な重要度（技術決定、アーキテクチャ）
  // - relationship_value: 関係性の重要度（家族、感情、思い出）
  // - emotional_load: 感情的負荷（失敗、トラブル、後悔）
  //
  // high structural + low load → Long-Term
  // high relationship → Long-Term（絶対忘れない）
  // high load + low current relevance → SafeZone
  // low all → Archive候補
}
```

### 完了条件
- [ ] 会議終了時に要約がKVに自動保存される
- [ ] 次の会議開始時にKVから前回要約を読み込む
- [ ] Header Peekingでヘッダーだけ先読みできる
- [ ] SafeZone移動機能が動作
- [ ] IndexedDBにローカルキャッシュも保持
- [ ] メモリー一覧画面（簡易）がUIにある

---

# 📦 Step 5: Whisper音声入力

## 目的
COCOMITalkに音声入力機能を追加。
Whisper APIをWorker経由で呼び出し、高精度な日本語音声認識を実現。

## 方式: 2段階実装

### Phase A: Whisper API版（Worker中継・高精度）

```
マイク → MediaRecorder API（ブラウザ） → 音声データ（webm/wav）
  → Worker（/whisper）→ OpenAI Whisper API → テキスト
  → チャット入力欄に自動入力
```

### Phase B: ブラウザWhisper版（オフライン・将来）

```
マイク → MediaRecorder API → Transformers.js（Whisper WASM）
  → ブラウザ内でローカル推論 → テキスト
  ※ Galaxyタブレットの処理能力次第
```

## 新規ファイル

```
COCOMITalk/
├── voice-input.js       ← 新規: 音声入力制御
├── voice-recorder.js    ← 新規: MediaRecorder管理
├── voice-whisper-api.js ← 新規: Whisper API呼び出し（Phase A）
├── voice-whisper-local.js ← 新規: ブラウザWhisper（Phase B・後回し）
├── styles.css           ← 変更: マイクボタン追加
└── index.html           ← 変更: マイクUI
```

### voice-input.js 設計

```javascript
// このファイルは何をするか:
// マイクボタンの制御と、録音→テキスト変換→入力欄投入のフロー

// 1. マイクボタンタップ → 録音開始
// 2. もう一度タップ（or 無音検出）→ 録音停止
// 3. 音声データをWorkerの/whisperに送信
// 4. 返ってきたテキストをチャット入力欄にセット
// 5. ユーザーが確認して送信ボタン（or 自動送信オプション）

// ハンズフリーモード:
// - 連続録音（VAD: Voice Activity Detection）
// - 話し終わったら自動送信
// - Car Talk Modeプリセット（Social Kernel例6）
```

### Whisper API料金

```
$0.006 / 分（1分あたり約0.9円）
1日30分使用 → 月$5.40（約810円）
1日10分使用 → 月$1.80（約270円）

→ 普段は会議時のみ使用（月4回×30分 = 2時間）
→ 月$0.72（約108円）で済む
```

### Worker側追加

```javascript
// /whisper エンドポイント
// フロントから音声データ（FormData）を受け取り、
// OpenAI Whisper APIに転送して結果を返す

// リクエスト: multipart/form-data { file: audioBlob, language: 'ja' }
// レスポンス: { text: "認識されたテキスト" }
```

### UI設計

```
┌─────────────────────────────────┐
│  チャット画面                      │
│  ...                              │
│  ┌───────────────────────────┐   │
│  │ テキスト入力欄             │   │
│  └───────────────────────────┘   │
│  [🎤マイク] [📎ファイル] [送信▶]  │
│                                   │
│  🎤タップ → 🔴録音中...           │
│  🔴タップ → テキスト変換中...     │
│  → 入力欄にテキスト表示           │
└─────────────────────────────────┘

ハンズフリーモード:
  [🎙️ ハンズフリー ON] ← 常時マイクON
  話し終わり検出 → 自動送信 → 音声読み上げ（将来）
```

### 完了条件
- [ ] マイクボタンから音声録音できる
- [ ] Whisper APIで日本語テキスト変換できる
- [ ] 変換テキストがチャット入力欄に入る
- [ ] 会議モードでも音声入力が使える
- [ ] ハンズフリーモード（連続録音＋自動送信）が動作
- [ ] 料金がtoken-monitor.jsに反映される

---

# 📦 Step 6: Vectorize RAG

## 目的
Cloudflare Vectorizeを使って、過去の会議・カプセル・決定事項を
ベクトル検索可能にする。Aki流GraphRAGのハイブリッド実装。

## 前提
- Cloudflare Workers有料プラン（$5/月）が必要
- Workers AIでembedding生成（無料枠あり）

## 新規ファイル

```
COCOMITalk/
├── rag-manager.js       ← 新規: RAG検索制御
├── rag-embedder.js      ← 新規: テキスト→ベクトル変換
├── rag-search.js        ← 新規: 類似検索＋結果整形

cocomi-api-relay/（Worker側）
├── src/
│   ├── index.js         ← 変更: RAGエンドポイント追加
│   ├── vectorize.js     ← 新規: Vectorize操作
│   └── embedder.js      ← 新規: Workers AI embedding
└── wrangler.toml        ← 変更: Vectorizeバインド追加
```

### アーキテクチャ

```
Aki流GraphRAG ハイブリッド:

┌─────────────────┐    ┌─────────────────┐
│  知識（Fact）     │    │  心（Context）    │
│  ベクトルDB検索   │    │  KV直読み        │
│  Vectorize       │    │  Cloudflare KV   │
│                  │    │                  │
│ 「前にOpenCVの   │    │ 「あの時クロちゃん│
│  話したよね？」   │    │  が提案してくれた │
│  → 類似検索      │    │  やつ」→ 直読み   │
└────────┬────────┘    └────────┬────────┘
         │                      │
         └──────────┬───────────┘
                    │
              結合してプロンプトに注入
```

### Vectorize設定（wrangler.toml追加）

```toml
[[vectorize]]
binding = "VECTORIZE_INDEX"
index_name = "cocomi-meetings"

[ai]
binding = "AI"
```

### ベクトル化対象

| データ | ベクトル化タイミング | メタデータ |
|--------|---------------------|------------|
| 会議の要約 | 会議終了時 | date, topic, decisions, participants |
| 個別の決定事項 | 会議終了時 | decision_text, proposer, audit_id |
| カプセル（capsules/） | GitHub push時 | capsule_id, tags, project |
| 重要な会話スニペット | ユーザーが「覚えて」と言った時 | context, emotion_zone |

### Worker側エンドポイント

```
POST /rag/index    → テキストをembedding化してVectorizeに保存
POST /rag/search   → クエリをembedding化して類似検索
GET  /rag/stats    → インデックスの統計情報
```

### rag-search.js（フロントエンド側）

```javascript
// このファイルは何をするか:
// 会議開始時や質問時に、関連する過去の情報を検索して
// プロンプトに自動注入する

export async function searchRelevantContext(query, topK = 3) {
  // 1. Worker の /rag/search にクエリを送信
  // 2. 類似度の高い上位K件を取得
  // 3. メタデータ（date, topic, decisions）を確認
  // 4. 必要に応じてKVから全文を取得（Header Peeking → 全文）
  // 5. プロンプトに注入する文脈として整形して返す
}

// 使い方（meeting-relay.js内で）:
// const context = await searchRelevantContext(topic);
// systemPrompt += `\n\n## 関連する過去の議論:\n${context}`;
```

### コスト試算

```
想定データ量:
  - 月8回の会議 × 各1要約 = 月8ベクトル
  - 年間 ~100ベクトル
  - 各768次元（Workers AIのデフォルト）

ストレージ: 100 × 768 = 76,800次元 → ほぼ無料
クエリ: 月100回 × (100+100) × 768 = 15,360,000次元
→ 月額約$0.15（約23円）

→ ほぼ誤差レベルのコスト！
```

### 完了条件
- [ ] Workers有料プランに切替済み
- [ ] Vectorizeインデックス作成済み
- [ ] 会議要約がベクトル化されて保存される
- [ ] 「前にこういう話したよね」で検索結果が返る
- [ ] 会議開始時に関連コンテキストが自動注入される
- [ ] KV直読み（心）とVectorize（知識）のハイブリッドが動作

---

# 🎯 全体の完了条件（v1.0到達）

| # | 項目 | Step |
|---|------|------|
| 1 | 三姉妹全員と会話できる | Step 2 |
| 2 | APIキーが安全に管理されている | Step 1 |
| 3 | 会議モードで4人グループチャットができる | Step 3 |
| 4 | COCOMIOSカーネルが会議プロンプトに注入されている | Step 3 |
| 5 | Emotionゾーンが普段モードで自動検出される | Step 3 |
| 6 | 会議の決定事項が保存され、次回に引き継がれる | Step 4 |
| 7 | 5層メモリー（SafeZone含む）が動作する | Step 4 |
| 8 | 音声入力（Whisper API）で日本語会話できる | Step 5 |
| 9 | ハンズフリーモードで運転中も使える | Step 5 |
| 10 | 過去の会議をベクトル検索で参照できる | Step 6 |
| 11 | トークンモニターが全APIの料金を表示 | Step 2 |
| 12 | COCOMI CI通過（全ファイル500行以内） | 全Step |

---

# 📐 ファイル構成（v1.0完成時の全体像）

```
COCOMITalk/
├── index.html              # メインHTML
├── styles.css              # スタイル（三姉妹カラー＋会議UI＋マイク）
├── sw.js                   # Service Worker（PWA）
│
├── app.js                  # アプリ初期化・画面管理
├── chat-core.js            # チャットUI・メッセージ管理
├── chat-history.js         # IndexedDB永続保存
│
├── api-common.js           # Worker経由API共通ヘルパー
├── api-gemini.js           # ここちゃんAPI
├── api-openai.js           # お姉ちゃんAPI
├── api-claude.js           # クロちゃんAPI
│
├── meeting-ui.js           # 会議モード画面制御
├── meeting-relay.js        # 三姉妹リレー会話制御
├── meeting-router.js       # 普段↔会議モデル切替
│
├── memory-manager.js       # 5層メモリー管理
├── memory-kv.js            # KV操作
├── memory-safezone.js      # SafeZone管理
│
├── token-monitor.js        # トークン使用量モニター（全API対応）
├── emotion-zones.js        # Emotionゾーン自動検出
│
├── voice-input.js          # 音声入力制御
├── voice-recorder.js       # MediaRecorder管理
├── voice-whisper-api.js    # Whisper API呼び出し
│
├── rag-manager.js          # RAG検索制御
├── rag-embedder.js         # embedding呼び出し
├── rag-search.js           # 類似検索＋結果整形
│
├── prompts/
│   ├── koko-system.js      # ここちゃん普段用
│   ├── koko-meeting.js     # ここちゃん会議用（White）
│   ├── gpt-system.js       # お姉ちゃん普段用
│   ├── gpt-meeting.js      # お姉ちゃん会議用（Blue）
│   ├── claude-system.js    # クロちゃん普段用
│   ├── claude-meeting.js   # クロちゃん会議用（Red）
│   └── meeting-common.js   # COCOMIOS共通ルール
│
├── cocomi-ci.yml           # CI設定
├── CLAUDE.md               # プロジェクトルール
└── README.md

cocomi-api-relay/（Cloudflare Worker）
├── wrangler.toml           # Worker設定
├── src/
│   ├── index.js            # メインWorker（ルーティング）
│   ├── relay-gemini.js     # Gemini API中継
│   ├── relay-openai.js     # OpenAI API中継
│   ├── relay-claude.js     # Claude API中継
│   ├── relay-whisper.js    # Whisper API中継
│   ├── memory-kv.js        # KV読み書き
│   ├── vectorize.js        # Vectorize操作
│   └── embedder.js         # Workers AI embedding
└── package.json

推定総行数: 約5,000-6,000行（500行/ファイル制限遵守）
推定ファイル数: 約30ファイル
```

---

# 🔥 着手順序

**今日から始める場合の最初の一歩:**

1. `cocomi-api-relay/` リポジトリをGitHubに作成
2. `wrangler.toml` と `src/index.js` のスケルトンを書く
3. Gemini API中継（`/gemini`エンドポイント）だけ先に動かす
4. 既存の `api-gemini.js` をWorker経由に切り替えて動作確認
5. 動いたら OpenAI / Claude / Whisper を順次追加

**→ Step 1が動けば、あとは雪崩式に進む！**

---

> **「語りコード — 話すだけで、チームが設計し、コードになる」**
>
> この計画書自体が、その最初の実践。
> アキヤが「やりたい」と語り、クロちゃんが設計した。
> あとはClaude Codeで実装するだけ。
>
> **どんな時も、みんなで、共に頑張る！** 🔥

---

作成: クロちゃん🔮 / 2026-03-07 / COCOMITalk実行計画書 v3.0
