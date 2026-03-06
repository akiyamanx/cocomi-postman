---
title: "🔧 開発カプセル_DIFF_DEV_culo-chan_2026-03-06_11"
capsule_id: "CAP-DIFF-DEV-CULO-20260306-11"
project_name: "CULOchan会計Pro / SAM2企画検証"
capsule_type: "diff_dev"
related_master: "M_CURRENT_思い出カプセル_MASTER_2026-03-06.md"
related_general: "思い出カプセル_DIFF_総合_2026-03-06_11.md"
mission_id: "M-CULO-SAM2-11"
phase: "SAM2レシート自動切り抜き 企画検証（Step1: デモ動作確認）"
date: "2026-03-06"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（HTMLダウンロード＋Galaxy S22 Ultra実機テスト）"
tester: "アキヤ（複数レシート写真で検証）"
---

# 1. 🎯 Mission Result

| 項目 | 内容 |
|------|------|
| ミッション | M-CULO-SAM2-11: SAM2-tiny ONNXのブラウザ動作検証＋レシート切り抜きデモ作成 |
| 結果 | ✅ **SAM2-tinyがGalaxy S22 Ultraで完全動作！レシート1枚ずつ切り抜き成功！** |
| 完了項目 | デモHTML作成✅、モデル読込✅、エンコーダー推論✅、デコーダー推論✅、マスク表示✅、切り抜き✅ |
| 追加検証 | SAM2-base_plus(340MB)は読込失敗 → tiny一択確定 |
| 重要な発見 | デコーダー推論300msでタップ即反応、折り目レシートも統合検出 |
| 作成ファイル | sam2-receipt-demo.html、sam2-receipt-demo-baseplus.html、UIモック2件 |

# 2. 📁 Files Changed

## 新規作成（claude.aiアーティファクト＋HTMLデモ）
| ファイル | 内容 |
|---------|------|
| sam2-receipt-demo.html | SAM2-tiny レシート切り抜きデモ（メイン、動作確認済み） |
| sam2-receipt-demo-baseplus.html | SAM2-base_plus版（読込失敗確認済み） |
| culochankaikei-category-mock.jsx | CULOchanカテゴリカードUIモック（アーティファクト） |
| sam-segmentation-demo.jsx | セグメンテーション説明＋SAMタップUIデモ（アーティファクト） |

## CULOchanKAIKEIpro本体への変更
なし（Session11はデモ検証のみ）

# 3. 🔄 開発の流れ（時系列）

## Step1: claude.aiのアーティファクト機能を学習
- アキヤが「アーティファクトって何？」「Codeって何？」から会話スタート
- アーティファクト = チャット内でReact/HTML/SVGをプレビューできる機能
- Claude Code（Termux）とclaude.ai（ここ）の違いを整理
- 「パーツ単位の試作→気に入ったらTermux側で本実装」のワークフロー確立

## Step2: CULOchanカテゴリカードUIモック作成
- React アーティファクトで10カテゴリのカード表示
- タップで展開→平均単価＋「レシート一覧→」ボタン
- 上部にサマリーバー（今月合計＋件数）
- アキヤ「え？今作ってくれたこれ自体メチャクチャ良いじゃん😂」

## Step3: SAM2企画の調査
- 企画カプセル（Session10で作成）の内容を確認
- SAM2-tinyのONNX変換済みモデルを調査
- **重要な発見**: エンコーダー134MB（企画カプセルの「数MB」は誤り）
- Labelboxが公開しているモデルURL（encoder.ort + decoder.onnx）を発見
- MobileSAM（9.66M）も候補だがSAM2-tinyで先に検証する方針

## Step4: セグメンテーション説明デモ作成
- 現場の絵（配管・壁・工具・作業員）でセグメンテーションを説明
- SAMレシート切り抜きのUIモック（デモデータでタップ→検出シミュレーション）
- 手動枠指定 vs SAM方式の比較表示

## Step5: SAM2-tiny実機デモHTML v1.0作成 → 初回テスト
**結果:**
- エンコーダー読込: 14.2秒 ✅
- デコーダー読込: 2.8秒 ✅
- エンコーダー推論: 27.9秒 ✅
- **デコーダー推論: エラー `invalid input 'orig_im_size'`** ❌

**原因:** SAM2のデコーダーはSAM1と違い`orig_im_size`入力が不要。Labelboxの実装を確認して判明。

## Step6: デモHTML v1.1 → orig_im_size削除＋正規化修正
**修正内容:**
- `orig_im_size`テンソルを削除
- 正規化をLabelbox準拠 `(pixel/255)*2-1` に変更
- `high_res_feats_0/1`をエンコーダー出力から直接渡す

**結果:**
- デコーダー推論: 334ms ✅
- スコア: 79.0% ✅
- **マスク表示: 見えない** ❌（オーバーレイ座標ズレ）
- **切り抜き: 「マスクが検出されませんでした」** ❌

## Step7: デモHTML v1.2 → マスク出力形状の動的取得
**修正内容:**
- デコーダー出力キー名を動的に検出
- マスク形状を`dims`から動的取得（256×256と判明）
- デバッグ情報をconsole.logに出力

**結果:**
- マスク: 256×256で出力されていた（1024×1024想定は誤り）
- マスク表示: **左上に紫の四角がズレて表示** ❌
- `scaledW is not defined`エラーで処理中断

## Step8: デモHTML v1.3 → scaledWエラー修正
**原因:** 古いdrawImage呼び出しが1行残っていた（`scaledW`変数は既に削除済み）
**修正:** 重複行を削除するだけ

**結果:**
- **マスクがレシートの上に正しく紫で表示！！** ✅
- タップするたびにマスクが追加される ✅
- 全レシートが紫で検出される ✅
- **ただし切り抜きが全体画像になる** ❌

## Step9: デモHTML v1.4 → 256×256マスクの座標変換修正＋1枚ずつ切り抜き
**修正内容:**
- マスク座標(256)→1024座標→元画像座標の3段変換
- `maskScale = maskW / INPUT_SIZE`でオフセット計算
- 切り抜きに`maskToImg = INPUT_SIZE / maskW`で逆変換
- パディング追加（mask座標で2px）
- スコア別のステータスメッセージ（70%以上→切り抜き促す、30〜70%→もう1回タップ）
- 切り抜き後のサムネイル拡大、元画像再描画

**結果:**
- **レシート1枚ずつの切り抜きに成功！！** ✅✅✅
- レシート1: 1906×844px
- レシート2: 1672×2484px
- レシート3: 1234×813px
- レシート4: 297×688px

## Step10: SAM2-base_plus(340MB)の動作検証
- デモHTMLのURLを変更するだけで試行
- **結果: モデル読込失敗（メモリ不足）** ❌
- Galaxy S22 Ultraのブラウザでは340MBは無理
- **結論: CULOchanへの組み込みはtiny一択**

# 4. 🐛 Bugs Found & Fixed

| バグ | 原因 | 対処 | 状態 |
|------|------|------|------|
| `invalid input 'orig_im_size'` | SAM2デコーダーにorig_im_sizeは不要（SAM1との違い） | orig_im_sizeテンソル削除 | ✅修正済み |
| マスクが見えない | 1024×1024想定だが実際は256×256出力 | dims動的取得に変更 | ✅修正済み |
| `scaledW is not defined` | 古いdrawImage呼び出しが残っていた | 重複行削除 | ✅修正済み |
| マスクが左上にズレる | 256→1024のスケール変換漏れ | maskScale計算追加 | ✅修正済み |
| 切り抜きが全体画像になる | タップ重ねでマスク全体に広がる | 1枚ずつ切り抜き→リセットのフローに変更 | ✅修正済み |
| base_plus読込失敗 | 340MBはGalaxy S22のブラウザメモリ上限超過 | tiny一択の判断確定 | ✅想定内 |

# 5. 🔮 Next Steps

## 最優先（次のセッション）
1. **receipt.htmlのゴミ箱はみ出し修正**（Session10からの持ち越し）
2. **AI個別解析の動作確認**（Session10からの持ち越し）
3. **SAM2統合の設計**: receipt-sam.js の設計・実装開始

## SAM2統合のロードマップ
```
Step1: receipt-sam.js 新規作成
  - モデル読込（スプラッシュ裏）
  - タップ→デコーダー推論→マスク表示
  - 切り抜き→multiImageDataUrlsに格納
  - フォールバック（SAM未ロード時→手動枠指定）

Step2: index.html / receipt.html 統合
  - scriptタグ追加
  - 「SAMモード / 手動モード」切替

Step3: スプラッシュ裏読み込み実装
  - エンコーダー(134MB)の非同期ロード
  - Service Workerキャッシュ
  - ロード状態表示

Step4: 実運用テスト
  - 複数レシートの切り抜き精度
  - Gemini AI解析との連携確認
```

## その後の優先度
- ①合計欄横線バグ ②Excel出力 ③印鑑レイヤー ④A4縦テンプレ ⑤ドロップダウンバグ

# 6. 🧠 技術メモ

## SAM2アーキテクチャ（ブラウザ実行版）
```
[エンコーダー] sam2_hiera_tiny.encoder.ort (134MB)
  入力: image [1, 3, 1024, 1024] float32
  出力: image_embed, high_res_feats_0, high_res_feats_1
  推論時間: 21〜28秒（Galaxy S22, WASM）

[デコーダー] sam2_hiera_tiny.decoder.onnx (20.6MB)
  入力:
    - image_embed: エンコーダー出力
    - high_res_feats_0: エンコーダー出力 [1, 32, 256, 256]
    - high_res_feats_1: エンコーダー出力 [1, 64, 128, 128]
    - point_coords: タップ座標 [1, N, 2] float32（1024座標系）
    - point_labels: ラベル [1, N] float32（1=前景, 0=背景）
    - mask_input: [1, 1, 256, 256] float32（初回はゼロ）
    - has_mask_input: [1] float32（0）
  出力:
    - masks: [1, 3, 256, 256]（3つのマスク候補）
    - iou_predictions: [1, 3]（各マスクのスコア）
  推論時間: 213〜334ms
```

## SAM2 vs SAM1のONNX入力の違い（重要！）
- SAM1: `orig_im_size`が必要（出力マスクのリサイズ用）
- **SAM2: `orig_im_size`は不要！代わりに`high_res_feats_0/1`をエンコーダー出力から渡す**
- この違いで初回テスト時にエラーが出た

## 画像前処理
```javascript
// 1024×1024にリサイズ（アスペクト比維持、黒パディング）
const scale = Math.min(1024 / img.width, 1024 / img.height);
const offsetX = (1024 - img.width * scale) / 2;
const offsetY = (1024 - img.height * scale) / 2;

// 正規化: Labelbox準拠
pixel_normalized = (pixel / 255.0) * 2 - 1;
```

## マスク座標変換（256→元画像）
```
マスク座標(256) × 4 = 1024座標
1024座標 - offset = スケール画像座標
スケール画像座標 / scale = 元画像座標
```

## モデルURL
```
// SAM2-tiny（✅動作確認済み）
エンコーダー: https://storage.googleapis.com/lb-artifacts-testing-public/sam2/sam2_hiera_tiny.encoder.ort
デコーダー: https://storage.googleapis.com/lb-artifacts-testing-public/sam2/sam2_hiera_tiny.decoder.onnx

// SAM2-base_plus（❌Galaxy S22で読込失敗）
エンコーダー: https://huggingface.co/vietanhdev/segment-anything-2-onnx-models/resolve/main/sam2_hiera_base_plus.encoder.onnx
デコーダー: https://huggingface.co/vietanhdev/segment-anything-2-onnx-models/resolve/main/sam2_hiera_base_plus.decoder.onnx
```

## ONNX Runtime Web
```html
<script src="https://cdn.jsdelivr.net/npm/onnxruntime-web@1.20.1/dist/ort.min.js"></script>
```
- executionProviders: ['wasm']（最も互換性が高い）
- WebGPU対応は将来検討（Chrome v113+で利用可能）

---
*作成: クロちゃん / 2026-03-06 Session11*
