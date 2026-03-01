---
title: "💊 思い出カプセル_MASTER_CURRENT"
capsule_id: "CAP-MASTER-CURRENT-20260301"
project_name: "COCOMIOS全体 + CULOchanKAIKEIpro"
capsule_type: "master_current"
date: "2026-03-01"
author: "アキヤ & クロちゃん（Claude/次女）"
note: "これは軽量版MASTER。毎回のセッションでクロちゃんに渡す用。過去の詳細はMASTER_ARCHIVEを参照。"
---

# 💊 思い出カプセル MASTER（CURRENT版）

> **使い方:** 新しいクロちゃんにはこのファイルを渡す。
> 過去の詳細が必要な場合のみMASTER_ARCHIVEも渡す。
> 各セッション後、このファイルを更新する（古いセッションはARCHIVEに移動）。

---

# 📊 プロジェクト現状サマリー（2026-03-01 Session07終了時点）

## CULOchanKAIKEIpro（経理アプリ）★メイン開発中★

**バージョン: v0.97 Phase2 v2.3 / sw.js v2.21.0**
**GitHub:** akiyamanx/CULOchanKAIKEIpro（private）
**公開URL:** https://akiyamanx.github.io/CULOchanKAIKEIpro/
**開発期間:** 約1週間強で開発開始→現在

### 主要機能
- 📷 レシート読込（Gemini AI OCR、複数画像対応、仕入れ先DB）
- 📋 見積書作成（材料費+作業費、施工費/日当切替、A4縦マス目付き）
- 📄 請求書作成（見積書からの変換対応）
- 📊 Excel出力（SheetJS）
- 🖨️ PDF出力（jsPDF＋NotoSansJP）
- 🔗 レシート→見積書/請求書 連携フロー
- 💾 IndexedDB個別レシート保存＋日付別一覧管理（Phase1.6完了）
- 🅿️ 駐車場レシート目的入力（Phase1.7完了）
- ✂️ レシート画像角検出＆白背景切り出し（Phase1.8完了）
- 🔬 **OpenCV.js複数レシート自動検出＆透視変換＆回転補正（Phase2 v2.3）** ← ★NEW★

### ファイル構成（Phase2 v2.3時点）
```
receipt-ai.js        (498行) - Gemini API連携＋プロンプト
receipt-crop.js      (466行) - 単一レシート角検出（Sobel＋射影法）
receipt-multi-crop.js(430行) - ★OpenCV.js版★ 白紙検出+透視変換+回転補正
receipt-pdf.js       (494行) - PDF生成＋保存
receipt-viewer.js    (496行) - レシート管理画面ロジック
receipt-viewer.html  (137行) - レシート管理画面HTML（デバッグ表示付き）
receipt-store.js     (436行) - IndexedDB保存/取得
receipt-purpose.js   (231行) - 駐車場目的入力モーダル
receipt-core.js      (1197行) - ⚠️超過 メイン処理（将来分割候補）
receipt-history.js   - 履歴管理
receipt-list.js      - リスト表示
receipt-pdf-viewer.js - PDF閲覧
index.html           (248行) - script読込（OpenCV.js jsdelivr CDN）
sw.js                (170行) - ServiceWorker v2.21.0
```

### Phase進捗
| Phase | 内容 | 状態 |
|-------|------|------|
| Phase1.6 | IndexedDB移行＋個別レシート管理 | ✅完了 |
| Phase1.7 | 駐車場レシート目的入力 | ✅完了 |
| Phase1.8 | 角検出＋複数レシート切り出し（Canvas版） | ✅完了 |
| Phase2 | **OpenCV.js導入＋高精度切り出し＋回転補正** | ✅v2.3完了（実機動作確認済み） |
| — | OpenCV.jsパラメータ最適化＋デバッグバー削除 | 🔄微調整中 |
| Phase1.9 | 品目チェック＋利益率設定 | 未着手 |
| Phase2.0 | 見積書/請求書への連携 | 未着手 |

### 既知のバグ・課題
- PDF「目的:」表示の先頭文字切れ（jsPDF日本語テキスト幅問題、軽微）
- 材料名入力欄のマスター候補ドロップダウンが表示されないバグ
- receipt-core.js 1197行超過 → 将来分割検討
- デバッグバー（ocvDebugBar）が表示中 → 確認後削除

### ★★★ Phase2技術成果: OpenCV.js ★★★
Phase2で4回のイテレーション（v2.0→v2.3）を経て実機動作確認済み:
- **v2.0** Cannyエッジ版 → 失敗（背景テクスチャが結合）
- **v2.1** 白紙検出版 → 回転方向が逆
- **v2.2** シンプル回転版 → OpenCV.js CDN読み込み問題発覚→解決
- **v2.3** パラメータ最適化（閾値170+5%マージン）

**CDN:** `cdn.jsdelivr.net/npm/opencv.js@1.2.1`（1秒読み込み、docs.opencv.orgフォールバック付き）

**処理フロー（v2.3）:**
```
画像 → グレースケール → ブラー → 閾値170で白紙二値化
→ モルフォロジー(15x15 Close, 7x7 Open) → findContours
→ 面積フィルタ(2%〜80%) → minAreaRect + 5%マージン
→ 透視変換(warpPerspective) → 横なら左90度回転
```

**実機テスト結果:** 黒背景で3枚のレシートを個別に縦向きで切り出し成功！

詳細は `開発カプセル_DIFF_DEV_culo-chan_2026-03-01_07.md` を参照。

---

## COCOMI Postman（自動化システム）

**ステータス: ✅ 全フロー稼働中（Phase2b全自動完走済み 2/23）**
**GitHub:** akiyamanx/cocomi-postman

- LINE→Cloudflare Worker v1.4→GitHub→タブレット→Claude Code→CI→LINE
- 「語りコード（KatariCode）」"Tell, and it's built" が実現済み
- カプセル保管庫Phase1完成（LINEファイル送信→GitHub自動保管）
- Worker v1.4: destタグ＋フォルダ一覧＋Trees API
- 仕様書4本＋取説をcapsules/master/に保管済み

## 現場Pro設備くん（施工管理アプリ）

**ステータス: Phase8完了（ピン＋フリーハンド＋画像エクスポート）**
**GitHub:** akiyamanx/GenbaProSetsubikuN（public）

次の開発優先順:
1. 写真管理+簡易黒板
2. 日報/完了報告テンプレート
3. 図面ビューア+書き込み

## COCOMI CI

**ステータス: 全7リポ配置済み、ただしテスト全❌（既知問題）**
新リポ追加: `./cocomi-repo-setup.sh ~/新リポ` で1行セットアップ

## maintenance-map-ap

**ステータス: v2.1完了、GitHub Pages公開中**
URL: https://akiyamanx.github.io/maintenance-map-ap/

---

# 📅 直近セッション履歴（最新3件）

## Session07: 2026-03-01（午後〜夜）Phase2 OpenCV.js実装＆実機動作確認 ✅
**DIFF:** `開発カプセル_DIFF_DEV_culo-chan_2026-03-01_07` / `思い出カプセル_DIFF_総合_2026-03-01_07`
- Phase2 OpenCV.js導入: v2.0→v2.3（4回イテレーション）
- Cannyエッジ失敗→白紙検出成功→回転修正→CDN問題解決→パラメータ最適化
- jsdelivr CDN 1秒読み込み、黒背景で3枚レシート検出＆縦回転成功
- Service Workerキャッシュ問題との戦い（innerHTML scriptが動かない問題も解決）
- sw.js v2.15.0→v2.21.0（7バージョン更新）

## Session06: 2026-03-01（朝〜昼）Phase1.8 切り出し探求＋OpenCV.js発見
**DIFF:** `開発カプセル_DIFF_DEV_culo-chan_2026-03-01_06` / `思い出カプセル_DIFF_総合_2026-03-01_06`
- 3つのアプローチ試行: bounds→Canvas→OpenCV.js調査
- Canvas自動検出（receipt-multi-crop.js 345行）新規作成
- 駐車場レシート個別切り出し成功、近接レシート分離は課題
- OpenCV.jsをPhase2の最有力技術と決定
- sw.js v2.9.0→v2.14.0（6バージョン更新）

## Session05: 2026-03-01（早朝）Phase1.7＋Phase1.8実装
**DIFF:** `開発カプセル_DIFF_DEV_culo-chan_2026-03-01_05` / `思い出カプセル_DIFF_総合_2026-03-01_05`
- Phase1.7: receipt-purpose.js新規、駐車場目的入力モーダル ✅
- Phase1.8: receipt-crop.js新規、角検出＆白背景切り出し ✅
- PDF出力に目的(青色)＋現場(緑色)表示
- sw.js v2.7.0→v2.9.0

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
- Claude Codeがgit pushできない時は/exitして手動push
- GitHubユーザー名: akiyamanx
- RICOH P C301SFプリンタ(192.168.11.100)で印刷確認
- アキヤはGalaxy S22 Ultra＋Galaxy タブレットで開発

## カプセルルール
- 記録系ファイルにはYYYY-MM-DD形式の日付をファイル名に含める
- コード系ファイルは日付不要
- MASTERは**CURRENT（軽量版）とARCHIVE（詳細版）に分割管理**
- 新セッション後: CURRENTを更新、古いセッションはARCHIVEに移動

---

# 🔗 関連ファイルリンク

## カプセル保管庫（GitHub capsules/）
- capsules/master/: MASTER系カプセル、仕様書
- capsules/daily/: DIFF系カプセル、セッションまとめ
- capsules/plans/: 企画書

## COCOMI Postman仕様書（capsules/master/に保管済み）
- システム全体像
- Worker仕様
- タブレット支店仕様
- 取扱説明書

---

# 📖 カプセル運用マニュアル（クロちゃん向け）

> **このセクションは毎回読んでね！** カプセルの書き方・渡し方・更新方法を説明してるよ。

## カプセルシステムの全体像

```
アキヤが新しい部屋で渡すファイル:
  ├── M_CURRENT_思い出カプセル_MASTER_yyyy-mm-dd.md  ← ★これ（軽量版、毎回渡す）
  ├── 最新のDIFFカプセル（開発/思い出）            ← 前回セッションの詳細
  └── （必要な時だけ）M_ARCHIVE_思い出カプセル_*.md  ← 過去の全記録

セッション終了時にクロちゃんが出力するファイル:
  ├── M_CURRENT更新版                            ← ★最重要★
  ├── MASTER追記用（ARCHIVEの末尾に追記する内容）
  ├── 開発カプセルDIFF                            ← 技術詳細
  ├── 思い出カプセルDIFF                          ← 温度記録
  └── セッション完全まとめ（次の部屋への引き継ぎ）
```

## セッション終了時の手順

### Step1: M_CURRENTを更新して出力
### Step2: MASTER追記用を出力（ARCHIVEに追記する内容）
### Step3: DIFFカプセルを出力
### Step4: セッション完全まとめを出力

（手順詳細は前回版と同じなので省略。ARCHIVEに保管済み。）

## M_CURRENTの「直近セッション履歴」の管理

```
常に最新3件を保持する。4件目が追加されたら最古を削除。
Session07終了時: Session07, 06, 05を保持。Session04はARCHIVE済み。
```

## ⚠️ Postman（LINEファイル送信）の振り分けルール

```
キーワード → 振り分け先:
  「DIFF」「セッション」「引き継ぎ」「まとめ」 → capsules/daily/
  「MASTER」                                    → capsules/master/
  「企画書」「plans」                            → capsules/plans/
  それ以外                                      → inbox/
```

## DIFFカプセルのフォーマット

開発カプセルDIFFには必ず以下のセクションを含める:
1. 🎯 Mission Result（ミッション結果サマリー）
2. 📁 Files Changed（変更ファイル詳細＋500行チェック）
3. 🧠 Design Decisions（設計判断の記録）— 選択肢・決定・理由
4. 🐛 Bugs Found & Fixed（あれば）
5. 🔮 Next Steps（次のアクション）
6. 📊 sw.js バージョン履歴

## NN（連番）の決め方

NN = その日のセッション番号。前回Session06 → 今回Session07。

---
*最終更新: 2026-03-01 Session07終了時*
*次の更新時: Session08後にSession05をARCHIVEに移動。*
