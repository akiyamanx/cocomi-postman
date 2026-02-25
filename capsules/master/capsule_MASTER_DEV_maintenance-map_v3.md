<!-- dest: capsules/master -->
---
title: "💊思い出カプセル_MASTER_DEV_maintenance-map"
capsule_id: "CAP-MASTER-DEV-MAINTENANCE-MAP"
project_name: "maintenance-map-ap（メンテナンスマップ）"
capsule_type: "master_dev"
last_updated: "2026-02-25"
author: "アキヤ & クロちゃん（Claude/次女）"
---

# 1. 📋 プロジェクト概要

**メンテナンスマップ** — 水浄化設備メンテナンスの顧客管理・ルート管理・精算書作成を一体化したPWAアプリ。

- **GitHub:** https://github.com/akiyamanx/maintenance-map-ap
- **公開URL:** https://akiyamanx.github.io/maintenance-map-ap/
- **CI:** cocomi-ci.yml v1.1（LINE通知+GitHub Pages自動デプロイ）
- **現バージョン:** v2.3（2026-02-25時点）
- **タグ:** v2.3（GitHubのReleasesに保存済み）
- **ステータス:** ほぼ完成形。使いながら改善していくフェーズ。

## 主な機能
- Google Maps APIで顧客をマーカー表示、ルート色分け
- 顧客情報CRUD（追加・編集・削除・ステータス管理）
- Excel/CSVインポート（電話番号・担当者・営業所・型式・フィルター自動検出）
- ルート別の訪問順管理（ドラッグ&ドロップ）
- 区間別 高速/下道選択 → Directions APIで距離計算（v2.2.3）
- 精算書への行先自動反映（地区名→会社名、→区切り、手動編集可）（v2.2.4）
- 精算書フォーム（ETC明細読込対応）→ PDF出力
- マーカータップで顧客ポップアップ（📞電話発信ボタン付き）
- バックアップ/リストア（JSON）
- PWAインストール対応（ホーム画面から直接起動）
- **📅 月別ワークスペース切り替え（v2.3）** ← ★最新機能

# 2. 📁 ファイル構成と役割

| ファイル | 行数目安 | 役割 |
|---------|---------|------|
| index.html | 321行 | メインHTML、全scriptタグ定義、WSメニュー＆追加ダイアログ |
| **data-storage.js** | **476行** | **LocalStorage CRUD、ワークスペース管理（月別キー生成、マイグレーション）** |
| **v1-converter.js** | **67行** | **v1.0→v2.0バックアップデータ変換（data-storage.jsから分離）** |
| csv-handler.js | 278行 | Excel/CSVインポート、カラム自動検出（v2.2.4で判定順序修正） |
| map-core.js | - | Google Maps表示、マーカー管理、顧客ポップアップ（📞電話発信） |
| route-manager.js | 441行 | ルートパネル、凡例、PDF出力、距離計算起動、行先テキスト生成 |
| segment-dialog.js | 129行 | 区間別 高速/下道選択ダイアログUI |
| distance-calc.js | 127行 | Directions APIで区間距離計算 |
| **expense-form.js** | **431行** | **精算書フォームUI、ETC読込、setDestination()、resetInitFlag()** |
| expense-pdf.js | - | PDF出力HTML書式 |
| etc-reader.js | - | ETC明細CSVの読込・パース |
| **ui-actions.js** | **349行** | **UI操作、ワークスペース切替UI、reloadAllUI()** |
| route-order.js | - | 訪問順の並べ替えUI |
| **workspace-styles.css** | **162行** | **ワークスペースメニューのスタイル（v2.3新規）** |
| styles.css | - | メインスタイル |
| expense-styles.css | - | 精算書スタイル |
| route-order-styles.css | - | 並べ替えスタイル |
| sw.js | v2.0.0 | Service Worker（PWAキャッシュ） |
| noto-font.js | - | 日本語フォント（PDF用） |
| manifest.json | - | PWA設定（display:standalone） |
| icon-192.png / icon-512.png | - | PWAアイコン |

### ⚠️ 存在しないファイル（カプセル整理済み）
- ~~doc-template.js~~ → expense-pdf.jsに統合済み
- ~~customer-popup.js~~ → map-core.jsに内包（InfoWindow）

# 3. 📅 ワークスペース機能（v2.3）

## データ構造
```
共通キー（ワークスペースに依存しない）:
  mm_workspaces → [{ id: "2026-02", name: "2026年2月", createdAt: "..." }, ...]
  mm_workspace_current → "2026-02"
  mm_settings → { homeAddress, apiKey }
  mm_geocache → { address: { lat, lng }, ... }

月別キー（ワークスペースごとに分離）:
  mm_customers_2026-02 → 2月の顧客データ
  mm_customers_2026-03 → 3月の顧客データ
  mm_routes_2026-02 → 2月のルートデータ
  mm_segments_2026-02 → 2月の区間データ
  mm_expenses_2026-02 → 2月の精算書データ
```

## 切り替え処理フロー
```
📅ボタンタップ → showWorkspaceMenu()
  → ワークスペース一覧表示（件数付き）
  → 月を選択 → selectWorkspace(wsId)
    → DataStorage.switchWorkspace(wsId)  // mm_workspace_current更新
    → reloadAllUI()
      ├── MapCore.refreshAllMarkers()    // 地図マーカー再描画
      ├── RouteManager.updateRoutePanel() // ルートパネル再描画
      ├── ExpenseForm.resetInitFlag()    // 精算書再初期化フラグ
      └── updateWsButton()              // ボタンラベル更新
```

## マイグレーション（旧データ→ワークスペース形式）
- 初回起動時にmigrateIfNeeded()が実行
- 旧キー（mm_customers等）が存在すれば今月のワークスペースに移行
- 旧キーは移行後に削除
- 旧データがなければ今月の空ワークスペースを作成

# 4. 🔄 距離計算→精算書反映フロー（v2.2.4）

```
📏ボタン押下（ルートタブ、2件以上＋訪問順設定済み）
  → route-manager.js calcDistance()
  → SegmentDialog.show() → 区間ごとに高速/下道選択
  → DistanceCalc.calcRouteDistance() → Directions API呼び出し
  → 結果alert → 「精算書に反映しますか？」
  → buildDestinationText() → 行先テキスト生成
  → applyDistanceToExpense(totalKm, destText)
  → ExpenseForm.setDestination(destText) → 行先自動入力
  → ユーザーが手動編集可能 → PDF出力
```

# 5. 🔍 CSVインポートのカラム検出（v2.2.4）

```
detectColumns() 判定順序:
  1. 電話（★最優先）→ 2. 担当者 → 3. 備考 → 4. 会社名 → 5. 住所 → 6. 管理番号
  独立if文: 都道府県、営業所、型式、フィルター
```

# 6. 💾 データ構造

## customers（例: mm_customers_2026-02）
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

# 7. 🔍 CI チェック項目（cocomi-ci.yml v1.1）

| # | チェック項目 | 対象 | 説明 |
|---|------------|------|------|
| ③ | ShellCheck | .sh | シェルスクリプト文法チェック（SC1091,SC2034除外） |
| ④ | 500行チェック | 全拡張子 | 1ファイル500行超過で不合格 |
| ⑤ | 先頭コメント | .sh/.js/.css | sw.js除外。ファイルの役割説明があるか |
| ⑥ | バージョン番号 | .sh/.js/.css | sw.js除外。先頭10行以内にvX.Xパターン |
| ⑦ | console.log | .js | sw.js除外。console.error/warnは許可 ★v1.1追加 |
| ⑧ | TODO/FIXME | 全拡張子 | TODO:/FIXME:/HACK:/XXX:を検出 ★v1.1追加 |
| ⑨ | セキュリティ | 全拡張子+json/yml | config.json/.env漏洩、ghp_/sk-ant-/xoxb-検出 |

# 8. 🔜 今後の方針

- maintenance-map-apはほぼ完成形。使いながら改善していくフェーズ
- 新機能の要望が出たらv2.4以降で対応
- CI v1.1を他の6リポにも展開予定（console.log残存に注意）
- git tagは大きな完成ごとに付けていく（v2.4, v2.5...）

# 9. 🔧 開発環境メモ

- **デバイス:** Galaxyスマートフォン＋タブレット
- **開発ツール:** Termux + Claude Code
- **tmpdir設定:** 毎回 `export TMPDIR=~/tmp && mkdir -p ~/tmp`
- **git push不可時:** `/exit`してTermuxから手動push
- **500行ルール:** 1ファイル500行以内。超過時はファイル分割で対応
- **プリンタ:** RICOH P C301SF (192.168.11.100)
- **CI:** cocomi-ci.yml v1.1 全リポ共通。新リポは `./cocomi-repo-setup.sh ~/新リポ` で1行セットアップ
- **タグ付け:** `git tag -a vX.X -m "説明"` → `git push origin vX.X`
- **タグから復元:** `git checkout vX.X` で任意の完成時点に戻れる

# 10. 📅 開発履歴

| 日付 | バージョン | 内容 |
|------|-----------|------|
| - | v2.0 | 分割ファイル構成対応、ルート管理、PDF出力、凡例 |
| - | v2.0.1 | v1.0互換インポート、10ルート対応 |
| - | v2.1 | 精算書機能統合、ETC明細読込 |
| - | v2.2 | 距離計算機能追加（Directions API）、訪問順管理 |
| - | v2.2.1 | 🔢ボタン削除（訪問順はポップアップから設定） |
| 2026-02-24 | v2.2.3 | 区間別 高速/下道選択UI、segment-dialog.js新規作成 |
| 2026-02-24 | v2.2.4 | 精算書への行先自動反映＋電話番号インポートバグ修正 |
| 2026-02-24 | v2.2.4 | PWAアイコン追加、スマホインストール対応 |
| **2026-02-25** | **v2.3** | **月別ワークスペース切り替え機能** ← ★git tag v2.3で保存 |
| **2026-02-25** | - | **CI v1.1 console.log＋TODO/FIXMEチェック追加** |
