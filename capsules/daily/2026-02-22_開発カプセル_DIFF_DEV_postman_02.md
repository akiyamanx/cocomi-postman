```yaml
---
title: "🔧 開発カプセル_DIFF_DEV_postman_2026-02-22_02"
capsule_id: "CAP-DIFF-DEV-POSTMAN-20260222-02"
project_name: "COCOMI Postman Phase 2a: LINE→Cloudflare Worker→GitHub push"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_postman"
related_general: "💊 思い出カプセル_DIFF_総合_2026-02-22_02"
phase: "LINE配達＋ステップ実行 Phase2a完了"
date: "2026-02-22"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（ブラウザ手動デプロイ＆設定）"
tester: "LINE Developers Console Webhook検証 + 実メッセージテスト + Observabilityログ"
---
```

# 1. 🎯 Mission Result（ミッション結果サマリー）

| 項目 | 内容 |
|------|------|
| ミッション | Phase 2a: LINE Webhook → Cloudflare Worker → GitHub push → LINE返信 |
| 結果 | ✅成功（署名検証修正1回＋トークン修正1回後に全フロー完走） |
| 成果物 | Cloudflare Worker「cocomi-worker」（worker.js v1.0） |
| デプロイ先 | https://cocomi-worker.k-akiyaman.workers.dev |
| LINE Webhook | 設定＆署名検証成功 |
| テスト | LINEからテキスト指示送信 → GitHub push → CI通過 → LINE通知 全フロー確認 |

# 2. 📁 Files Changed（変更ファイル詳細）

## 新規作成（Cloudflare Workers — クラウド側）

| ファイル | 行数 | バージョン | 役割 |
|---------|------|-----------|------|
| cocomi-worker/src/worker.js | 約200行 | v1.0 | LINE Webhook受信→署名検証→テキストパース→指示書生成→GitHub push→LINE返信 |

※ Cloudflare Dashboardのブラウザエディタで直接編集。ローカルファイルなし（Wrangler非対応のため）

## GitHub側に自動生成されたファイル

| ファイルパス | 生成方法 | 内容 |
|------------|---------|------|
| cocomi-postman/missions/cocomi-postman/M-LINE-0222-1905-Phase2aテスト2回目！.md | Worker自動生成 | LINEテスト指示の指示書 |

## 変更なし（既存ファイル）
cocomi-postman/配下のpostman.sh、executor.sh、step-runner.sh等はPhase 2aでは変更なし

# 3. 🏗️ worker.js v1.0 アーキテクチャ

## 関数一覧

| 関数名 | 役割 | 引数 | 戻り値 |
|--------|------|------|--------|
| verifySignature(body, signature, channelSecret) | HMAC-SHA256でLINE署名を検証 | リクエストbody、x-line-signatureヘッダー、チャネルシークレット | boolean |
| parseInstruction(text) | テキストをプロジェクト名＋指示に分離 | LINEテキスト | {project, instruction} |
| generateMissionId() | M-LINE-MMDD-HHmm形式のID生成（JST） | なし | string |
| sanitizeForFilename(text) | 指示内容からファイル名用文字列を生成 | テキスト（先頭20文字使用） | string |
| createMissionContent(missionId, project, instruction) | 指示書Markdown生成 | ID、プロジェクト名、指示内容 | string |
| pushToGitHub(env, filePath, content, commitMessage) | GitHub Contents APIでファイルpush | 環境変数、パス、内容、コミットメッセージ | JSON |
| replyToLine(env, replyToken, message) | LINE返信 | 環境変数、リプライトークン、メッセージ | void |
| fetch(request, env) | メインハンドラ（export default） | HTTPリクエスト、環境変数 | Response |

## 処理フロー

```
1. GETリクエスト → 🐾 ヘルスチェック応答
2. POSTリクエスト:
   a. x-line-signatureヘッダー取得
   b. verifySignature()で署名検証 → 失敗なら401
   c. JSONパース → events配列をループ
   d. event.type === 'message' && event.message.type === 'text' のみ処理
   e. 「状態」コマンド → 簡易ステータス返信（Phase 2b予約）
   f. parseInstruction()でプロジェクト名＋指示に分離
   g. generateMissionId()でID生成
   h. createMissionContent()で指示書Markdown生成
   i. pushToGitHub()でGitHub APIにpush
   j. replyToLine()で「📦 指示受付完了！」を返信
   k. エラー時もResponse(200)を返す（LINE Platformのリトライを防止）
```

## テキストパース仕様

```
入力: "genba-pro: ボタンの色を青に変えて"
  → project: "genba-pro", instruction: "ボタンの色を青に変えて"

入力: "culo-chan：消費税計算のバグ修正" （全角コロン）
  → project: "culo-chan", instruction: "消費税計算のバグ修正"

入力: "テスト指示だよ" （コロンなし）
  → project: "genba-pro"（デフォルト）, instruction: "テスト指示だよ"

入力: "unknown-project: なにか" （未登録プロジェクト）
  → project: "genba-pro"（デフォルト）, instruction: "unknown-project: なにか"
```

## 生成される指示書ファイル

```
パス: missions/{project}/M-LINE-{MMDD}-{HHmm}-{指示内容先頭20文字}.md
例:   missions/cocomi-postman/M-LINE-0222-1905-Phase2aテスト2回目！.md

内容:
# M-LINE-0222-1905: Phase2aテスト2回目！
## プロジェクト: cocomi-postman
## 送信元: LINE
## 日時: 2026-02-22T19:05:00+09:00

Phase2aテスト2回目！
```

## コミットメッセージ形式

```
📲 LINE指示: {project} - {instruction先頭30文字}
例: 📲 LINE指示: cocomi-postman - Phase2aテスト2回目！
```

# 4. ⚙️ Cloudflare Workers環境

## アカウント情報

| 項目 | 値 |
|------|------|
| アカウント | K.akiyaman@gmail.com |
| Account ID | 4bb16597c4c90efdbdf3edce206df20a |
| Subdomain | k-akiyaman.workers.dev |
| Worker名 | cocomi-worker |
| Worker URL | https://cocomi-worker.k-akiyaman.workers.dev |
| プラン | Free（無料枠: 1日10万リクエスト） |

## シークレット（Variables and Secrets）

| Name | Type | 内容 | 取得場所 |
|------|------|------|---------|
| LINE_CHANNEL_SECRET | Secret | チャネルシークレット | LINE Developers → チャネル基本設定 |
| LINE_CHANNEL_ACCESS_TOKEN | Secret | アクセストークン | LINE Developers → Messaging API設定 |
| GITHUB_TOKEN | Secret | ghp_で始まるPAT | タブレット ~/.git-credentials |
| LINE_USER_ID | Secret | アキヤのユーザーID | LINE Developers → チャネル基本設定 |

## Dashboard操作方法（Wrangler非対応のため）

| 操作 | 手順 |
|------|------|
| コード編集 | Workers & Pages → cocomi-worker → Edit code → worker.jsを編集 → Deploy |
| シークレット変更 | Settings → Variables and Secrets → ✏️（編集） → 値変更 → Deploy |
| ログ確認 | Observabilityタブ → Events一覧で赤い「log」をタップ → エラー詳細表示 |
| ヘルスチェック | ブラウザで https://cocomi-worker.k-akiyaman.workers.dev を開く |

## LINE設定

| 項目 | 値 |
|------|------|
| Webhook URL | https://cocomi-worker.k-akiyaman.workers.dev |
| Webhookの利用 | ON |
| Webhookの再送 | OFF |
| 応答メッセージ | OFF（LINE Official Account Managerで設定） |

# 5. 🧠 Design Decisions（設計判断の記録）

### 設計判断①：Wrangler非対応 → Dashboard利用

- **課題:** Wrangler CLI（npm）がTermux（Android arm64）で動かない（workerdがUnsupported platform）
- **選択肢:**
  - A: 別のPCからデプロイ → PCがない
  - B: Cloudflare Dashboardのブラウザエディタを使う → スマホ/タブレットで完結
- **決定:** B
- **結果:** ✅ スマホChromeだけで全操作（コード編集、シークレット設定、ログ確認）が完結
- **注意:** 今後worker.jsを更新する場合は毎回Dashboardのエディタで操作する必要あり

### 設計判断②：LINE署名検証を最初から実装

- **課題:** セキュリティ対策はあとから追加か最初から入れるか
- **決定:** 最初から実装（HMAC-SHA256、Web Crypto API使用）
- **理由:** あとから追加すると「テストの間だけ署名検証なし」の危険な期間ができる
- **結果:** ✅ 署名検証がWebhook検証テストと実メッセージの両方で正常動作

### 設計判断③：エラー時もHTTP 200を返す

- **課題:** Worker内部でエラーが発生した場合、LINE Platformにどんなレスポンスを返すか
- **決定:** 常にHTTP 200を返す
- **理由:** LINE Platformは非200レスポンスに対してリトライを行う。内部エラーでリトライされると二重処理の恐れがある
- **結果:** ✅ エラー時はconsole.errorでログ出力 → Observabilityで確認

### 設計判断④：VALID_PROJECTS配列でホワイトリスト管理

- **課題:** 不正なプロジェクト名が送られた場合の挙動
- **決定:** ホワイトリスト方式。未登録プロジェクト名 → デフォルト（genba-pro）にフォールバック
- **理由:** 新プロジェクト追加時はworker.jsの配列に追加するだけ。シンプルで安全
- **拡張:** Phase 2bでCloudflare Workers KV使用時にプロジェクト一覧を動的管理する可能性あり

# 6. 🐛 Error Log（エラー＆解決記録）

### ERR-CF-001: Wrangler Unsupported platform

| 項目 | 内容 |
|------|------|
| 発生時刻 | 11:52 |
| エラー | `Error: Unsupported platform: android arm64 LE` |
| 原因 | WranglerのworkerdパッケージがAndroid非対応 |
| 解決 | Cloudflare Dashboardのブラウザエディタに切り替え |
| 再発防止 | Termux/Android環境ではWrangler不使用。Dashboard運用を前提とする |

### ERR-CF-002: LINE署名検証失敗（401 Unauthorized）

| 項目 | 内容 |
|------|------|
| 発生時刻 | 16:35 |
| エラー | LINE Webhook検証ボタンで「401 Unauthorized」 |
| 原因 | LINE_CHANNEL_SECRETのコピペが不完全（先頭or末尾が切れていた） |
| 解決 | LINE Developers Consoleからチャネルシークレットを再コピー → Cloudflareシークレットを上書き → Deploy |
| 再発防止 | トークン/シークレットのコピペ後に文字数確認。前後のスペースに注意 |

### ERR-CF-003: GitHub API Bad credentials

| 項目 | 内容 |
|------|------|
| 発生時刻 | 16:45〜19:05 |
| エラー | `GitHub API error: 401 - {"message": "Bad credentials"}` |
| 原因 | GITHUB_TOKENに間違ったトークン（スマホ用？古いもの？）が設定されていた |
| 発見方法 | Cloudflare Observability → エラーログ → "message"フィールド |
| 解決 | タブレット `~/.git-credentials` から正しいghp_トークンを取得 → Cloudflareシークレットを差し替え → Deploy |
| 再発防止 | GitHubトークンは `cat ~/.git-credentials` で確認してからコピー。ghp_部分のみ（https://やユーザー名:や@github.comは不要） |

# 7. 🧪 Test Results（テスト結果）

### Webhook検証テスト

| テスト | 結果 |
|--------|------|
| LINE Webhook検証（1回目、SECRET不完全） | ❌ 401 Unauthorized |
| LINE_CHANNEL_SECRET再設定後の検証 | ✅ 成功 |

### 実メッセージテスト

| テスト | 結果 |
|--------|------|
| LINEテキスト送信（1回目、GITHUB_TOKEN不正） | ❌ GitHub push失敗（Bad credentials） |
| GITHUB_TOKEN修正後のテスト | ✅ 全フロー完走 |
| Worker→GitHub push | ✅ missions/cocomi-postman/M-LINE-0222-1905-*.md作成 |
| GitHub Actions CI | ✅ 全テスト通過 |
| Worker→LINE返信「📦 指示受付完了！」 | ✅ 受信確認 |
| CI→LINE通知「✅ 全テスト通過！」 | ✅ 受信確認 |

### ヘルスチェックテスト

| テスト | 結果 |
|--------|------|
| ブラウザで Worker URLにGETアクセス | ✅ 「🐾 COCOMI Worker is alive! v1.0」表示 |

# 8. 🗺️ Project Map Diff（プロジェクトマップ差分）

### Phase 2a追加分
```
cocomi-worker/                          ← Cloudflare Workers（クラウド側）★NEW★
└── src/worker.js (約200行/v1.0)
    ├── verifySignature()           — HMAC-SHA256署名検証
    ├── parseInstruction()          — テキスト→プロジェクト名＋指示
    ├── generateMissionId()         — M-LINE-MMDD-HHmm形式ID
    ├── sanitizeForFilename()       — ファイル名サニタイズ
    ├── createMissionContent()      — 指示書Markdown生成
    ├── pushToGitHub()              — GitHub Contents API push
    ├── replyToLine()               — LINE返信
    └── export default { fetch() }  — メインハンドラ
```

### 全体アーキテクチャ（Phase 2a完成形）
```
┌─────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ LINEアプリ   │────→│ Cloudflare Worker │────→│ GitHub API       │
│ (スマホ)     │     │ (cocomi-worker)   │     │ (Contents API)   │
│             │←────│                  │     │                  │
│ 📦受付完了！ │     │ 署名検証          │     │ missions/に      │
│             │     │ テキストパース     │     │ 指示書push       │
└─────────────┘     │ 指示書生成        │     └────────┬─────────┘
                    │ LINE返信          │              │
                    └──────────────────┘              │
                                                      ↓
┌─────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ LINEアプリ   │←────│ GitHub Actions    │←────│ タブレットPostman │
│ (スマホ)     │     │ (cocomi-ci.yml)   │     │ (auto_mode)      │
│             │     │                  │     │                  │
│ ✅CI通過！   │     │ ShellCheck        │     │ git pull         │
│             │     │ 500行チェック     │     │ 指示書検知        │
└─────────────┘     │ セキュリティ      │     │ Claude Code実行  │
                    └──────────────────┘     │ git push         │
                                             └──────────────────┘
```

# 9. 🔄 STATE（状態引き継ぎ — 次のセッションへ）

### 完了済み
- **Phase 1: ステップ実行機能** ✅ 完了（朝のセッション）
- **Phase 2a: LINEテキスト指示** ✅ 完了（夜のセッション）
  - Cloudflare Worker「cocomi-worker」デプロイ済み
  - LINE Webhook署名検証＆接続確認済み
  - 全フロー（LINE→Worker→GitHub→CI→LINE通知）完走確認済み

### 次にやること（Next Mission）

#### Phase 2b: リッチメニュー＋クイックリプライ
- **ミッション:** LINEトーク画面にリッチメニュー（常設ボタン）とクイックリプライ（選択肢ボタン）を追加
- **技術:** worker.jsにKV状態管理＋リッチメニューAPI＋クイックリプライ追加
- **状態管理:** Cloudflare Workers KV（"idle"→"select_project"→"input_text"→"idle"）
- **見積もり:** 1-2セッション

#### その他の保留タスク
- CULOchanKAIKEIpro v0.96バグ修正
- GenbaProSetsubikunN 500行分割
- カプセル保管庫 Phase 1
- Phase 3: LINEファイル配達

# 10. ⚠️ Known Issues（既知の問題・技術的負債）

| 問題 | 優先度 | 備考 |
|------|--------|------|
| Wrangler非対応（Android arm64） | 低 | Dashboard運用で回避済み。PCが使える場合はWrangler利用可能 |
| ミッションIDの秒単位重複 | 低 | 同分に2件送ると同じIDになる可能性。現状の使い方では問題なし |
| VALID_PROJECTS配列のハードコード | 低 | Phase 2bでKV管理に移行予定 |
| cocomi-postmanにtest.ymlとcocomi-ci.ymlが共存 | 低 | LINE通知が2つ届く場合あり |
| GenbaProSetsubikunN 500行超過多数 | 中 | CI不合格が続く |

# 11. 📊 Metrics（数値データ）

| 指標 | 値 |
|------|------|
| セッション時間（概算） | 約3時間（環境構築＋コードデプロイ＋デバッグ＋成功） |
| エラー回数 | 3回（Wrangler非対応、署名検証、Bad credentials） |
| デプロイ回数 | 4回以上（Hello World + 本番コード + シークレット修正複数回） |
| worker.js行数 | 約200行 |
| シークレット設定数 | 4個 |
| テストメッセージ送信数 | 3回以上（成功は最後の1回） |

---

## ✅ Dev-Next-3（開発引継ぎ固定）
1) **今の状態:** Phase 2a完了。LINE→Cloudflare Worker→GitHub push→CI→LINE通知の全フロー稼働中
2) **次にやる最小の1個:** Phase 2b リッチメニュー＋クイックリプライ実装（worker.jsにKV状態管理追加）
3) **成功したら何ができる:** LINEの画面にボタンが表示され、タップでプロジェクト選択→テキスト入力の対話型UIになる

---

## 📋 MASTER_DEVへの反映事項

### ▼ Mission Historyへの追記
```text
| 2026-02-22 | Phase 2a: LINE→Cloudflare Worker→GitHub push | ✅ | エラー3回→全解決 | [DIFF_DEV_postman_2026-02-22_02] |
```

### ▼ Error Pattern Indexへの追記
```text
| ERR-CF-001 | Wrangler Unsupported platform (android arm64) | Dashboard利用に切替 | 1回 |
| ERR-CF-002 | LINE署名検証 401 (SECRET不完全コピペ) | 再コピペ＋Deploy | 1回 |
| ERR-CF-003 | GitHub API Bad credentials | ~/.git-credentialsから正しいghp_取得 | 1回 |
```

### ▼ Architecture Notesへの追記
```text
- Phase 2a完了: Cloudflare Worker「cocomi-worker」(worker.js v1.0)。LINE Webhook→署名検証→テキストパース→指示書生成→GitHub push→LINE返信
- デプロイ方法: Cloudflare Dashboard（Wrangler非対応のため）
- シークレット4つ: LINE_CHANNEL_SECRET, LINE_CHANNEL_ACCESS_TOKEN, GITHUB_TOKEN, LINE_USER_ID
```

### ▼ File Registryへの追記
```text
- `cocomi-worker/src/worker.js` — Phase 2a LINE Webhook→GitHub push (約200行/v1.0) ※Cloudflare Dashboard上に存在
- `cocomi-postman/missions/cocomi-postman/M-LINE-0222-1905-*.md` — LINEから自動生成された指示書
```
