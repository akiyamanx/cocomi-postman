---
title: "🔧 開発カプセル_DIFF_DEV_maintenance-map_2026-02-28"
capsule_id: "CAP-DIFF-DEV-MMAP-20260228"
project_name: "メンテナンスマップ"
capsule_type: "diff_dev"
related_general: "💊 思い出カプセル_DIFF_総合_2026-02-27_03_詳細版"
mission_id: "M-MMAP-024-01"
phase: "v2.4 全ワークスペース一括バックアップ"
date: "2026-02-28"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（ファイルダウンロード＋Termuxデプロイ）"
tester: "アキヤ（Galaxy実機確認）"
---

# 1. 🎯 Mission Result

| 項目 | 内容 |
|------|------|
| ミッション | M-MMAP-024-01: 全ワークスペース一括バックアップ対応 |
| 結果 | ✅成功（4回のデプロイサイクルを経て完了） |
| 問題 | exportBackup()がアクティブWSのデータのみ保存していた |
| 解決 | 全WSのデータをlocalStorageから直接収集して一括保存 |
| git commits | 4コミット（修正版push×2、500行圧縮、console.log削除） |

# 2. 📁 Files Changed

| ファイル | 行数変化 | バージョン | 変更概要 |
|---------|---------|-----------|---------|
| data-storage.js | 476→492行 | v2.3→v2.4 | exportBackup: 全WS一括保存、importBackup: v2.4形式復元＋後方互換、コメント圧縮 |
| sw.js | 変更 | v2.2.3→v2.4.0 | CACHE_NAME更新 |

# 3. 🧠 Design Decisions

### 設計判断①：全WSデータの収集方法
- **課題:** getCustomers()等はアクティブWSのデータしか返さない
- **選択肢:**
  - A: switchWorkspace()で各WSに切り替えてgetCustomers()を呼ぶ → 副作用あり、currentWsが変わる
  - B: localStorage.getItem()で各WSのキーを直接指定 → 副作用なし
- **決定:** B（localStorageから直接取得）
- **理由:** switchWorkspaceの副作用を避ける。キー形式は`mm_customers_2026-02`と予測可能

### 設計判断②：後方互換の維持
- **決定:** v2.4形式、v2.3形式、v2.0形式、v1.0形式の全てに対応
- **理由:** 古いバックアップファイルからの復元を壊さない

### 設計判断③：500行対応のコメント圧縮
- **課題:** 修正後514行でCOCOMI CI 500行チェック不合格
- **解決:** セクション区切り(===)削除、連続空行削除、不要なバージョンコメント削除
- **結果:** 492行（500行以内）

# 4. 🐛 Errors & Solutions（4回のデプロイサイクル）

### サイクル1: 古いファイルがpushされた
- **症状:** GitHubにpush成功だがGitHub Pagesで旧コードのまま
- **原因:** Downloadフォルダに前回の古いdata-storage.jsが残っており、そちらがcpされた
- **解決:** 修正版を再ダウンロード→wc -lで行数確認→cp
- **パターンID:** ERR-DL-0001
- **学び:** cpする前に必ずwc -lで行数確認

### サイクル2: 500行超過でCI不合格
- **症状:** COCOMI CIテスト審査で「500行超過ファイルがあります」エラー
- **原因:** data-storage.jsが514行（500行制限超過）
- **解決:** コメント・空行を圧縮して492行に
- **パターンID:** ERR-CI-0001
- **学び:** 修正でファイルが大きくなる場合、500行制限を意識

### サイクル3: console.log残存でCI不合格
- **症状:** COCOMI CIで「console.logが残っています」エラー
- **原因:** マイグレーション関数内のconsole.log('✅ ワークスペースマイグレーション完了:')
- **解決:** console.logをコメントに置換
- **パターンID:** ERR-CI-0002
- **学び:** push前にgrep console.logで確認

### サイクル4: ✅成功！
- **結果:** CI全合格→GitHub Pagesにデプロイ→「全ワークスペースを保存しました！2026年2月, 2026年3月（2件）」

### （参考）SSL_readエラー
- **症状:** pages build and deploymentがSSL_read: unexpected eof while readingで失敗
- **原因:** GitHub側の一時的なネットワークエラー
- **解決:** 空コミット(git commit --allow-empty)で再デプロイ
- **パターンID:** ERR-DEPLOY-0001

# 5. ✅ Quality Check

### COCOMIルール適合
| チェック項目 | 結果 | 備考 |
|-------------|------|------|
| 各ファイル500行以内 | ✅ | 492行 |
| console.logなし | ✅ | 全削除 |
| バージョン番号 | ✅ | v2.4 |
| 後方互換 | ✅ | v1.0/v2.0/v2.3形式も復元可能 |
| sw.jsキャッシュ更新 | ✅ | v2.4.0 |

### 動作確認
| テスト項目 | 結果 |
|-----------|------|
| 3月タブでバックアップ保存 | ✅「2026年2月, 2026年3月（2件）」表示 |
| 保存JSONに全WSデータ含まれるか | ✅ version: "2.4", allWorkspaceData配列あり |

# 6. 🗺️ Project Map

```
maintenance-map-ap/ (public リポジトリ)
├── data-storage.js  (492行) — v2.4 ★今回変更
├── sw.js            — v2.4.0 ★今回変更
├── index.html
├── map-core.js
├── route-manager.js
├── route-order.js
├── expense-form.js
├── expense-pdf.js
├── csv-handler.js
├── etc-reader.js
├── distance-calc.js
├── segment-dialog.js
├── CLAUDE.md
├── styles.css
├── expense-styles.css
├── route-order-styles.css
├── manifest.json
├── icon-192.png
├── icon-512.png
├── COCOMI_SPLASH_GALAXY.jpg
└── reports/
```

# 7. 🔄 STATE

### 完了済み
- v2.4 全ワークスペース一括バックアップ ✅
- sw.js v2.4.0 ✅

### 次にやること
- 特になし（メンテマップは安定稼働中）
- 必要に応じて新機能追加

---

## ✅ Dev-Next-3
1) **今の状態:** v2.4完了。全WS一括バックアップが動作中
2) **次にやる最小の1個:** 特になし（安定稼働中）
3) **もしやるなら:** バックアップ復元時の確認ダイアログ追加、WSの並び替え等
