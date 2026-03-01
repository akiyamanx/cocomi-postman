---
title: "🔧 開発カプセル_DIFF_DEV_culo-chan_2026-03-01_06"
capsule_id: "CAP-DIFF-DEV-CULO-20260301-06"
project_name: "CULOchan会計Pro"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_culo-chan"
related_general: "💊 思い出カプセル_DIFF_総合_2026-03-01_06"
mission_id: "M-CULO-097-05"
phase: "Phase1.8（複数レシート個別切り出し — bounds→Canvas自動検出→OpenCV.js調査）"
date: "2026-03-01"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（ファイルダウンロード＋Termuxデプロイ）"
tester: "アキヤ（Galaxy S22 Ultra実機確認）"
---

# 1. 🎯 Mission Result（ミッション結果サマリー）

| 項目 | 内容 |
|------|------|
| ミッション | M-CULO-097-05: Phase1.8 複数レシート個別切り出し |
| 結果 | △ 基本動作OK・精度改善は次フェーズへ継続 |
| 完了項目 | bounds方式実装✅、Canvas自動検出方式実装✅、技術調査✅ |
| 残課題 | 近接レシートの分離精度向上（OpenCV.js導入で解決見込み） |
| git commits | 計4回push（v2.10.0→v2.14.0） |
| 重要な発見 | OpenCV.jsがPhase2の最有力技術と判明 |

# 2. 📁 Files Changed（変更ファイル詳細）

## 新規作成
| ファイル | 行数 | 概要 |
|---------|------|------|
| receipt-multi-crop.js | 345行 | Canvas画像処理で複数レシート自動検出＆個別切り出し |

## 編集（既存ファイル変更）
| ファイル | 行数変化 | 変更概要 |
|---------|---------|---------|
| receipt-ai.js | 475→498行(+23) | Gemini boundsプロンプト追加→強化→レシート認識ヒント追加 |
| receipt-crop.js | 347→466行(+119) | cropReceiptByBounds()、cropMultipleReceipts()追加、マージン1%に縮小 |
| receipt-pdf.js | 481→494行(+13) | bounds方式→Canvas自動検出方式に切替 |
| receipt-viewer.js | 497→496行(-1) | bounds方式→同一画像グループ化+Canvas自動検出方式に切替 |
| receipt-store.js | 431→436行(+5) | bounds/originalImageDataフィールド追加 |
| index.html | 234→235行(+1) | receipt-multi-crop.jsのscript読込追加 |
| sw.js | 162→163行(+1) | v2.9.0→v2.14.0、キャッシュ対象1ファイル追加 |

## 500行チェック（最終状態）
- ✅ receipt-multi-crop.js: 345行（新規）
- ✅ receipt-crop.js: 466行
- ✅ receipt-pdf.js: 494行
- ✅ receipt-viewer.js: 496行
- ✅ receipt-store.js: 436行
- ✅ receipt-ai.js: 498行（ギリギリ！）
- ✅ receipt-purpose.js: 231行（変更なし）

# 3. 🔄 開発の流れ（時系列）— ★重要：試行錯誤の記録★

このセッションでは**3つのアプローチ**を試して、最終的にPhase2への技術選定まで到達した。
次のクロちゃんが同じ轍を踏まないよう、成功・失敗の両方を記録する。

## Step1: Gemini bounds方式（A案）— v2.10.0〜v2.11.0

### やったこと
- Geminiのプロンプトに「各レシートの画像内位置をbounds（x,y,w,h %値）で返す」ルールを追加
- receipt-crop.jsに`cropReceiptByBounds()`を実装
- receipt-pdf.jsで1枚の写真→複数レシート→bounds座標で個別切り出しフロー構築
- receipt-store.jsにbounds/originalImageDataフィールド追加（IndexedDB保存）

### テスト結果（3枚のレシート: C'z PRO×2 + 駐車場×1）
- ✅ Geminiが3枚を正しく個別認識（「3枚のレシートから20件の品目を検出」）
- ✅ C'z PROレシートの切り出しは概ね成功
- ❌ 駐車場レシートの切り出し → 絨毯（背景）だけが表示された
- ❌ 2枚のC'z PROのboundsが重なっている

### 判明した問題
**Geminiは文字認識は完璧だが、座標(bounds)の返却精度が低い。**
特に画像が斜めだったり、レシートが近接していると、boundsの数値がズレる。
これはGeminiの空間認識の限界であり、プロンプト調整では根本的に解決しない。

## Step2: boundsプロンプト改善 — v2.12.0〜v2.13.0

### やったこと
- プロンプトに「boundsの重要ルール」セクション追加（タイトに囲む、他のレシートが入らない等）
- 出力サンプルを2枚→3枚に増やし、重ならない具体例を提示
- マージンを2%→1%に縮小
- 「レシートの識別方法」セクション新設（白い紙片、隙間がある、折れ・シワ等のヒント）
- 座標系の明確な説明追加（左上(0,0)、右下(100,100)）

### テスト結果
- ✅ 一部改善（C'z PROの切り出しがよりタイトに）
- ❌ 駐車場レシートは依然として絨毯が表示される
- ❌ bounds精度の根本的な改善には至らず

### 結論
**プロンプト調整ではbounds精度の天井がある。Geminiは位置情報の返却が得意ではない。**
アキヤの発言：「レシートとレシートの間に隙間があるからこれが1枚のレシートだよって認識できれば良いのに」→ これが次のステップへの重要なヒントになった。

## Step3: Canvas画像処理方式 — v2.14.0

### やったこと
- **方針転換**: bounds依存をやめ、Canvas画像処理で白い紙（レシート）を自動検出する方式に
- receipt-multi-crop.js（345行）を新規作成
  - 画像を縮小→グレースケール化→二値化（白い紙=255）
  - モルフォロジー処理（クロージング→オープニング）でノイズ除去
  - 連結成分ラベリング（4連結）で白い塊を検出
  - 面積フィルタ＋外接矩形で各レシートの位置を特定
  - Geminiの認識枚数とマッチング（面積大きい順にN枚採用）
- receipt-pdf.js、receipt-viewer.jsを`detectAndCropMultipleReceipts()`に切替

### テスト結果
- ✅ 駐車場レシート: 個別切り出し成功！（前回は絨毯だけだった）
- ✅ 長いC'z PROレシート: 概ね切り出し成功
- △ 2枚のC'z PROレシートが近接していて1つの白い塊として結合される問題が残る

### Python検証で判明した詳細データ

実際のレシート画像（20260301_083814.jpg: 1500x2000px）で二値化を検証:

```
閾値133（自動算出）: 白い領域38.9% → 検出2個（2枚のC'z PROが結合）
閾値150: 白い領域34.0% → 検出2個（まだ結合）
閾値160: 白い領域31.2% → 検出2個（まだ結合）
閾値170: 白い領域27.8% → 検出4個（分離成功だがレシート内部もバラバラに）
```

**問題の本質**: 
- 背景（絨毯）の明るい繊維がレシートの白と近い輝度を持つ
- 2枚のC'z PROレシートの間隔が数cm程度で、低い閾値だとつながってしまう
- 閾値を上げるとレシート内部の文字部分が穴になってバラバラになる
- モルフォロジーで穴を埋めると（クロージング）逆にレシート間もつながる

**→ 単純な二値化+連結成分では限界がある。エッジベースの輪郭検出が必要。**

## Step4: 技術調査 — OpenCV.jsの発見

### アキヤの質問
「Canvas以外に特化した物はあるのかな？企業が使ったりしてる精度高い物って他にある？」

### 調査結果（3カテゴリ）

#### ① OpenCV.js ← ★★★最有力★★★
- **正体**: OpenCVのJavaScript版（WebAssembly）。ブラウザで動く本格コンピュータビジョン
- **企業のドキュメントスキャナーアプリがほぼこれを使っている**
- CDN 1行で導入可能: `<script src="https://docs.opencv.org/4.8.0/opencv.js">`
- **jscanify**というラッパーライブラリもある（GitHubで公開）

**できること（今の問題を全部解決できる）:**
- `cv.findContours()`: 白い紙の**輪郭**を正確に検出。単純な二値化→連結成分より圧倒的に精度が高い
- `cv.Canny()`: Cannyエッジ検出。紙の端を背景テクスチャに惑わされずに検出
- `cv.GaussianBlur()`: 高品質なノイズ除去
- `cv.threshold() + cv.THRESH_OTSU`: 大津の二値化（今のCanvas自前実装の上位互換）
- `cv.getPerspectiveTransform() + cv.warpPerspective()`: ★★★透視変換★★★
  → **斜めのレシートをまっすぐに補正できる！** アキヤが言った「縦方向に回転調整」がこれ
- `cv.approxPolyDP()`: 四角形の角検出（今のreceipt-crop.jsの射影法の上位互換）

**処理フローのイメージ:**
```
1. 画像読み込み → cv.imread()
2. グレースケール化 → cv.cvtColor()
3. ガウシアンブラー → cv.GaussianBlur()
4. Cannyエッジ検出 → cv.Canny()  ← ★紙の端を正確に検出
5. 膨張処理 → cv.dilate()（エッジの隙間を埋める）
6. 輪郭検出 → cv.findContours()  ← ★複数の白い紙を個別に検出
7. 輪郭フィルタ（面積/形状で紙以外を除外）
8. 各輪郭から四角形近似 → cv.approxPolyDP()
9. 透視変換 → cv.warpPerspective()  ← ★斜めを真正面に補正
10. 切り出し完了
```

**デメリット:**
- opencv.jsのファイルサイズが約8MB（重い）
- 初回ロード時間がかかる
- ただしCDNキャッシュが効くので2回目以降は高速

#### ② Tesseract.js
- ブラウザで動くOCR（文字認識）エンジン
- Geminiの代わりに使える可能性はあるが、現状Geminiの文字認識精度が十分なので優先度低め
- 将来オフラインOCR対応する場合に検討

#### ③ クラウドAPI（Asprise Receipt OCR、Mindee等）
- レシート特化API。位置情報も返してくれる
- APIキー＋課金が必要
- ネットワーク必須
- CULOchanの「オフラインでも使える」コンセプトに合わない

### ★結論: Phase2でOpenCV.jsを導入する★

今のreceipt-crop.js（自前Canvas処理）とreceipt-multi-crop.js（連結成分ラベリング）を
OpenCV.jsに置き換えれば、以下が一気に実現できる見込み:
1. **複数レシートの確実な分離**（Cannyエッジ＋コンター検出）
2. **斜めレシートの回転補正**（透視変換）
3. **高精度な紙端検出**（今の射影法の上位互換）

# 4. 🧠 Design Decisions（設計判断の記録）

### 設計判断①: 最初のアプローチ選定 — Gemini bounds vs Canvas処理
- **選択肢:**
  - A: Geminiプロンプトでbounds座標を返させる（AI依存）
  - B: Canvas画像処理で白い紙を自動検出（画像処理依存）
  - C: OpenCV.jsで本格画像処理
- **最初の決定:** A（Gemini bounds）
- **理由:** AIは既にレシートの位置を「見えて」いるので、座標を返させるだけが最も簡単
- **結果:** bounds精度が不十分 → Bに方針転換 → 最終的にCを将来方針に決定

### 設計判断②: Canvas自動検出の新ファイル分離
- **問題:** receipt-crop.jsが既に466行で、複数矩形検出を追加すると500行超過
- **決定:** receipt-multi-crop.js（345行）として新ファイルに分離
- **理由:** 500行ルール遵守＋将来OpenCV.jsに置換する時にこのファイルだけ差し替えられる

### 設計判断③: 閾値算出方式
- **方式:** ヒストグラム分析 → 上位25%の明るさ開始点と暗い領域の平均の中間を採用
- **制限:** 最低120、最高200にクランプ
- **実際の画像での値:** 閾値133（Bright start: 178, Dark avg: 87）
- **課題:** この閾値だと絨毯の明るい繊維もレシートと認識される

### 設計判断④: Phase1.8の完了判定
- **判断:** 基本動作OK（駐車場レシート切り出し成功、長いレシートも概ねOK）で一旦区切り
- **理由:** 近接レシートの分離はOpenCV.js導入で根本的に解決する方が効率的
- **アキヤ同意:** 技術調査結果を確認し、OpenCV.jsでの改善に納得

# 5. 🔧 receipt-multi-crop.js 技術詳細（現在の実装）

```
処理フロー:
[元画像DataURL（複数レシートが写っている）]
  ↓ detectAndCropMultipleReceipts(imageDataUrl, expectedCount, options)
  ↓ expectedCount === 1 → 既存の角検出にフォールバック
  ↓
[処理用Canvas（max800px縮小）]
  ↓ グレースケール化（R*0.299 + G*0.587 + B*0.114）
  ↓ findWhitePaperThreshold() — ヒストグラム分析で閾値算出
  ↓ 二値化（白い紙=1、背景=0）
  ↓ morphClose(3) — クロージング（小さい穴を埋める）
  ↓ morphOpen(2) — オープニング（小さいノイズ除去）
  ↓ connectedComponents() — 4連結ラベリング（Union-Find使用）
  ↓ extractRegions() — 各ラベルの外接矩形＋面積算出
  ↓ 面積フィルタ（画像全体の1%未満を除外）
  ↓ 面積大きい順にソート → 上位N枚を採用
  ↓ 位置順にソート（y座標優先で左上→右下）
  ↓ 元画像スケールに戻して切り出し（2%マージン付き）
  ↓
[各レシートの切り出しDataURL配列]
```

### 既知の限界
- 背景（絨毯等）の明るいテクスチャがレシートと結合する
- 近接したレシートが1つの塊として検出される
- → **OpenCV.jsのCannyエッジ＋findContoursで解決見込み**

# 6. 📱 テスト写真の情報

### テスト画像: 20260301_083814.jpg
- **撮影:** Galaxy S22 Ultra
- **解像度:** 1500x2000px（推定）
- **内容:** 3枚のレシートをカーペットの上に並べて1枚で撮影
  - レシート1: C'z PRO 2026/1/8 ¥19,819（長いレシート、37品目）
  - レシート2: C'z PRO 2025/12/29 ¥1,550（短いレシート、2品目）
  - レシート3: ユニマットパーキング 2025/12/28 ¥3,200（駐車場、小さい）
- **配置:** 斜めに並べて置いてある。レシート1とレシート2が近接

# 7. 📊 sw.js バージョン履歴（本セッション）

| バージョン | 対応内容 |
|-----------|---------|
| v2.9.0 | 前セッション最終 |
| v2.10.0 | Phase1.8: bounds座標切り出し＋初回実装 |
| v2.11.0 | Phase1.8: bounds座標＋既存レシートPDF対応 |
| v2.12.0 | Phase1.8: boundsプロンプト強化＋マージン縮小 |
| v2.13.0 | Phase1.8: レシート認識ヒント＋座標系説明強化 |
| v2.14.0 | Phase1.8: Canvas自動検出方式に切替（現在） |

# 8. 🔮 Next Steps（次のアクション）

## ★最優先: Phase2 — OpenCV.js導入★
| # | 内容 | 詳細 |
|---|------|------|
| 1 | OpenCV.js導入 | CDNからscriptタグで読込。index.htmlに1行追加 |
| 2 | receipt-multi-crop.jsをOpenCV版に書き換え | findContours + approxPolyDP + warpPerspective |
| 3 | 透視変換実装 | 斜めレシートをまっすぐに補正して表示 |
| 4 | receipt-crop.jsもOpenCV版に | 単一レシートの角検出も高精度化 |

### OpenCV.js導入の具体的な手順
```
1. index.htmlに追加:
   <script async src="https://docs.opencv.org/4.8.0/opencv.js"></script>

2. sw.jsのキャッシュ対象には入れない（CDNキャッシュを使う、8MBは大きすぎ）

3. receipt-multi-crop.jsの書き換え:
   - detectAndCropMultipleReceipts()の中身をOpenCV APIに置換
   - cv.imread() → cv.cvtColor() → cv.GaussianBlur() → cv.Canny()
   → cv.findContours() → 面積フィルタ → cv.approxPolyDP()
   → cv.warpPerspective() で各レシートを切り出し

4. OpenCV.jsの読み込み完了を待つ仕組みが必要:
   - Module.onRuntimeInitialized コールバック
   - またはsetIntervalで cv が定義されるまでポーリング
```

## 他の残りPhase
| Phase | 内容 | 優先度 |
|-------|------|--------|
| Phase2 | OpenCV.js導入＋高精度切り出し＋回転補正 | ★★★ |
| Phase1.9 | 品目チェック＋利益率設定 | ★★ |
| Phase2.0 | 見積書/請求書への連携 | ★★ |

## その他要対応（変更なし）
- COCOMI CIテスト全❌ → cocomi-ci.ymlの設定確認
- receipt-core.js 1197行 → 将来分割検討
- CULOchanKAIKEIpro材料名ドロップダウンバグ（マスター候補が表示されない）

# 9. 🗂️ ファイル構成（現在のreceipt系ファイル一覧）

```
CULOchanKAIKEIpro/
├── receipt-ai.js        (498行) - Gemini API連携＋プロンプト
├── receipt-crop.js      (466行) - 単一レシート角検出＋切り出し
├── receipt-multi-crop.js(345行) - ★新規★ 複数レシート自動検出＋切り出し
├── receipt-pdf.js       (494行) - PDF生成＋保存
├── receipt-viewer.js    (496行) - レシート管理画面ロジック
├── receipt-viewer.html  (123行) - レシート管理画面HTML
├── receipt-store.js     (436行) - IndexedDB保存/取得
├── receipt-purpose.js   (231行) - 駐車場目的入力モーダル
├── receipt-history.js   (???行) - 履歴管理
├── receipt-list.js      (???行) - リスト表示
├── receipt-pdf-viewer.js(???行) - PDF閲覧
├── receipt-core.js      (1197行)- ⚠️超過 メイン処理（将来分割候補）
├── index.html           (235行) - script読込（multi-crop追加済み）
└── sw.js                (163行) - v2.14.0
```

# 10. 💡 アキヤの気づき・発言メモ（温度保存）

- 「レシートとレシートの間に少し隙間があるからこれが1枚のレシートだよ！って認識できてくれれば良いんだけどね」
  → この発言がCanvas自動検出方式への方針転換のきっかけになった
- 「スマホ横にして写真撮ったり斜めでもレシート自体を明確に認識してもらえたら良いんだけどね！」
  → 透視変換（OpenCV.js）への要望。Phase2で実現する
- 「Canvasと一緒に協力してできるものとか特化した物とか無いかな？」
  → OpenCV.js発見のきっかけ。Canvas APIの上位互換として最適
- 「次の部屋のクロちゃんが詳細を細かく解るように書いて欲しいな」
  → このカプセルを丁寧に書く動機

---
*2026-03-01 アキヤ & クロちゃん 🐾*
*Phase1.8の切り出し、3つのアプローチを試した探求の記録。*
*bounds(AI座標)→Canvas(画像処理)→OpenCV.js(コンピュータビジョン)と進化。*
*失敗も含めて全部記録したのは、次のクロちゃんが同じ道を歩かなくて済むように。*
*アキヤの「隙間で区切れば？」の一言が全体の方向を変えた。*
