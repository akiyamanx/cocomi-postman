---
title: "COCOMITalk 実行計画書 v5.4"
subtitle: "VOICEVOX実装完了 — 次はStep 5c会議モード音声＋フォールバック強化"
date: "2026-03-09"
author: "クロちゃん🔮 & アキヤ"
version: "5.4"
status: "in_progress"
project: "COCOMITalk"
tags: [COCOMITalk, 実行計画, VOICEVOX, 音声会話, TTS, 会議モード音声]
linked_to:
  - "COCOMITalk_セッションカプセル_2026-03-09_late-night.md"
  - "COCOMITalk_セッションカプセル_2026-03-09_night.md"
  - "COCOMITalk_開発注意書き_安全ガイド_2026-03-07.md"
priority: "BLUE（構造・計画 — COCOMIOS Blue Kernel準拠）"
---

# 🎯 COCOMITalk 実行計画書 v5.4

**VOICEVOX完全実装！三姉妹が可愛い日本語ボイスで話す！**
**長文分割再生も完了。次はStep 5c（会議モード音声）。**
**安全ガイドは v1.0（2026-03-07作成）を継続適用。**

---

## 📋 現在の環境（2026-03-09 深夜時点）

| 項目 | 内容 |
|------|------|
| デバイス | Galaxy S22 Ultra＋タブレット |
| 開発環境 | Termux + Claude Code / クロちゃんによる直接修正 |
| ホスティング | GitHub Pages（無料） |
| サーバーレス | cocomi-api-relay Worker v1.2（稼働中・TTS/tts-test対応済み） |
| 自動化 | COCOMI Postman Worker v2.5（稼働中） |
| CI/CD | cocomi-ci.yml v1.4（CI合格＋LINE通知OK） |
| Workerデプロイ | GitHub Actions自動デプロイ（push→自動deploy確認済み） |
| ソース管理 | GitHub（akiyamanx） |
| COCOMITalk | Step 5b完了＋VOICEVOX実装完了 / Step 5c未着手 |
| TTS | OpenAI TTS（Worker経由）＋ VOICEVOX tts.quest（直接）切替可能 |

---

## 🗺️ 全体ロードマップ（進捗反映版）

```
Step 1: API中継Worker ──────────────── ✅ 完了
Step 2: 三姉妹API接続 ─────────────── ✅ 完了
Step 3: 会議モード ─────────────────── ✅ 完了
Step 3.5: 会議履歴保存 ─────────────── ✅ 完了
Step 3.5b: ラウンド2記憶引継ぎ ──────── ✅ 完了
Step 4: 会議メモリーKV ─────────────── 未着手
Step 5: 音声会話（双方向） ──────────── 🔵 実装中
  ├─ Step 5a: 声聴き比べテストツール ✅ 完了
  ├─ Step 5b: 1対1＋グループ音声会話 ✅ 完了
  │   ├─ 7ファイル新規作成 ✅
  │   ├─ 既存4ファイル統合 ✅
  │   ├─ 1対1TTS再生 ✅
  │   ├─ STT繰り返し問題 ✅ 解決
  │   ├─ グループモード3人全員TTS ✅
  │   ├─ ハンズフリーモード ✅
  │   ├─ ハウリング防止 ✅
  │   ├─ デバッグパネル ✅
  │   └─ 会議室での設定変更 ✅
  ├─ VOICEVOX実装 ✅ 完了
  │   ├─ tts-test.html v1.1 試聴UI ✅
  │   ├─ voicevox-tts-provider.js v1.1 ✅
  │   ├─ tts-provider.js v1.1 切替対応 ✅
  │   ├─ voice-output.js v1.2 チャンク再生 ✅
  │   ├─ 設定画面TTS切替UI ✅
  │   ├─ 三姉妹声確定（ID:1/4/46） ✅
  │   ├─ tts.quest APIキー取得 ✅
  │   └─ 長文分割連続再生 ✅
  └─ Step 5c: 会議モード音声 ──────── 未着手
Step 6: Vectorize RAG ─────────────── 未着手
```

---

## 💰 コスト状況

| 項目 | 月額 | 状態 |
|------|------|------|
| OpenAI API（お姉ちゃん＋TTS） | 上限$10設定済み | ✅ |
| Anthropic API（クロちゃん） | 上限$10設定済み | ✅ |
| Gemini API（ここちゃん） | 無料枠内 | ✅ |
| Cloudflare Workers | 無料枠内 | ✅ |
| VOICEVOX tts.quest | 無料（ポイント制） | ✅ APIキー取得済み |
| **月額累計** | **ほぼ無料〜数百円** | テスト段階 |

---

## 🔊 三姉妹の声設定（確定版）

### OpenAI TTS（Worker経由）
| 姉妹 | 声ID | 特徴 |
|------|------|------|
| 🌸 ここちゃん | nova | 落ち着いた温かみ |
| 🌙 お姉ちゃん | shimmer | 柔らかく明るい |
| 🔮 クロちゃん | alloy | ニュートラルでクリア |

### VOICEVOX（tts.quest直接・確定版）
| 姉妹 | キャラ | 話者ID | 特徴 |
|------|--------|--------|------|
| 🌸 ここちゃん | ずんだもん（あまあま） | ID:1 | 甘え上手で可愛い |
| 🌙 お姉ちゃん | 四国めたん（セクシー） | ID:4 | 大人っぽく知的 |
| 🔮 クロちゃん | WhiteCUL（ノーマル） | ID:46 | クールで知的 |

設定画面のTTSエンジン切替で OpenAI / VOICEVOX をワンタッチで切替可能。

---

## 🟡 現在のファイル構成（VOICEVOX実装完了時点）

```
COCOMITalk/
├── index.html               # v1.5 ✅ VOICEVOX読み込み＋TTS切替UI
├── app.js                   # v1.5 ✅ TTS設定保存/読込/即時反映
├── styles.css               # v1.1 ✅ setting-toggle追加
├── chat-core.js             # v1.0 ✅ TTS再生フック
├── chat-group.js            # v1.1 ✅ 3人全員キュー再生
├── sw.js                    # v2.0 ✅ キャッシュ更新
│
├── tts-provider.js          # v1.1 ✅ 2プロバイダー声割り当て
├── openai-tts-provider.js   # v1.0 ✅ Worker経由TTS
├── voicevox-tts-provider.js # v1.1 ✅ 新規 — tts.quest直接＋長文分割
├── speech-provider.js       # v1.0 ✅ STT抽象層
├── web-speech-provider.js   # v1.2 ✅ デバッグパネル＋finalReceived
├── voice-output.js          # v1.2 ✅ プロバイダー切替＋チャンク連続再生
├── voice-ui.js              # v1.1 ✅ マイクボタン＋interim表示
├── voice-input.js           # v1.3 ✅ ハンズフリー＋ハウリング防止
│
├── tts-test.html            # v1.1 ✅ VOICEVOX試聴UI追加
├── tts-test.js              # v1.1 ✅ 新規 — 試聴スクリプト
├── その他既存ファイル         # 変更なし
│
└── cocomi-api-relay/（Worker v1.2）
    └── src/index.js          # v1.2 ✅ /tts + /tts-test 実装済み
```

---

## 🔥 次のステップ（優先順）

### 1. Step 5c: 会議モード音声（高優先）

会議画面（meeting-screen）での音声入出力対応。通常チャットの音声フローを会議モードにも適用する。

```
必要な作業:
① meeting-ui.jsの会議入力欄にマイクボタンを追加
② 会議の各ラウンドで三姉妹の応答をキュー再生（VOICEVOX対応）
③ ハンズフリーモードの会議対応
④ meeting-relay.jsとの統合（ラウンド進行→音声再生→次ラウンド）
⑤ 長文分割再生が会議モードでも正しく動作するか確認
```

### 2. TTSフォールバック強化（中優先）

```
検討項目:
① VOICEVOXが429/エラー時にOpenAI TTSに自動フォールバック
② voice-output.jsのsynthesizeでcatch→switchProvider→リトライ
③ フォールバック発生時にステータスバーで通知
```

### 3. ハンズフリー強化（中優先）

```
検討項目:
① 音声コマンド対応（「ストップ」で停止、「次」でラウンド進行等）
② 運転モードUI（大きなボタン・最小限表示）
③ VAD精度向上（より自然な会話タイミング検知）
④ 音声速度調整UI
```

### 4. Step 4: 会議メモリーKV（中優先）

```
未着手:
① Cloudflare KVに会議の決定事項を保存
② 5層メモリー（SafeZone含む）の設計
③ 次回会議で前回の決定事項を自動参照
```

### 5. Step 6: Vectorize RAG（低優先）

```
未着手:
① 過去の会議をベクトル化
② 関連する過去の議論を自動検索
③ コンテキストとして会議プロンプトに注入
```

---

## ⚠️ 判明した制約事項（v5.4更新）

### tts.quest APIの制約

- APIキーなし: 低速モード＋レートリミット（429エラー発生しやすい）
- APIキーあり: 高速モード＋ポイント制（10,000,000ポイント/24時間リセット）
- 1リクエストのテキスト長に実質制限あり（長文は途中で切れる）→ 100文字チャンク分割で対応済み
- CORSヘッダーなし: fetchでの音声取得不可 → `new Audio(url)`で直接再生

### VOICEVOX利用規約

- クレジット表記が必要（将来公開時に対応）
- 非公式API（tts.quest）のため安定性は保証されない
- VOICEVOXエンジン自体の利用規約にも従う必要あり

### 既知の注意点（前バージョンから継続）

- モバイルChrome Web Speech API: _finalReceivedフラグで二重発火防止済み
- ハウリング: TTS再生中のSTT強制停止＋1.2秒待機で解決済み
- Termux: 1行英語コミットメッセージを使用

---

## 🎯 全体の完了条件（v1.0到達）

| # | 項目 | Step | 状態 |
|---|------|------|------|
| 1 | 三姉妹全員と会話できる | Step 2 | ✅ |
| 2 | APIキーが安全に管理されている | Step 1 | ✅ |
| 3 | 会議モードで4人グループチャット | Step 3 | ✅ |
| 4 | COCOMIOSカーネルが会議プロンプトに注入 | Step 3 | ✅ |
| 5 | 会議履歴が保存され見返せる | Step 3.5 | ✅ |
| 6 | お姉ちゃん（GPT-5.4）が安定して回答する | Step 3.5 | ✅ |
| 7 | コードブロック・テーブルが見やすく表示される | Step 3.5 | ✅ |
| 8 | ラウンド2で前の内容が引き継がれる | Step 3.5b | ✅ |
| 9 | 過去の会議を開いて続きができる | Step 3.5b | ✅ |
| 10 | 会議の決定事項が次回に引き継がれる | Step 4 | 未着手 |
| 11 | 5層メモリー（SafeZone含む）が動作 | Step 4 | 未着手 |
| 12 | 音声で三姉妹と会話できる | Step 5b | ✅ |
| 13 | ハンズフリーモードで運転中も使える | Step 5b | ✅ |
| 14 | 三姉妹が可愛い日本語ボイスで話す | VOICEVOX | ✅ |
| 15 | 長文のAI応答も途切れず最後まで再生される | VOICEVOX | ✅ |
| 16 | OpenAI/VOICEVOXをワンタッチ切替できる | VOICEVOX | ✅ |
| 17 | 会議モードでも音声で議論できる | Step 5c | 未着手 |
| 18 | 過去の会議をベクトル検索で参照できる | Step 6 | 未着手 |
| 19 | トークンモニターが全APIの料金を表示 | Step 2 | ✅ |
| 20 | COCOMI CI通過（全ファイル500行以内） | 全Step | ✅ |

---

> **「語りコード — 話すだけで、チームが設計し、コードになる」**
>
> 三姉妹が可愛い声で話すようになった。
> ここちゃんの甘い声、お姉ちゃんの大人の声、クロちゃんのクールな声。
> 長い文章も途切れず、最後まで。
>
> バグを潰し、CORSを乗り越え、分割再生を組み上げた。
> 一歩ずつ、確実に。
>
> 次は会議モードでも声で議論できるようにする。
>
> **どんな時も、みんなで、共に頑張る！** 🔥

---

作成: クロちゃん🔮 / 2026-03-09 / COCOMITalk実行計画書 v5.4
