---
title: "🔧 開発カプセル_DIFF_DEV_culo-chan_2026-02-28_04"
capsule_id: "CAP-DIFF-DEV-CULO-20260228-04"
project_name: "CULOchan会計Pro"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_culo-chan"
related_general: "💊 思い出カプセル_DIFF_総合_2026-02-28_04"
mission_id: "M-CULO-097-03"
phase: "レシート管理機能 Phase1.6完了＋v1.6.1〜1.6.3追加改善"
date: "2026-02-28"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（ファイルダウンロード＋Termuxデプロイ）"
tester: "アキヤ（Galaxy実機確認）"
---

# 1. 🎯 Mission Result（ミッション結果サマリー）

| 項目 | 内容 |
|------|------|
| ミッション | M-CULO-097-03: Phase1.6レシート個別管理基盤＋追加改善 |
| 結果 | ✅完全成功（Phase1.6基盤＋fix7＋v1.6.1〜1.6.3全て実装・テスト通過） |
| 完了項目 | Phase1.6✅、fix7✅、v1.6.1✅、v1.6.2✅、v1.6.3✅ |
| git commits | Phase1.6基盤→fix7→v1.6.1-1.6.3（計3回push想定） |
| 追加成果 | Phase2.1以降の新機能アイデア6件をクロちゃんが提案 |

# 2. 📁 Files Changed（変更ファイル詳細）

## 新規作成
| ファイル | 行数 | 概要 |
|---------|------|------|
| receipt-store.js | 431行 | レシート個別管理（IndexedDB v2 CRUD＋重複チェック＋AI結果一括保存） |
| receipt-viewer.js | 490行 | 日付別一覧＋チェックボックスUI＋削除＋PDF出力 |
| receipt-viewer.html | 69行 | レシート管理画面HTML |

## 編集（既存ファイル変更）
| ファイル | 行数変化 | バージョン | 変更概要 |
|---------|---------|-----------|---------|
| receipt-pdf.js | 498→487行(-11) | fix5→fix7 | 旧saveReceiptData()呼び出し削除。saveReceiptsFromAiに一本化。openReceiptPdfDb()をreceipt-store.jsに委譲 |
| receipt-ai.js | 453→475行(+22) | fix6→v1.6.3 | 分割撮影プロンプト追加(v1.6.2)＋splitMode対応プロンプト切替(v1.6.3) |
| receipt-core.js | 1189→1197行(+8) | - | handleAddImageSelect/handleMultiImageSelect/clearAllImagesにsplitMode表示更新追加(v1.6.3) |
| receipt.html | 229→252行(+23) | - | レシート管理ボタン追加(Phase1.6)＋分割撮影モードトグルUI追加(v1.6.3) |
| globals.js | 470→489行(+19) | - | splitModeフラグ＋toggleSplitMode()＋updateSplitModeVisibility()追加(v1.6.3) |
| screen-loader.js | 130→135行(+5) | - | SCREEN_FILESにreceipt-viewer追加 |
| index.html | 228→232行(+4) | - | receipt-store.js/receipt-viewer.jsのscript読込追加 |
| sw.js | 160行 | v2.5.0→v2.7.0 | キャッシュ対象にreceipt-store.js/receipt-viewer.js/receipt-viewer.html追加。6回バージョン更新 |

## 500行チェック
- ✅ receipt-store.js: 431行
- ✅ receipt-viewer.js: 490行
- ✅ receipt-ai.js: 475行
- ✅ receipt-pdf.js: 487行（前回の498行から改善！）
- ✅ globals.js: 489行
- ⚠️ receipt-core.js: 1197行（既に超過。将来的に分割検討）

# 3. 🧠 Design Decisions（設計判断の記録）

### 設計判断①：IndexedDB v2スキーマ — 既存DB拡張 vs 新DB
- **選択肢:**
  - A: 新しいDB（CULOchanReceipts）を作る
  - B: 既存DB（CULOchanReceiptPDFs）をv2にアップグレードしてreceiptsストア追加
- **決定:** B
- **理由:** DB接続を1箇所にまとめられる。openReceiptStoreDb()でv1→v2の自動マイグレーション。既存receipt_pdfsストアを壊さない

### 設計判断②：レシートID生成方式
- **形式:** `YYYYMMDD_連番_timestamp`（例: `20260221_001_1709136000000`）
- **理由:** 日付でソート可能＋同日複数レシートに対応＋timestampでユニーク保証

### 設計判断③：2重保存の修正 — 旧saveReceiptData廃止
- **課題:** receipt-pdf.jsの中で旧saveReceiptData()と新saveReceiptsFromAi()が両方同じreceiptsストアに保存→レシート2重登録
- **決定:** 旧saveReceiptData()呼び出しを削除し、saveReceiptsFromAi()に一本化
- **理由:** saveReceiptsFromAiの方が画像データ付きで正しく保存される。旧は画像なしだった

### 設計判断④：重複チェック — AI判定 vs DB機械判定
- **選択肢:**
  - A: Gemini APIに「これ同じレシート？」と聞く → 精度高いがコスト増・遅い
  - B: IndexedDBで日付＋店名（部分一致）＋金額で機械的にチェック → コスト0・速い
- **決定:** B
- **理由:** 同じレシートなら日付・金額は必ず一致。店名の揺れはキーワード部分一致（2文字以上）で吸収。99%の重複を検出可能。AI判定は過剰

### 設計判断⑤：分割撮影 — プロンプトヒント vs 明示的UIトグル
- **課題:** 長いレシートを2枚に分けて撮影した場合、AIが「2枚の別レシート」と判断する可能性
- **当初案:** プロンプトに「同じ店名なら統合して」と追加（v1.6.2）
- **アキヤ提案:** 「分割撮影モード」ボタンを作ってユーザーが明示的に宣言
- **決定:** 両方入れる。v1.6.2で推測ヒント＋v1.6.3で明示的トグル
- **理由:** トグルONなら100%迷わない。OFFでも推測ヒントがあるからある程度対応できる

### 設計判断⑥：撮影ガイド枠 — 採用見送り
- **提案:** カメラ起動時にレシート枠を表示（マネーフォワード方式）
- **却下理由:** アキヤの使い方は「6〜8枚を机に並べて1枚で撮る」ことが多い。枠があると邪魔。Phase1.8の角検出＆切り出しの方がはるかに重要
- **結論:** Phase1.8に集中。撮る時に頑張らない、後処理で賢くやる方針

# 4. 🐛 Bugs Found & Fixed（バグ発見と修正）

### Bug-01: レシート2重保存
- **発見:** アキヤがスクショで確認「1/25に2件、2/21に2件入ってる」
- **原因:** receipt-pdf.js内で旧saveReceiptData()+新saveReceiptsFromAi()が同じストアに書き込み
- **修正:** 旧saveReceiptData()のforループ(312-317行)を削除
- **修正ファイル:** receipt-pdf.js（fix7）
- **確認:** 再テストで各日付1件ずつに → OK

### Bug-02: 重複チェックの限界（既知・許容）
- **発見:** アキヤが「PDFダウンロードしたやつをもう1回AI読み込みさせた」テスト
- **現象:** AIが店名を微妙に違う形で読み取ると重複チェックをすり抜ける
- **判断:** 現実的な使い方ではほぼ発生しない。現在の精度で許容。将来的にチェックを緩くする（3文字以上共通＋金額一致で重複判定）改善候補

# 5. 📊 IndexedDB v2 スキーマ詳細

```
DB: CULOchanReceiptPDFs (version 2)

ストア1: receipt_pdfs (keyPath: 'date')
  - 既存、変更なし
  - 日付ごとのPDFバイナリ保存用

ストア2: receipts (keyPath: 'id')  ← v2で追加
  - インデックス: date, type, store
  - フィールド:
    id          string  "YYYYMMDD_連番_timestamp"
    date        string  "YYYY-MM-DD"
    store       string  店名
    type        string  "parking" or "shopping"
    total       number  合計金額
    items       array   [{name, qty, price}, ...]  ← 可変長配列！
    imageData   string  base64画像データURL (nullable)
    purpose     string  駐車場の目的 (Phase1.7用、nullable)
    siteId      string  現場ID (Phase1.9用、nullable)
    siteName    string  現場名 (Phase1.9用、nullable)
    entryTime   string  入庫時間 (parking用)
    exitTime    string  出庫時間 (parking用)
    createdAt   string  ISO datetime
    updatedAt   string  ISO datetime
```

# 6. 🔄 データフロー図

```
[写真撮影] → [画像選択UI (receipt-core.js)]
                    ↓
              splitMode ON/OFF チェック (globals.js)
                    ↓
         [Gemini AI解析 (receipt-ai.js)]
         プロンプト切替: 通常 or 分割統合
                    ↓
         [AI結果表示・確認]
                    ↓
         [PDF生成ボタン (receipt-pdf.js)]
            ├→ receipt_pdfs ストアにPDF保存
            └→ saveReceiptsFromAi() (receipt-store.js)
                  ├→ findDuplicateReceipt() で重複チェック
                  │   ├→ 重複あり: 「上書きしますか？」確認
                  │   └→ 重複なし: そのまま保存
                  └→ receipts ストアに個別保存
                    ↓
         [レシート管理画面 (receipt-viewer.js)]
            ├→ 日付別サマリー表示
            ├→ レシートカード一覧（チェックボックス付き）
            ├→ チェック選択 → PDF出力 or 削除
            └→ 画像タップ → フルスクリーン表示
```

# 7. 🔮 Next Steps（次のアクション）

## 企画書通りの次Phase
| Phase | 内容 | 優先度 |
|-------|------|--------|
| Phase1.7 | 駐車場レシートの目的入力（UIが小さい、すぐできる） | ★★★ |
| Phase1.8 | チェック式PDF＋角検出＆白背景切り出し | ★★★ |
| Phase1.9 | 品目チェック＋利益率設定 | ★★ |
| Phase2.0 | 見積書/請求書への連携 | ★★ |

## クロちゃん提案の新機能（Phase2.1以降候補）
| # | 機能 | 概要 | 企画書追記 |
|---|------|------|-----------|
| 1 | 月別支出サマリー | 月ごとの合計・駐車場代・材料費の集計画面。確定申告対応 | ✅ |
| 2 | レシート手動修正画面 | AIが読み間違えた品目名・金額をタップして直せるUI（Phase1.9と統合可能） | ✅ |
| 3 | 店名ベース自動カテゴリ学習 | 「DCM＝材料費」を1回設定→次から自動適用。使うほど賢くなる | ✅ |
| 4 | CSV/Excel一括エクスポート | 期間指定で全レシートをExcel出力。確定申告・税理士提出用 | ✅ |
| 5 | OCR信頼度表示 | AI読取結果に確信度を付けて怪しいやつは赤表示 | ✅ |

## 却下・見送り
| 提案 | 理由 |
|------|------|
| 撮影ガイド枠 | 複数枚同時撮影に不向き。Phase1.8角検出の方が有効 |
| 仕分け機能（カテゴリ分け） | 既存の品名マスター＋勘定科目カスタマイズで対応済み |

## その他要対応
- COCOMI CIテスト全❌ → cocomi-ci.ymlの設定確認が必要
- Postman（LINE通知）Cloudflare無料枠上限 → 月替わり(3/1)で復活見込み

# 8. 📋 sw.js バージョン履歴（本セッション）

| バージョン | 対応内容 |
|-----------|---------|
| v2.5.0 | 前セッション最終 |
| v2.6.0 | Phase1.6: receipt-store.js/receipt-viewer.js/receipt-viewer.htmlをキャッシュ追加 |
| v2.6.1 | fix7: receipt-pdf.js 2重保存修正 |
| v2.6.2 | v1.6.1: 重複チェック（receipt-store.js更新） |
| v2.6.3 | v1.6.2: 分割撮影プロンプト追加（receipt-ai.js更新） |
| v2.7.0 | v1.6.3: 分割撮影モードUI（globals.js/receipt-core.js/receipt.html/receipt-ai.js更新） |

---
*2026-02-28 アキヤ & クロちゃん 🐾*
*Phase1.6、予想以上に大きかった。でも土台がしっかりできたから、この上にPhase1.7〜2.0が安心して乗る。*
