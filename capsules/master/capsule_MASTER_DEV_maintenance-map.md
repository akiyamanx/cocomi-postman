<!-- dest: capsules/master -->
---
title: "💊思い出カプセル_MASTER_DEV_maintenance-map-ap"
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
- **現バージョン:** v2.2.3（2026-02-24時点）

## 主な機能
- Google Maps APIで顧客をマーカー表示、ルート色分け
- 顧客情報CRUD（追加・編集・削除・ステータス管理）
- Excel/CSVインポート
- ルート別の訪問順管理（ドラッグ&ドロップ）
- **区間別 高速/下道選択 → Directions APIで距離計算** ←★v2.2.3で完成
- 精算書フォーム（ETC明細読込対応）→ PDF出力
- バックアップ/リストア（JSON）

# 2. 📁 ファイル構成と役割

| ファイル | 行数目安 | 役割 |
|---------|---------|------|
| index.html | - | メインHTML、全scriptタグ定義 |
| app.js | - | アプリ初期化、タブ切替（switchTab）、全体制御 |
| map-core.js | - | Google Maps表示、マーカー管理、focusMarker |
| data-storage.js | - | LocalStorage CRUD（顧客/ルート/区間/設定/精算書） |
| route-manager.js | 384行 | ルートパネル、凡例、PDF出力、距離計算起動 |
| **segment-dialog.js** | **129行** | **区間別 高速/下道選択ダイアログUI ★v2.2.3新規** |
| distance-calc.js | 127行 | Directions APIで区間距離計算 |
| expense-form.js | - | 精算書フォームUI、ETC読込 |
| doc-template.js | - | PDF出力HTML書式（exportPDF関数定義） |
| csv-handler.js | - | Excel/CSVインポート |
| customer-popup.js | - | 顧客詳細ポップアップ（ステータス変更、ルート割当、訪問順設定） |
| sw.js | v2.0.0 | Service Worker（PWAキャッシュ） |
| noto-font.js | - | 日本語フォント（PDF用） |

# 3. 🔄 距離計算フロー（v2.2.3）

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
「精算書に反映しますか？」→ OK → 精算書タブに切替 → 走行距離自動入力
```

# 4. 💾 データ構造

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

## settings（LocalStorage: mm_settings）
```json
{ "homeAddress": "袖ケ浦市神納1407-1", "apiKey": "..." }
```

# 5. 🔜 次回の開発予定

## 精算書への行先自動反映＋手動編集（優先度: 高）

**背景:** 📏距離計算→精算書反映の流れで、現在は「走行距離」だけが入る。行先は手入力。

**やりたいこと:**
1. **行先の自動反映**
   - PDF「行先（お客様名）」欄にルート順の情報を自動入力
   - 上段: 地区名（住所から抽出。例: 港区虎ノ門→埼玉県所沢市）
   - 下段: 会社名/個人名（ルート順に列挙）
2. **手動編集機能**
   - 自動入力後にユーザーが修正可能にする
   - Claude Codeのミスがあった時に自分で直せるように

**必要なファイル:** expense-form.js、doc-template.js、index.htmlの精算書セクション

**参考:** PDF最終出力は「出張費精算請求書」形式。行先欄に上段: 地区ルート、下段: 会社名。

# 6. 🔧 開発環境メモ

- **デバイス:** Galaxyスマートフォン＋タブレット
- **開発ツール:** Termux + Claude Code
- **Termuxダウンロードパス:** `/storage/emulated/0/Download/`（`~/Downloads/`ではない！）
- **tmpdir設定:** 毎回 `export TMPDIR=~/tmp && mkdir -p ~/tmp`
- **git push不可時:** `/exit`してTermuxから手動push
- **ファイル名注意:** ダウンロード時にスペースが混入することがある → `find`で確認してからcpが安全
- **500行ルール:** 1ファイル500行以内。超過時はファイル分割で対応
- **プリンタ:** RICOH P C301SF (192.168.11.100)
- **CI:** cocomi-ci.yml全リポ共通。新リポは `./cocomi-repo-setup.sh ~/新リポ` で1行セットアップ

# 7. 📅 開発履歴

| 日付 | バージョン | 内容 |
|------|-----------|------|
| - | v2.0 | 分割ファイル構成対応、ルート管理、PDF出力、凡例 |
| - | v2.0.1 | v1.0互換インポート、10ルート対応 |
| - | v2.1 | 精算書機能統合、ETC明細読込 |
| - | v2.2 | 距離計算機能追加（Directions API）、訪問順管理 |
| - | v2.2.1 | 🔢ボタン削除（訪問順はポップアップから設定） |
| 2026-02-24 | v2.2.3 | **区間別 高速/下道選択UI**、segment-dialog.js新規作成 |
