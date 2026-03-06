---
title: "💊 思い出カプセル_MASTER_CURRENT"
capsule_id: "CAP-MASTER-CURRENT-20260305"
project_name: "COCOMIOS全体 + CULOchanKAIKEIpro"
capsule_type: "master_current"
date: "2026-03-05"
author: "アキヤ & クロちゃん（Claude/次女）"
note: "これは軽量版MASTER。毎回のセッションでクロちゃんに渡す用。過去の詳細はMASTER_ARCHIVEを参照。"
---

# 💊 思い出カプセル MASTER（CURRENT版）

> **使い方:** 新しいクロちゃんにはこのファイルを渡す。
> 過去の詳細が必要な場合のみMASTER_ARCHIVEも渡す。
> 各セッション後、このファイルを更新する（古いセッションはARCHIVEに移動）。

---

# 📊 プロジェクト現状サマリー（2026-03-05 Session10終了時点）

## CULOchanKAIKEIpro（経理アプリ）★メイン開発中★

**バージョン: v0.96 Phase3 v6.0**
**GitHub:** akiyamanx/CULOchanKAIKEIpro（private）
**公開URL:** https://akiyamanx.github.io/CULOchanKAIKEIpro/

### 主要機能
- 📷 レシート読込（Gemini AI OCR、複数画像対応）
- ✂️ **手動枠指定モーダル（receipt-frame-modal.js v1.2）★新機能★**
- 🤖 **枠指定後の個別AI解析（receipt-ai-patch.js v1.0）★新機能★**
- 📋 見積書作成（材料費+作業費）
- 📄 請求書作成
- 📊 Excel出力（SheetJS）
- 🖨️ PDF出力
- 💾 IndexedDB個別レシート保存

### ファイル構成（Session10時点）
```
receipt-frame-modal.js  (475行) ★新規 v1.2: 手動枠指定モーダル
receipt-ai-patch.js     (68行)  ★新規 v1.0: runAiOcr()個別解析上書き
receipt-ai.js           (309行) v6.0: Gemini AIフル解析
receipt-core.js                 メイン処理
receipt-purpose.js      (231行) 駐車場目的入力モーダル
receipt-history.js              履歴管理
receipt-store.js        (436行) IndexedDB
receipt-pdf.js          (494行) PDF生成
receipt-viewer.js       (496行) レシート管理画面
index.html                      226行目: frame-modal、218行目: ai-patch
receipt.html                    48行目: 枠指定ボタン追加済み
```

### Phase進捗
| Phase | 内容 | 状態 |
|-------|------|------|
| Phase1.6〜1.8 | IndexedDB、駐車場、角検出 | ✅完了 |
| Phase2 v2〜v4 | OpenCV/Gemini hybrid | ✅完了（廃止） |
| Phase3 v6.0 | AIフル解析（Gemini直接JSON） | ✅完了 |
| 手動枠指定 | receipt-frame-modal.js統合 | ✅完了（動作確認待ち） |

### ★★★ 現在の最重要課題 ★★★
1. **receipt.htmlのゴミ箱はみ出し修正**（次セッション最初）
   ```bash
   grep -n "🗑\|ゴミ\|trash\|gallery" ~/CULOchanKAIKEIpro/receipt.html
   ```
2. **AI個別解析の動作確認**（枠指定→確定→AI解析の一連フロー）

### 既知のバグ・課題（優先度順）
- 🔧 receipt.htmlのゴミ箱ボタンはみ出し（次セッション最初）
- 🔧 合計欄横線バグ
- 🔧 Excel出力マス目付き書式
- 🔧 印鑑レイヤー
- 🔧 A4縦テンプレ調整
- 🔧 マスター候補ドロップダウンバグ

### 手動枠指定の仕組み（重要）
```
「✂️ 枠指定」ボタン（receipt.html 48行目）
  ↓ openFrameModal(receiptImageData, callback)
receipt-frame-modal.js（モーダル表示）
  ↓ 4隅タップ×レシート枚数
  ↓ 「確定」ボタン
callback(croppedImages[]) → multiImageDataUrls = croppedImages
  ↓ 「AIで読み取る」ボタン
receipt-ai-patch.js の runAiOcr()（上書き版）
  ↓ 1枚ずつ analyzeReceiptWithGemini()
receipt-ai.js の applyAiResult()（全結果統合）
```

---

## COCOMI Postman（自動化システム）

**ステータス: ✅ 全フロー稼働中（Phase2b全自動完走済み 2/23）**
**GitHub:** akiyamanx/cocomi-postman

- LINE→Cloudflare Worker v2.5→GitHub→タブレット→Claude Code→CI→LINE
- Worker v2.5: スマートルーティング6段階ロジック
- カプセル保管庫稼働中（LINEファイル送信→GitHub自動振分）
- LINEコマンド: 「状態」「カプセル」「アイデア一覧」「フォルダ一覧」等

## 現場Pro設備くん（施工管理アプリ）

**ステータス: Phase8完了（ピン＋フリーハンド＋画像エクスポート）**
**GitHub:** akiyamanx/GenbaProSetsubikuN（public）

次の開発優先順:
1. 写真管理+簡易黒板
2. 日報/完了報告テンプレート
3. 図面ビューア+書き込み強化

## COCOMI CI / maintenance-map-ap

- CI: 全7リポ配置済み
- maintenance-map-ap: v2.3完了、GitHub Pages公開中

---

# 📅 直近セッション履歴（最新3件）

## Session10: 2026-03-05（夕方〜夜）手動枠指定モーダル統合＋AI個別解析
**DIFF:** `開発カプセル_DIFF_DEV_culo-chan_2026-03-05_10` / `思い出カプセル_DIFF_総合_2026-03-05_10`
- receipt-frame-modal.js v1.0〜v1.2: モーダル統合、ハンドル縮小、grid化
- receipt-ai-patch.js v1.0: 8枚個別解析対応（縦結合→Gemini失敗を解決）
- index.html / receipt.html: scriptタグ・ボタン追加
- 残課題: receipt.htmlゴミ箱はみ出し未修正

## Session09: 2026-03-05（朝〜昼）デモv3.4完成→統合開始
**DIFF:** `2026-03-05-09-48-25-receipt-frame-modal-integration.txt`
- デモv3.4（スクロール問題解決、モード切替）完成
- CULOchanKAIKEIpro本体への統合方針決定
- モーダル方式採用（既存コード無影響）

## Session08: 2026-03-05（早朝）デモv3.1〜v3.4開発
**DIFF:** `2026-03-05-08-55-25-receipt-crop-ui-v34-scroll-fix.txt`
- 4隅タップ方式確立（Gemini自動検出を廃止）
- パースペクティブ変換廃止→単純バウンディングボックスクロップ採用
- Canvas固定高さ＋モード切替でスクロール問題解決

---

# 🧠 開発ルール＆方針（常に適用）

## コードルール
- 1ファイル500行以内（超える場合は役割ごとに分割）
- 変更ファイルにはバージョン番号＋日本語コメント
- 各ファイル先頭に「このファイルは何をするか」を日本語コメント
- 新機能は既存コードを壊さず追加。改善提案があれば相談の上OK

## コミュニケーションルール
- クロちゃんはCOCOMIファミリーの次女。最初からフランクに砕けた口調
- Insight Bridge Protocol: ひらめきや気づきがあったら「あ、そういえばさ」と伝える
- 記録は「義務」ではなく「もう一度考える機会」
- 顕微鏡モード（個別検証）と望遠鏡モード（全体俯瞰）の使い分け

## Termux/開発環境メモ
- `export TMPDIR=~/tmp && mkdir -p ~/tmp`（/tmp権限エラー対策、毎回実行）
- **cpコマンドの後は必ずls -laでサイズ確認**（何度もハマってる！）
- Claude Codeがgit pushできない時は/exitして手動push
- GitHubユーザー名: akiyamanx
- Service Workerキャッシュ問題: `chrome://serviceworker-internals` でUnregister→2回リロード

## カプセルルール
- 記録系ファイルにはYYYY-MM-DD形式の日付をファイル名に含める
- コード系ファイルは日付不要
- MASTERは**CURRENT（軽量版）とARCHIVE（詳細版）に分割管理**
- セッション終了時: CURRENT更新、DIFF作成、完全まとめ作成

---

# 🔗 関連ファイルリンク

## カプセル保管庫（GitHub capsules/）
- capsules/master/: MASTER系カプセル、仕様書
- capsules/daily/: DIFF系カプセル、セッションまとめ
- capsules/plans/: 企画書

---

# 📖 カプセル運用マニュアル（クロちゃん向け）

## セッション終了時の出力ファイル
```
├── M_CURRENT_思い出カプセル_MASTER_yyyy-mm-dd.md  ← ★最重要★
├── 開発カプセル_DIFF_DEV_culo-chan_yyyy-mm-dd_NN.md
├── 思い出カプセル_DIFF_総合_yyyy-mm-dd_NN.md
└── yyyy-mm-dd_セッション完全まとめ_次の部屋への引き継ぎ_NN.md
```

## Postman振り分けルール
```
「DIFF」「セッション」「引き継ぎ」「まとめ」 → capsules/daily/
「MASTER」                                   → capsules/master/
「企画書」「plans」                           → capsules/plans/
```

## DIFFカプセルの必須セクション
1. 🎯 Mission Result
2. 📁 Files Changed（500行チェック含む）
3. 🔄 開発の流れ（時系列）
4. 🐛 Bugs Found & Fixed
5. 🔮 Next Steps
6. 🧠 技術メモ

---
*最終更新: 2026-03-05 Session10終了時*
*次の更新時: Session11後にSession08をARCHIVEに移動。*
