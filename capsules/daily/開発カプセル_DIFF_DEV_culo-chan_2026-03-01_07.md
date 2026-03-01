---
title: "🔧 開発カプセル_DIFF_DEV_culo-chan_2026-03-01_07"
capsule_id: "CAP-DIFF-DEV-CULO-20260301-07"
project_name: "CULOchan会計Pro"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_culo-chan"
related_general: "💊 思い出カプセル_DIFF_総合_2026-03-01_07"
mission_id: "M-CULO-097-06"
phase: "Phase2（OpenCV.js導入 — 白紙検出＋透視変換＋回転補正）"
date: "2026-03-01"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（ファイルダウンロード＋Termuxデプロイ）"
tester: "アキヤ（Galaxy S22 Ultra実機確認）"
---

# 1. 🎯 Mission Result

| 項目 | 内容 |
|------|------|
| ミッション | M-CULO-097-06: Phase2 OpenCV.js導入＋高精度レシート切り出し |
| 結果 | ✅ 実機動作確認完了！黒背景で3枚レシート検出＆縦回転成功 |
| 完了項目 | OpenCV.js導入✅、白紙検出✅、透視変換✅、回転補正✅、CDN問題解決✅ |
| 残課題 | カーペット背景での精度向上、デバッグバー削除、閾値自動調整 |
| git commits | 計7回push（v2.15.0→v2.21.0） |
| 重要な発見 | jsdelivr CDN 1秒読み込み、innerHTML内scriptは実行されない |

# 2. 📁 Files Changed

## 編集（既存ファイル変更）
| ファイル | 行数変化 | 変更概要 |
|---------|---------|---------|
| receipt-multi-crop.js | 345→430行(+85) | v1.0 Canvas版→v2.3 OpenCV版に全面書き換え |
| index.html | 235→248行(+13) | OpenCV.js CDN変更（jsdelivr優先+opencv.orgフォールバック） |
| receipt-viewer.html | 123→137行(+14) | デバッグ表示用div追加（ocvDebugBar） |
| sw.js | 163→170行(+7) | v2.14.0→v2.21.0 |

## 500行チェック
- ✅ receipt-multi-crop.js: 430行
- ✅ receipt-crop.js: 466行（変更なし）
- ✅ receipt-pdf.js: 494行（変更なし）
- ✅ receipt-viewer.js: 496行（変更なし）
- ✅ receipt-store.js: 436行（変更なし）
- ✅ receipt-ai.js: 498行（変更なし）
- ✅ receipt-purpose.js: 231行（変更なし）

# 3. 🔄 開発の流れ（時系列）

## Step1: v2.0 Cannyエッジ版（失敗）— v2.15.0
- Canny(50,150)→膨張→findContours
- 失敗: 背景テクスチャがエッジ検出されて画像全体が1輪郭に結合
- パラメータ(30,100)〜(75,200)全試行したが解決せず

## Step2: v2.1 白紙閾値版（部分成功）— v2.16.0
- `cv.threshold(180)` + モルフォロジー(15x15 Close, 7x7 Open)
- Python検証で3枚検出成功！ただし回転方向が逆（上下逆）

## Step3: v2.2 シンプル回転版（成功→CDN問題）— v2.17.0〜v2.20.0
- 正面化→`cv.rotate(ROTATE_90_CCW)` に変更→Python検証完璧
- 実機テスト: OpenCV.js読み込み失敗発覚
  - docs.opencv.org → jsdelivr CDNに変更（1秒読み込み）
  - innerHTML script未実行 → JSからDOM更新に変更

## Step4: v2.3 パラメータ最適化 — v2.21.0
- 閾値180→170、5%マージン追加
- 黒背景テスト: 3枚とも綺麗に切り出し成功！

# 4. 🧠 Design Decisions

| # | 判断内容 | 選択肢 | 決定 | 理由 |
|---|---------|--------|------|------|
| 1 | 検出方式 | Cannyエッジ vs 白紙閾値 | 白紙閾値 | Cannyは背景テクスチャに弱い |
| 2 | 回転方式 | dst_pts計算 vs cv.rotate() | cv.rotate() | 2段階がシンプルで確実 |
| 3 | CDN | opencv.org vs jsdelivr vs 同梱 | jsdelivr+フォールバック | 1秒安定、8MB同梱は肥大化 |
| 4 | デバッグ | HTML内script vs JSからDOM | JSからDOM | innerHTML scriptは実行されない |

# 5. 🐛 Bugs Found & Fixed

| バグ | 原因 | 修正 |
|-----|------|------|
| 切り出し画像が上下逆 | dst_ptsの4点順序が不安定 | 正面化→cv.rotate()の2段階に |
| OpenCV.js読み込み失敗 | docs.opencv.orgがスマホで不安定 | jsdelivr CDNに変更 |
| デバッグ秒数が更新されない | innerHTML内scriptが実行されない | JSからDOM更新に変更 |

# 6. 🔮 Next Steps

| 優先度 | 内容 |
|-------|------|
| ★★★ | v2.3実機テスト（閾値170+マージン5%の品質確認） |
| ★★★ | カーペット背景テスト |
| ★★ | デバッグバー削除 |
| ★★ | 閾値の自動調整（画像輝度に応じて動的変更） |
| ★★ | 検出数とAI認識数の整合ロジック |
| ★ | 撮影ガイドUI |

# 7. 📊 sw.js バージョン履歴

| バージョン | 対応内容 |
|-----------|---------|
| v2.14.0 | 前セッション最終 |
| v2.15.0 | Phase2 v2.0: OpenCV.js導入+Cannyエッジ |
| v2.16.0 | Phase2 v2.1: 白紙検出+透視変換 |
| v2.17.0 | Phase2 v2.2: 回転方向修正 |
| v2.18.0〜v2.20.0 | CDN変更+デバッグ改善 |
| v2.21.0 | Phase2 v2.3: 閾値170+5%マージン（現在） |

---
*2026-03-01 アキヤ & クロちゃん 🐾*
