---
title: "🔧 開発カプセル_DIFF_DEV_culo-chan_2026-03-05_10"
capsule_id: "CAP-DIFF-DEV-CULO-20260305-10"
project_name: "CULOchan会計Pro"
capsule_type: "diff_dev"
related_master: "M_CURRENT_思い出カプセル_MASTER_2026-03-05.md"
related_general: "思い出カプセル_DIFF_総合_2026-03-05_10.md"
mission_id: "M-CULO-096-10"
phase: "Phase3 v6.0（AIフル解析）+ 手動枠指定モーダル統合（Session09後半〜Session10）"
date: "2026-03-05"
designer: "クロちゃん (Claude Sonnet 4.6)"
executor: "アキヤ（ファイルダウンロード＋Termuxデプロイ）"
tester: "アキヤ（Galaxy S22 Ultra実機確認）"
---

# 1. 🎯 Mission Result

| 項目 | 内容 |
|------|------|
| ミッション | M-CULO-096-10: 手動枠指定モーダルのCULOchanKAIKEIpro本体統合＋AI解析修正 |
| 結果 | ✅ 統合完了。AI個別解析対応完了。ゴミ箱はみ出し未完了 |
| 完了項目 | receipt-frame-modal.js v1.0→v1.2 ✅、receipt-ai-patch.js v1.0 ✅、index.html/receipt.html統合 ✅ |
| 残課題 | receipt.htmlのゴミ箱ボタンはみ出し修正、AI個別解析の動作確認 |
| git commits | v1.0〜v1.2まで計4回push済み |
| 重要な発見 | 8枚縦結合→GeminiJSON解析失敗の原因特定。1枚ずつ個別解析で解決 |

# 2. 📁 Files Changed

## 新規作成
| ファイル | 行数 | 内容 |
|---------|------|------|
| receipt-frame-modal.js | 475行 | 手動枠指定モーダルUI（デモv3.4から完全移植） |
| receipt-ai-patch.js | 68行 | runAiOcr()上書き：multiImageDataUrls→1枚ずつ個別解析 |

## 編集（既存ファイル変更）
| ファイル | 変更概要 |
|---------|---------|
| index.html | 226行目: receipt-frame-modal.js追加、218行目: receipt-ai-patch.js追加 |
| receipt.html | 48行目: 「✂️ 枠指定」ボタン追加（openFrameModal呼び出し） |

## 500行チェック
- ✅ receipt-frame-modal.js: 475行
- ✅ receipt-ai-patch.js: 68行
- ✅ receipt-ai.js: 309行（変更なし）
- ✅ receipt-core.js: 変更なし

# 3. 🔄 開発の流れ（時系列）

## Step1: CULOchanKAIKEIpro本体への統合方針決定
デモv3.4（手動4隅タップ方式）をそのままモーダル化して統合。
既存コードを一切壊さない独立実装方針。

**統合コマンド:**
```bash
# index.htmlにscriptタグ追加
sed -i '225a\    <script src="receipt-frame-modal.js"></script>' ~/CULOchanKAIKEIpro/index.html

# receipt.htmlにボタン追加（48行目）
# onclick: openFrameModal(receiptImageData, function(imgs){...})
```

## Step2: receipt-frame-modal.js v1.0 完成→push

**主要機能:**
- モーダル全画面表示
- 4隅タップ方式（左上→右上→右下→左下）
- 8ハンドルドラッグで微調整
- 複数レシート対応
- スクロール/編集モード切替
- サムネイルリスト表示
- バウンディングボックスクロップ

## Step3: v1.1修正（ハンドル当たり判定縮小）

**問題:** 隣接する枠への誤反応
**修正:**
```javascript
// HANDLE: 22 → 11（半径縮小）
// 当たり判定: HANDLE * 1.6 → HANDLE * 2.5（絶対値は縮小）
// 描画サイズ: HANDLE → HANDLE * 1.5（見た目は維持）
```

**CSSボタン修正:**
```css
flex-wrap: nowrap;   /* 折り返し禁止 */
min-width: 0;        /* flex子要素最小幅リセット */
white-space: nowrap; /* テキスト折り返し禁止 */
```

## Step4: AI解析「JSON解析に失敗しました」問題

**原因の特定:**
```
multiImageDataUrls（8枚） → mergeImages()で縦結合
→ 巨大1枚画像（推定10MB超）
→ GeminiのresponseSchema付きJSON解析が失敗
```

**解決: receipt-ai-patch.js v1.0 新規作成**
```javascript
// multiImageDataUrlsがある時は1枚ずつ個別解析
async function _runAiOcrMulti(images, apiKey) {
  for (var i = 0; i < total; i++) {
    showAiLoading('AI解析中... (' + (i+1) + '/' + total + '枚)');
    var result = await analyzeReceiptWithGemini(images[i], apiKey);
    // 結果を allReceipts に統合
  }
  applyAiResult({ receipts: allReceipts });
}
```

**index.html 218行目（receipt-ai.jsの次）に追加:**
```html
<script src="receipt-ai-patch.js"></script> <!-- v1.0追加: 枠指定個別解析 -->
```

## Step5: v1.2修正（点打ち中ハンドル無効化）

**問題:** 2枚目以降の枠を付けようとすると、既存ハンドルが反応して2度手間

**修正（_onStart関数）:**
```javascript
// v1.2: 点打ち中（_pts.length>0）はハンドル・枠選択を完全無効化
if (_pts.length === 0) {
  // ハンドル検索・枠選択ここだけ有効
}
// _pts.length > 0 の時は新しい点のみ追加
```

**ボタンgrid化（ゴミ箱はみ出し対策）:**
```css
/* flex → grid に変更 */
#fmActions { display: grid; grid-template-columns: 1fr 1fr 1fr; }
```

**注意:** これはモーダル内のボタン修正。
receipt.htmlの「✂️ 枠指定」行のゴミ箱はみ出しは**未修正**。

# 4. 🐛 Bugs Found & Fixed

| バグ | 原因 | 対処 | 状態 |
|------|------|------|------|
| AI解析「JSON解析に失敗」 | 8枚縦結合で巨大画像→Gemini失敗 | receipt-ai-patch.js v1.0で個別解析 | ✅修正済み（動作確認待ち） |
| ハンドル誤反応 | 点打ち中も既存ハンドルが有効だった | v1.2で_pts.length>0時は無効化 | ✅修正済み（動作確認待ち） |
| ボタンはみ出し（モーダル内） | flex折り返し | v1.1でCSS修正、v1.2でgrid化 | ✅修正済み |
| ゴミ箱はみ出し（receipt.html） | image-btnエリアのボタン行 | **未修正** | 🔧次セッション |

# 5. 🔮 Next Steps

## 最優先（次のセッション最初にやること）
1. **receipt.htmlのゴミ箱はみ出し修正**
   ```bash
   grep -n "🗑\|ゴミ\|trash\|gallery" ~/CULOchanKAIKEIpro/receipt.html
   ```
   → ボタン行のCSS確認→修正

2. **AI個別解析の動作確認**
   - 枠指定→確定→「AIで読み取る」
   - 「AI解析中... (1/8枚)」の進捗表示確認
   - 解析結果が入力フォームに正しく反映されるか確認

## その後（優先度順）
- ①合計欄横線バグ
- ②Excel出力マス目付き書式
- ③印鑑レイヤー
- ④A4縦テンプレ調整
- ⑤マスター候補ドロップダウンバグ

# 6. 📊 バージョン履歴（receipt-frame-modal.js）

| バージョン | 変更内容 |
|-----------|---------|
| v1.0 | デモv3.4完全移植、モーダル実装、CULOchan統合 |
| v1.1 | ハンドル当たり判定縮小（22→11）、ボタンflex修正 |
| v1.2 | 点打ち中ハンドル無効化、ボタンgrid化 |

# 7. 🧠 技術メモ

## なぜ個別解析にしたか
- 8枚縦結合 → 推定10MB超の巨大画像
- GeminiのresponseSchemaはレスポンスサイズに上限あり
- 1枚ずつなら確実にJSONが返ってくる
- デメリット: APIコール数が増える（8枚→8回）→ 無料枠内で問題なし

## _ptsの状態管理
```
_pts = []          → 点なし（ハンドルドラッグ有効）
_pts = [p1]        → 1点目（ハンドル無効）
_pts = [p1,p2,p3]  → 3点目（ハンドル無効）
4点で確定 → _receiptsに追加 → _pts = []に戻る
```

## ファイル間の繋がり
```
receipt.html 「✂️ 枠指定」ボタン
  ↓ openFrameModal(receiptImageData, callback)
receipt-frame-modal.js
  ↓ callback(croppedImages) → multiImageDataUrls = imgs
receipt-ai-patch.js の runAiOcr()
  ↓ 1枚ずつ analyzeReceiptWithGemini()
receipt-ai.js の analyzeReceiptWithGemini()
  ↓ 全結果統合
receipt-ai.js の applyAiResult()
```

## cpコマンド後の確認（重要！）
```bash
# ファイルサイズが変わったか確認
ls -la ~/CULOchanKAIKEIpro/receipt-frame-modal.js
ls -la ~/storage/shared/Download/receipt-frame-modal.js
```
→ バイト数が異なれば正しくコピーできてる

---
*作成: クロちゃん / 2026-03-05 Session10*
