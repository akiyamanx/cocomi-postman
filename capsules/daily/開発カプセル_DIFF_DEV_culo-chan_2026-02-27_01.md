---
title: "🔧 開発カプセル_DIFF_DEV_culo-chan_2026-02-27_01"
capsule_id: "CAP-DIFF-DEV-CULO-20260227-01"
project_name: "CULOchan会計Pro"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_culo-chan"
related_general: "💊 思い出カプセル_DIFF_総合_2026-02-27_01"
mission_id: "M-CULO-096-01"
phase: "レシート管理機能 Phase1（撮影→読み取り→PDF保存→閲覧）"
date: "2026-02-27"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（Termux手動実行）"
tester: "アキヤ（Galaxy実機確認）"
---

# 1. 🎯 Mission Result（ミッション結果サマリー）

| 項目 | 内容 |
|------|------|
| ミッション | M-CULO-096-01: レシート管理Phase1 — AI分離認識＆PDF生成＆日付別閲覧 |
| 結果 | ⚠️部分成功（核心機能は全動作。PDF日本語文字化け・表示方法に課題あり） |
| 完了Step | Step 4/4（Phase1の全Stepを実装完了。品質改善は次Phase） |
| 実行回数 | クロちゃん設計→アキヤTermux実行を約8回（修正含む） |
| リトライ | sw.jsキャッシュ問題で3回ほど修正サイクル |
| git commits | 4コミット |
| 主な成果 | レシート撮影→Gemini AI複数レシート分離認識→日付別PDF生成→IndexedDB保存→月別一覧画面→PDF閲覧が一通り動作 |

# 2. 📁 Files Changed（変更ファイル詳細）

## 新規作成
| ファイル | 行数 | バージョン | 役割 |
|---------|------|-----------|------|
| receipt-pdf.js | 458行 | v0.96 | jsPDFによるレシートPDF生成、IndexedDB（CULOchanReceiptPDFs）への保存・取得・削除、日付別グループ化 |
| receipt-pdf-viewer.js | 155行 | v0.96 | PDF一覧画面ロジック。月選択、統計表示、日付カード一覧、削除確認 |
| receipt-pdf-viewer.html | 36行 | v0.96 | PDF一覧画面HTML。ヘッダー（🏠/📷ボタン）、月ナビ、統計バー、日付リスト |

## 編集（既存ファイル変更）
| ファイル | 行数変化 | バージョン | 変更概要 |
|---------|---------|-----------|---------|
| receipt-ai.js | 211行→451行(+240) | v0.95→v0.96 | Geminiプロンプト拡張（複数レシート分離）、normalizeAiResponse()追加（後方互換）、applyAiResult()拡張（駐車場自動判定）、getReceiptsByDate()/getLastAiResults()追加 |
| receipt.html | 158行付近変更 | v0.96 | save-barをアコーディオン式に変更。「仕訳を保存」常時表示＋「📄 PDF機能 ▼」折りたたみライン＋展開時にPDF生成/一覧ボタン |
| index.html | +2行 | v0.96 | `<script src="receipt-pdf.js">` と `<script src="receipt-pdf-viewer.js">` を追加（197-198行目） |
| screen-loader.js | +1行 | v0.96 | SCREEN_FILES配列に `'receipt-pdf-viewer'` を追加（23行目） |
| sw.js | 変更 | v2.0.0→v2.1.0 | CACHE_NAME更新、receipt-pdf.js/receipt-pdf-viewer.js/receipt-pdf-viewer.htmlをキャッシュリストに追加 |

## 500行チェック
- ⚠️ 500行超過ファイル: なし
- receipt-ai.js: 451行（セーフ）、receipt-pdf.js: 458行（セーフ）
- 分割が必要なファイル: なし

# 3. 🧠 Design Decisions（設計判断の記録）

### 設計判断①：Geminiプロンプトを「複数レシート分離型JSON」に拡張
- **課題:** 1枚の写真に複数レシートが写る場合、個別認識できなかった
- **選択肢:**
  - A: 画像を事前にクロップして1枚ずつ送る → 角検出が必要で複雑
  - B: プロンプトで「複数レシートを個別に認識して」と指示 → シンプル、Gemini 2.0 Flashの能力で可能
- **決定:** B（プロンプト拡張方式）
- **理由:** Phase2で角検出を実装予定だが、まずプロンプトだけで分離できるか検証。Gemini 2.0 Flashは十分な能力がある
- **結果:** 駐車場レシート1枚の写真で正しく認識成功。店名・金額・日付・種別(parking)を正確に抽出

### 設計判断②：レスポンスJSON形式を `{receipts: [...]}` に統一
- **課題:** 旧形式 `{storeName, items[]}` と新形式の互換性
- **選択肢:**
  - A: 旧形式を廃止、新形式のみ → 既存データが壊れるリスク
  - B: normalizeAiResponse()で旧→新形式に自動変換 → 後方互換を維持
- **決定:** B（自動変換レイヤー追加）
- **理由:** 既存のレシート履歴データを壊さない安全設計
- **結果:** 旧形式でも新形式でも正しく動作

### 設計判断③：PDF専用IndexedDB（CULOchanReceiptPDFs）を新設
- **課題:** 既存のIndexedDBにPDFデータを追加するか、別DBにするか
- **選択肢:**
  - A: 既存DB（reform_app_receipts等）にストア追加 → バージョン管理が複雑
  - B: 専用DB新設 → 既存DBに一切影響なし
- **決定:** B（専用DB）
- **理由:** 企画書のSection 5-3の設計に準拠。既存機能への影響ゼロ
- **結果:** `receipt_pdfs`（日付キー）と `receipts`（個別データ）の2ストアで正常動作

### 設計判断④：save-barをアコーディオン方式に
- **課題:** PDF関連ボタン3つが常時表示だとUIがうるさい
- **選択肢:**
  - A: AI読み取り後のみPDFボタン表示 → display:none/blockの切り替え
  - B: 折りたたみ式のラインボタン → タップで展開/収納
- **決定:** B（アキヤの提案によるアコーディオン方式）
- **理由:** いつでもPDF一覧にアクセスしたい場面がある。折りたたみなら邪魔にならずアクセス可能
- **結果:** 「── 📄 PDF機能 ▼ ──」の薄いラインが良い感じに収まった

### 設計判断⑤：jsPDFでのフォントはデフォルト（helvetica）で仮実装
- **課題:** jsPDFはデフォルトで日本語非対応
- **選択肢:**
  - A: 最初からNotoSansJP等の日本語フォントを埋め込む → ファイルサイズ大、実装コスト高
  - B: まずhelveticaで動作確認、Phase2で日本語フォント対応 → 早くフロー全体を繋げられる
- **決定:** B（段階的実装）
- **理由:** Phase1の目的は「フロー全体を繋げる」こと。文字化けは既知の課題として次フェーズへ
- **結果:** フロー全体が動作確認でき、文字化け箇所も明確になった

### 今回確立したパターン（再利用可能な知見）
- **Service Workerキャッシュ更新パターン:** sw.jsのCACHE_NAMEバージョンを上げないと新ファイルが配信されない。PWAでは必ずsw.jsのバージョンアップが必要
- **screen-loader.js画面登録パターン:** 新しいHTML画面を追加する時は、screen-loader.jsのSCREEN_FILES配列にも画面名を追加する必要がある。receipt-.htmlではなくreceipt.htmlが正しいファイル名（`${screenName}.html` の形式）
- **Termuxファイルパス:** Androidのダウンロードフォルダは `~/Downloads` ではなく `/storage/emulated/0/Download/`

# 4. 📝 Instruction Sheets Summary（指示書の要点記録）

### 今回の特殊性：Claude Code不使用、全てクロちゃん設計→アキヤTermux手動実行
- COCOMI Postman / Claude Codeは今回未使用
- クロちゃんがコード全文を生成 → アキヤがダウンロード → Termuxでgit配置 → sedでHTML編集 → git push
- 指示書形式ではなく「完成コード＋配置手順＋sedコマンド」の形で提供

### 提供物①: receipt-ai.js v0.96（完成コード）
- **ゴール:** 複数レシート分離認識＋後方互換＋日付別グループ化API
- **核心のコード設計:**
```javascript
// Geminiへの新プロンプト: receipts配列を返す
// response format: {receipts: [{date, store, total, type, items[], entry_time, exit_time}]}

// 後方互換レイヤー
function normalizeAiResponse(data) // 旧{storeName,items[]} → 新{receipts:[...]}

// AI結果適用（複数レシート対応）
function applyAiResult(data) // 全レシートの品目をUIに統合表示

// 日付別ゲッター（PDF生成用）
function getReceiptsByDate() // {dateKey: [receipt, ...]}
function getLastAiResults()  // 最後のAI解析結果を返す
var _lastAiReceiptResults = null; // グローバル保持
```
- **完了条件:** AI読み取りが動作し、複数レシートを分離認識できること
- **結果:** ✅完了（駐車場レシートでtype:parking自動判定も成功）

### 提供物②: receipt-pdf.js（完成コード・新規）
- **ゴール:** 日付別PDF生成＆IndexedDB保存
- **核心のコード設計:**
```javascript
// 専用IndexedDB
var RECEIPT_PDF_DB_NAME = 'CULOchanReceiptPDFs';
// ストア: receipt_pdfs (keyPath: 'date'), receipts (keyPath: 'id')

// PDF生成: jsPDF A4縦、レシート画像+ラベル付き
async function generateReceiptPdf(dateKey, receiptDataList, imageDataList)

// メインフロー: AI結果→日付別グループ→PDF生成→IDB保存
async function generateAndSaveReceiptPdfs()

// CRUD
async function saveReceiptPdf(dateKey, pdfBase64, receiptCount, totalAmount)
async function getReceiptPdf(dateKey)
async function listReceiptPdfs() // PDF本体除く一覧（軽量）
async function deleteReceiptPdf(dateKey)
async function viewReceiptPdf(dateKey) // 新タブでPDF表示
```
- **結果:** ✅完了

### 提供物③: receipt-pdf-viewer.js/html（完成コード・新規）
- **ゴール:** 月別PDF一覧画面
- **核心のコード設計:**
```javascript
// 月選択 → IDBからlistReceiptPdfs() → 月フィルタ → 日付カード表示
// 統計バー: 日数・枚数・合計金額
// カードタップ → viewReceiptPdf(dateKey)
// 削除ボタン → confirmDeletePdf(dateKey)
function initReceiptPdfViewer() // showScreen時に呼ばれる
function changeReceiptPdfMonth(delta) // ◀▶ボタン
async function renderReceiptPdfViewer() // メイン描画
```
- **結果:** ✅完了（2026年2月のPDF1件が正しく表示された）

### 提供物④: 配置手順＋sedコマンド群
- Termuxコマンド一式（cp, sed, grep, git add/commit/push）
- 修正サイクルが4回発生（receipt-.html→receipt.html問題、sw.jsキャッシュ問題、アコーディオン化）

# 5. 🐛 Errors & Solutions（エラー＆解決策）

### エラー①: receipt-.htmlを編集したのにUIに反映されない
- **症状:** save-barにPDFボタンを追加したが、ブラウザ上で変化なし
- **発見方法:** キャッシュクリア・Service Worker削除しても変わらず
- **原因分析:**
  - 仮説1: Service Workerキャッシュ → 削除しても変わらず
  - 仮説2: 編集したファイルが間違い → **確定原因**
- **確定原因:** screen-loader.jsが `${screenName}.html` の形式で画面をフェッチしている。SCREEN_FILESに `'receipt'` と登録されているため、実際に読み込まれるのは `receipt.html` であって `receipt-.html` ではない
- **解決:** `receipt.html` のsave-barを編集
- **パターンID:** ERR-CULO-0001
- **再発防止:** 画面HTMLを編集する前に、必ず `screen-loader.js` のSCREEN_FILESを確認して正しいファイル名を特定する
- **学び:** アプリの画面ルーティング仕組みを把握してから編集に入るべき

### エラー②: AI読み取りボタンが反応しない
- **症状:** レシート画像をセットして「AIで読み取る」を押しても何も起きない
- **発見方法:** アキヤ実機テスト
- **原因分析:**
  - 仮説1: receipt-ai.jsの構文エラー → `node -c receipt-ai.js` でエラーなし
  - 仮説2: 関数名の不一致 → ボタンは `runAiOcr()` を呼んでおり、receipt-ai.js 30行目に定義あり
  - 仮説3: sw.jsが古いreceipt-ai.jsをキャッシュ配信 → **確定原因**
- **確定原因:** sw.jsのCACHE_NAME `'reform-app-v2.0.0'` が変更されていなかったため、新しいreceipt-ai.jsがキャッシュに反映されず古いバージョンが配信され続けていた
- **解決コード:**
```bash
# CACHE_NAMEバージョンアップ
sed -i "s|reform-app-v2.0.0|reform-app-v2.1.0|" sw.js
# 新規ファイルもキャッシュリストに追加
sed -i "s|'receipt-ai.js',|'receipt-ai.js',\n  'receipt-pdf.js',\n  'receipt-pdf-viewer.js',\n  'receipt-pdf-viewer.html',|" sw.js
```
- **パターンID:** ERR-CULO-0002
- **再発防止:** ★新ファイル追加・既存ファイル変更時は、**必ずsw.jsのCACHE_NAMEバージョンを上げる**。これを忘れるとPWAで新コードが配信されない
- **学び:** PWAのService Workerキャッシュは通常のブラウザキャッシュクリアでは解消されない。CACHE_NAMEの変更が必須

### エラー③: Termuxの~/Downloadsパスが違う
- **症状:** `cp ~/Downloads/receipt-ai.js ./` で「No such file or directory」
- **確定原因:** Termuxの `~/Downloads` はTermux内部パス。Androidの「ダウンロード」フォルダは `/storage/emulated/0/Download/`
- **解決:** `/storage/emulated/0/Download/` を使用
- **パターンID:** ERR-CULO-0003
- **学び:** Termuxでは `~/` と Android共有ストレージのパスが異なる

### 既知の未解決課題（Phase2へ持ち越し）
- **PDF日本語文字化け:** jsPDFデフォルトのhelveticaフォントは日本語非対応。NotoSansJP等の埋め込みが必要
- **PDF表示方法:** `about:blank` + iframe方式はスマホChromeで使いにくい。ダウンロード方式またはアプリ内ビューアに変更推奨
- **レシート画像の切り出し:** 現在は撮影画像をそのままPDFに貼付。Phase2で角検出＆Canvas切り出しを実装予定

# 6. ✅ Quality Check（品質チェック結果）

### COCOMIルール適合
| チェック項目 | 結果 | 備考 |
|-------------|------|------|
| 各ファイル500行以内 | ✅ | receipt-ai.js: 451行、receipt-pdf.js: 458行 |
| 日本語コメント（全関数） | ✅ | 全ファイルに日本語コメント付き |
| バージョン番号（変更箇所） | ✅ | v0.96表記あり |
| ファイル先頭コメント | ✅ | 各ファイル冒頭にブロックコメントで役割・依存を記載 |
| 既存コード非破壊 | ✅ | normalizeAiResponse()で後方互換維持 |
| sw.jsキャッシュ更新 | ✅ | v2.0.0→v2.1.0に更新済み |

### 動作確認（アキヤ実機テスト）
| テスト項目 | 結果 | 備考 |
|-----------|------|------|
| AI読み取り（駐車場レシート） | ✅ | 店名・金額・日付・type:parkingを正確に認識 |
| PDF生成＆保存 | ✅ | 「PDF生成完了！1日分のPDFを保存しました」表示 |
| PDF一覧画面表示 | ✅ | 2026年2月、1日分、1枚、¥850正しく表示 |
| PDF閲覧（タップ→表示） | ⚠️ | PDFは生成されるがabout:blankで開く。「開く」ボタン押下後にPDFと画像が表示される。日本語文字化け |
| アコーディオン折りたたみ | ✅ | 「📄 PDF機能 ▼」タップで展開/収納動作 |
| 月ナビ（◀▶） | ✅ | 月切り替え動作 |
| Android Chrome動作 | ✅ | Galaxy実機で動作確認済み |
| オフライン動作 | 未テスト | sw.js v2.1.0でキャッシュ登録済みだが未確認 |

# 7. 🗺️ Project Map Diff（プロジェクトマップ差分）

### 現在のファイル構成（関連部分のみ）
```
CULOchanKAIKEIpro/
├── index.html           — メイン画面（receipt-pdf.js, receipt-pdf-viewer.js追加）
├── receipt.html          — レシート読込画面（save-barアコーディオン化） ★変更
├── receipt-ai.js    (451行) — AI解析（複数レシート分離認識） [v0.96] ★変更
├── receipt-pdf.js   (458行) — PDF生成＆IndexedDB保存 [v0.96] ★新規
├── receipt-pdf-viewer.js (155行) — PDF一覧画面ロジック [v0.96] ★新規
├── receipt-pdf-viewer.html (36行) — PDF一覧画面HTML [v0.96] ★新規
├── receipt-core.js (1175行) — レシート基本ロジック（変更なし）
├── receipt-history.js    — レシート履歴管理（変更なし）
├── receipt-list.js       — レシートリスト表示（変更なし）
├── screen-loader.js      — 画面ローダー（receipt-pdf-viewer追加） ★変更
├── sw.js                 — Service Worker [v2.1.0] ★変更
└── ...
```

### 依存関係の変化
- `receipt-pdf.js` → `receipt-ai.js` の `getLastAiResults()` を参照（AI解析結果取得）
- `receipt-pdf.js` → `receipt-core.js` の `receiptImageData` を参照（画像データ取得）
- `receipt-pdf.js` → `jsPDF` (CDN) を使用
- `receipt-pdf-viewer.js` → `receipt-pdf.js` の `listReceiptPdfs()`, `viewReceiptPdf()`, `deleteReceiptPdf()` を参照
- `receipt.html` → `receipt-pdf.js` の `generateAndSaveReceiptPdfs()` をonclickで呼び出し
- `receipt.html` → `screen-loader.js` の `showScreen('receipt-pdf-viewer')` で画面遷移

### IndexedDB変更
- **新規DB:** `CULOchanReceiptPDFs` (version 1)
  - **receipt_pdfs ストア:** keyPath: `date`(YYYY-MM-DD), fields: `pdf_data`(Base64), `receipt_count`, `total_amount`, `updated_at`, index: `updated_at`
  - **receipts ストア:** keyPath: `id`(合成キー), fields: `date`, `type`, `store`, `total`, `items[]`, `entry_time`, `exit_time`, `purpose`, `pdf_date`, `created_at`, indexes: `date`, `type`, `store`

# 8. 🔄 STATE（状態引き継ぎ — 次のセッションへ）

### 完了済み
- レシート管理機能 Phase1 Step 1〜4 全完了
  - Step1: Geminiプロンプト拡張（複数レシート分離認識） ✅
  - Step2: PDF生成モジュール（receipt-pdf.js） ✅
  - Step3: IndexedDB保存・取得 ✅
  - Step4: 日付別閲覧画面（receipt-pdf-viewer） ✅
- 最後にgit pushしたブランチ: main
- 最新commit: `"v2.1.0: SW更新 - キャッシュバージョンアップ＆新規ファイル追加"` + その直前に `"v0.96fix3: PDF機能を折りたたみアコーディオンに変更"`
- sw.js: v2.1.0
- CULOchan会計Pro: v0.96

### 次にやること（Next Mission）
- **ミッション:** M-CULO-096-02: PDF日本語フォント対応（文字化け解消）
- **内容:** jsPDFにNotoSansJP等の日本語フォントを埋め込み、PDF内の店名・品目が正しく表示されるようにする
- **前提条件:** Phase1完了（済み）
- **難易度予想:** 中 — jsPDFのaddFont APIとBase64フォントデータの組み込みが必要。フォントファイルのサイズ（数MB）がPWAキャッシュに影響する可能性

### その次にやること
- **M-CULO-096-03:** PDF表示方法の改善（about:blank→ダウンロード方式 or アプリ内ビューア）
- **M-CULO-097-01:** Phase2 レシート角検出＆Canvas切り出し

### 引き継ぎ注意点（★重要）
- **sw.jsのバージョン管理:** 今回sw.js v2.0.0→v2.1.0に更新した。次回ファイル変更時はv2.2.0に上げること
- **receipt.htmlが正しいファイル名:** `receipt-.html` ではない！screen-loader.jsが `'receipt'` → `receipt.html` をフェッチする
- **Termuxのダウンロードパス:** `/storage/emulated/0/Download/`（`~/Downloads` ではない）
- **PDF文字化けは既知:** jsPDF + helveticaでは日本語が表示されない。次回修正予定
- **receipt-core.jsの `runAiOcr()`:** これがAI読み取りボタンのエントリポイント。receipt-ai.jsの `analyzeReceiptWithGemini()` はrunAiOcrから呼ばれる

### 次のセッションへの指示書ドラフト
```markdown
# 次のミッション概要: PDF日本語フォント対応
1. NotoSansJP-Regular.ttfをBase64変換してreceipt-pdf.jsに組み込む
   - またはCDNから動的読み込み
2. jsPDFのdoc.addFont()でフォント登録
3. doc.setFont('NotoSansJP')で使用
4. generateReceiptPdf()内の全テキスト描画で日本語フォント適用
5. フォントファイルのサイズ考慮（sw.jsキャッシュ、初回読み込み時間）
6. テスト: 店名・品目・日付ラベルが正しく日本語表示されること
```

# 9. ⚠️ Known Issues（既知の問題・技術的負債）

- **PDF日本語文字化け（優先度: 高）** — jsPDFデフォルトフォント(helvetica)は日本語非対応。NotoSansJP埋め込みで解消予定
- **PDF表示方法（優先度: 中）** — about:blank + iframeはスマホChromeで使いにくい。Blob URL + ダウンロード方式に変更推奨
- **レシート画像未切り出し（優先度: 低・Phase2）** — 現在は撮影画像全体をPDFに貼付。背景が写り込む
- **receipt-core.jsが1175行（優先度: 低）** — 500行ルール超過。将来的に分割検討
- **receipt-.htmlの存在** — 使われていないが残っている。削除してもOK

# 10. 📊 Metrics（数値データ）

| 指標 | 値 |
|------|------|
| 設計→実装サイクル | 約8回（修正含む） |
| セッション時間（概算） | 約5時間（12:30〜17:00） |
| git commitの数 | 4個 |
| 追加した総行数（概算） | +925行（新規3ファイル + 既存変更） |
| 今回追加/変更ファイル数 | 新規3 + 変更5 = 計8個 |

# 11. 💭 メタメモ（設計者の気づき・改善提案）

- **screen-loader.jsの存在を最初に確認すべきだった:** 画面HTMLがどのファイル名で読み込まれるかを確認せずに `receipt-.html` を編集してしまい、時間をロスした。次回から「画面追加/編集前にscreen-loader.jsのSCREEN_FILESを確認」を手順に入れる
- **sw.jsのバージョン更新を必ず行う:** PWAアプリではこれを忘れると新コードが配信されない。「ファイル変更→sw.jsバージョンアップ→git push」をワンセットにする
- **sedコマンドの限界:** 複雑なHTML置換はsedだと壊れやすい。Pythonワンライナーのほうが安全。ただしアキヤの操作負荷を考えるとnanoで手動編集のほうが確実な場面も多い
- **アキヤのUXフィードバックが的確:** 「出っぱなしなのかな」→「薄いラインで隠す感じで」という提案がUI改善に直結した。実機テストのフィードバックは設計品質を大きく左右する
- **企画書のフェーズ分割が効果的:** Phase1を「フロー全体を繋げる」に絞ったことで、文字化け等の品質課題があっても「核心が動いた」感が得られた

---

## ✅ Dev-Next-3（開発引継ぎ固定）
1) **今の状態:** Phase1 Step1〜4完了。v0.96 / sw.js v2.1.0。AI→PDF→一覧→閲覧の全フロー動作。PDF日本語文字化け・表示方法に課題あり
2) **次にやる最小の1個:** jsPDFに日本語フォント（NotoSansJP）を埋め込んでPDF文字化け解消
3) **成功したら何ができる:** レシートを撮影→AIで読み取り→日本語の店名・品目が正しく表示されたPDFが自動生成され、日付別に閲覧できる

---

## 📋 MASTER_DEVへの反映事項

### ▼ Mission Historyへの追記
```text
| 2026-02-27 | M-CULO-096-01: レシート管理Phase1 — AI分離認識＆PDF生成＆日付別閲覧 | ⚠️ | [DIFF_DEV_culo-chan_2026-02-27_01] |
```

### ▼ Error Pattern Indexへの追記
```text
| ERR-CULO-0001 | screen-loader画面ファイル名の不一致 | screen-loader.jsのSCREEN_FILESで正しいファイル名を確認してから編集する | 1回 |
| ERR-CULO-0002 | sw.jsキャッシュ未更新による新コード未配信 | sw.jsのCACHE_NAMEバージョンを上げる（例: v2.0.0→v2.1.0） | 1回 |
| ERR-CULO-0003 | Termuxダウンロードパスの違い | ~/Downloadsではなく/storage/emulated/0/Download/を使用 | 1回 |
```

### ▼ Architecture Notesへの追記
```text
- 新規IndexedDB: CULOchanReceiptPDFs（receipt_pdfs + receiptsストア）
- Gemini AI応答形式を {receipts: [...]} に拡張（normalizeAiResponse()で後方互換維持）
- PDF生成にjsPDF使用（CDN読込済み）。日本語フォント未対応（Phase2で対応予定）
- 画面追加時はscreen-loader.jsのSCREEN_FILES配列に登録が必要
- sw.jsキャッシュ: ファイル追加/変更時はCACHE_NAMEバージョンアップ必須
```

### ▼ File Registryへの追記
```text
- `receipt-pdf.js` — PDF生成＆IndexedDB保存 (458行/v0.96)
- `receipt-pdf-viewer.js` — PDF一覧画面ロジック (155行/v0.96)
- `receipt-pdf-viewer.html` — PDF一覧画面HTML (36行/v0.96)
```
