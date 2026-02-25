<!-- dest: capsules/master -->
---
title: "💊思い出カプセル_MASTER_DEV_maintenance-map"
capsule_id: "CAP-MASTER-DEV-MAINTENANCE-MAP"
project_name: "maintenance-map-ap（メンテナンスマップ）"
capsule_type: "master_dev"
last_updated: "2026-02-24"
author: "アキヤ & クロちゃん（Claude/次女）"
---

# 1. 📋 プロジェクト概要

**メンテナンスマップ** — 水浄化設備メンテナンスの顧客管理・ルート管理・精算書作成を一体化したPWAアプリ。

- **GitHub:** https://github.com/akiyamanx/maintenance-map-ap
- **公開URL:** https://akiyamanx.github.io/maintenance-map-ap/
- **CI:** cocomi-ci.yml（LINE通知+GitHub Pages自動デプロイ）
- **現バージョン:** v2.2.4（2026-02-24時点）

## 主な機能
- Google Maps APIで顧客をマーカー表示、ルート色分け
- 顧客情報CRUD（追加・編集・削除・ステータス管理）
- Excel/CSVインポート（電話番号・担当者・営業所・型式・フィルター自動検出）
- ルート別の訪問順管理（ドラッグ&ドロップ）
- **区間別 高速/下道選択 → Directions APIで距離計算** ←★v2.2.3で完成
- **精算書への行先自動反映（地区名→会社名、→区切り、手動編集可）** ←★v2.2.4で完成
- 精算書フォーム（ETC明細読込対応）→ PDF出力
- マーカータップで顧客ポップアップ（📞電話発信ボタン付き）
- バックアップ/リストア（JSON）

# 2. 📁 ファイル構成と役割

| ファイル | 行数目安 | 役割 |
|---------|---------|------|
| index.html | - | メインHTML、全scriptタグ定義 |
| app.js | - | アプリ初期化、タブ切替（switchTab）、全体制御 |
| map-core.js | - | Google Maps表示、マーカー管理、focusMarker、**顧客ポップアップ（InfoWindow、📞電話発信ボタン）** |
| data-storage.js | - | LocalStorage CRUD（顧客/ルート/区間/設定/精算書） |
| **csv-handler.js** | **278行** | **Excel/CSVインポート、カラム自動検出（v2.2.4で判定順序修正）** |
| route-manager.js | 441行 | ルートパネル、凡例、PDF出力、距離計算起動、**行先テキスト生成** |
| segment-dialog.js | 129行 | 区間別 高速/下道選択ダイアログUI ★v2.2.3新規 |
| distance-calc.js | 127行 | Directions APIで区間距離計算 |
| **expense-form.js** | **424行** | **精算書フォームUI、ETC読込、setDestination()で行先自動入力** |
| expense-pdf.js | - | PDF出力HTML書式（generate関数定義）※旧名doc-template.js |
| etc-reader.js | - | ETC明細CSVの読込・パース |
| ui-actions.js | - | UI操作（モーダル制御、設定、バックアップ等） |
| route-order.js | - | 訪問順の並べ替えUI |
| sw.js | v2.0.0 | Service Worker（PWAキャッシュ） |
| noto-font.js | - | 日本語フォント（PDF用） |

### ⚠️ 存在しないファイル（カプセル整理済み）
- ~~doc-template.js~~ → expense-pdf.jsに統合済み
- ~~customer-popup.js~~ → map-core.jsに内包（InfoWindow）

# 3. 🔄 距離計算→精算書反映フロー（v2.2.4）

```
📏ボタン押下（ルートタブ、2件以上＋訪問順設定済みで表示）
  ↓
route-manager.js calcDistance()
  ├── ポイントリスト構築
  │   └── 🏠自宅(出発) → 顧客A → 顧客B → ... → 🏠自宅(帰着)
  ├── DataStorage.getSegments() で前回の高速/下道設定を取得
  ↓
SegmentDialog.show(points, savedSegments) ← segment-dialog.js
  ├── 各区間をカード形式で表示
  ├── タップで 🚗下道 ⇔ 🛣️高速 トグル切替
  ├── 前回の設定が復元されてる
  └── 「📏計算する」→ { "fromId_toId": "general"|"highway", ... } を返す
  ↓
DataStorage.saveSegments() で選択を保存（次回復元用）
  ↓
DistanceCalc.calcRouteDistance(routeId, segmentChoices) ← distance-calc.js
  ├── 各区間で Directions API 呼び出し（500ms間隔）
  ├── avoidHighways = (type === 'general') で高速回避を制御
  └── 区間ごとの距離・所要時間を集計
  ↓
結果alert表示（総距離・高速/下道内訳・区間詳細）
  ↓
「精算書に反映しますか？」→ OK
  ↓
★v2.2.4追加: buildDestinationText(ordered) で行先テキスト生成
  ├── extractArea(address) で住所→都道府県+市区町村を抽出
  ├── 上段: 地区名（重複除外、→区切り）
  └── 下段: 会社名（ルート順、→区切り）
  ↓
applyDistanceToExpense(totalKm, destText)
  ├── 精算書タブに切替 → ExpenseForm.init()
  ├── ExpenseForm.setDestination(destText) → 行先テキストエリアに自動入力
  └── 走行距離を1行目に自動入力 → ガソリン代自動計算
  ↓
ユーザーが行先を手動編集可能（textareaなので自由に修正OK）
  ↓
PDF出力 → expense-pdf.jsが行先をそのまま表示
```

# 4. 🔍 CSVインポートのカラム検出（v2.2.4）

```
csv-handler.js detectColumns()
  else ifチェーン判定順序（v2.2.4で修正）:
  
  1. 電話     ← 「電話」「TEL」「phone」を含む（★最優先）
  2. 担当者   ← 「担当」「contact」「受付」を含む
  3. 備考     ← 「備考」「情報」「note」「memo」を含む
  4. 会社名   ← 「会社」「設置先」「名称」「company」を含む
  5. 住所     ← 「住所」「address」「所在地」を含む
  6. 管理番号  ← 「管理」「管理NO」「U管理」を含む
  
  ※独立if文（上記と併用）:
  - 都道府県  ← 「都道府県」「prefecture」
  - 営業所    ← 「営業所」「支店」「branch」
  - 型式      ← 「型式」（「交換」を含まない）
  - フィルター ← 「フィルター」「交換フィルター」「filter」

  ⚠️ 重要: 「設置先TEL」「受付担当者」「設置先情報」のように
  複合的なヘッダー名は、電話・担当者・備考を先にチェックしないと
  「設置先」条件で会社名に誤判定される（v2.2.4で修正済み）
```

# 5. 💾 データ構造

## segments（LocalStorage: mm_segments）
```json
{
  "route_1": {
    "home_start_c_xxx": "highway",
    "c_xxx_c_yyy": "general",
    "c_yyy_home_end": "general"
  }
}
```

## routes（LocalStorage: mm_routes）
```json
{ "id": "route_1", "name": "ルート1", "color": "#4285f4", "order": ["c_xxx", "c_yyy", "c_zzz"] }
```

## customers（LocalStorage: mm_customers）
```json
{
  "id": "c_xxx", "company": "キャノンメディカルファイナンス㈱",
  "address": "東京都中央区日本橋人形町2-14-10",
  "phone": "03-6371-4591", "contact": "北村様",
  "managementNo": "MF 111180", "branch": "中央", "equipType": "直",
  "filter": "セディ+プレC+M+ポストC",
  "routeId": "route_1", "status": "pending", "unitCount": 1
}
```

## settings（LocalStorage: mm_settings）
```json
{ "homeAddress": "袖ケ浦市神納1407-1", "apiKey": "..." }
```

# 6. 🔜 次回の開発候補

- 特に決まった予定なし。アキヤの要望次第。
- 過去の候補: 写真管理+簡易黒板（現場Pro設備くん向け）
- 精算書まわりの改善余地: PDF行先欄のレイアウト微調整、ETC明細との連携強化

# 7. 🔧 開発環境メモ

- **デバイス:** Galaxyスマートフォン＋タブレット
- **開発ツール:** Termux + Claude Code
- **Termuxダウンロードパス:** `/storage/emulated/0/Download/`（`~/Downloads/`ではない！）
- **tmpdir設定:** 毎回 `export TMPDIR=~/tmp && mkdir -p ~/tmp`
- **git push不可時:** `/exit`してTermuxから手動push
- **ファイル名注意:** ダウンロード時にスペースが混入することがある → `find`で確認してからcpが安全
- **500行ルール:** 1ファイル500行以内。超過時はファイル分割で対応
- **プリンタ:** RICOH P C301SF (192.168.11.100)
- **CI:** cocomi-ci.yml全リポ共通。新リポは `./cocomi-repo-setup.sh ~/新リポ` で1行セットアップ
- **ファイルデプロイ手順:**
  1. `find /storage/emulated/0/Download/ -name "*ファイル名*"` で確認
  2. `cp /storage/emulated/0/Download/ファイル名.js ~/maintenance-map-ap/ファイル名.js`
  3. `head -5 ~/maintenance-map-ap/ファイル名.js` でバージョン確認
  4. `git add → git commit → git push`

# 8. 📅 開発履歴

| 日付 | バージョン | 内容 |
|------|-----------|------|
| - | v2.0 | 分割ファイル構成対応、ルート管理、PDF出力、凡例 |
| - | v2.0.1 | v1.0互換インポート、10ルート対応 |
| - | v2.1 | 精算書機能統合、ETC明細読込 |
| - | v2.2 | 距離計算機能追加（Directions API）、訪問順管理 |
| - | v2.2.1 | 🔢ボタン削除（訪問順はポップアップから設定） |
| 2026-02-24 | v2.2.3 | 区間別 高速/下道選択UI、segment-dialog.js新規作成 |
| 2026-02-24 | **v2.2.4** | **精算書への行先自動反映（地区名→会社名、→区切り）** |
| 2026-02-24 | **v2.2.4** | **csv-handler.js detectColumns判定順序修正（電話番号インポートバグ修正）** |
