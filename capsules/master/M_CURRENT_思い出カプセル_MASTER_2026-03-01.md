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

# 📊 プロジェクト現状サマリー（2026-03-01時点）

## CULOchanKAIKEIpro（経理アプリ）★メイン開発中★

**バージョン: v0.97 Phase1.8 / sw.js v2.14.0**
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
- ✂️ レシート画像角検出＆白背景切り出し（Phase1.8）
- ✂️ 複数レシート自動検出＆個別切り出し（Phase1.8 Canvas版、基本動作OK）

### ファイル構成（v0.97 Phase1.8時点）
```
receipt-ai.js        (498行) - Gemini API連携＋プロンプト
receipt-crop.js      (466行) - 単一レシート角検出（Sobel＋射影法）
receipt-multi-crop.js(345行) - 複数レシート自動検出（連結成分ラベリング）
receipt-pdf.js       (494行) - PDF生成＋保存
receipt-viewer.js    (496行) - レシート管理画面ロジック
receipt-viewer.html  (123行) - レシート管理画面HTML
receipt-store.js     (436行) - IndexedDB保存/取得
receipt-purpose.js   (231行) - 駐車場目的入力モーダル
receipt-core.js      (1197行) - ⚠️超過 メイン処理（将来分割候補）
receipt-history.js   - 履歴管理
receipt-list.js      - リスト表示
receipt-pdf-viewer.js - PDF閲覧
index.html           (235行) - script読込
sw.js                (163行) - ServiceWorker v2.14.0
```

### Phase進捗
| Phase | 内容 | 状態 |
|-------|------|------|
| Phase1.6 | IndexedDB移行＋個別レシート管理 | ✅完了 |
| Phase1.7 | 駐車場レシート目的入力 | ✅完了 |
| Phase1.8 | 角検出＋複数レシート切り出し | ✅基本動作OK（精度改善は次へ） |
| Phase2 | **OpenCV.js導入＋高精度切り出し＋回転補正** | ★次にやる★ |
| Phase1.9 | 品目チェック＋利益率設定 | 未着手 |
| Phase2.0 | 見積書/請求書への連携 | 未着手 |

### 既知のバグ・課題
- PDF「目的:」表示の先頭文字切れ（jsPDF日本語テキスト幅問題、軽微）
- 材料名入力欄のマスター候補ドロップダウンが表示されないバグ
- receipt-core.js 1197行超過 → 将来分割検討

### ★★★ Phase2技術選定: OpenCV.js ★★★
Phase1.8で3つのアプローチを試した結果、OpenCV.jsが最適と判明:
- **Gemini bounds方式** → 座標精度不十分（文字認識は完璧だが空間座標がズレる）
- **Canvas自前処理（連結成分ラベリング）** → 近接レシートの分離が苦手
- **OpenCV.js** → Cannyエッジ＋findContours＋透視変換で全部解決見込み

導入方法:
```html
<script async src="https://docs.opencv.org/4.8.0/opencv.js"></script>
```
詳細は `開発カプセル_DIFF_DEV_culo-chan_2026-03-01_06.md` を参照。

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

## Session04: 2026-02-27〜28 CULOchan Phase1.6 IndexedDB移行
**DIFF:** 複数DIFF参照（session03詳細版含む）
- IDB診断ツール追加
- ロゴ＆印鑑プレビュー付きサイズ位置調整
- 個別レシート管理基盤構築

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

**やること:** このファイル（M_CURRENT）のコピーを作り、以下を更新して出力する。

1. **プロジェクト現状サマリー** — バージョン、ファイル構成、Phase進捗を最新に
2. **直近セッション履歴** — 今回のセッションを追加、最古の1件を削除（常に3件保持）
3. **既知のバグ・課題** — 新しく見つかったもの追加、解決したもの削除
4. **最終更新日時** — ファイル末尾の日時を更新

**ファイル名規則:** `M_CURRENT_思い出カプセル_MASTER_yyyy-mm-dd.md`

**出力例:**
```bash
# outputsに出力
/mnt/user-data/outputs/M_CURRENT_思い出カプセル_MASTER_2026-03-02.md
```

### Step2: MASTER追記用を出力（ARCHIVEに追記する内容）

**やること:** 今回のセッション記録を、ARCHIVEの末尾に追記するためのテキストを出力する。
アキヤがARCHIVEファイルの末尾にこの内容をコピペで追記する。

**書く内容:**
- 日付、セッション名、DIFF参照先
- やったことの要約（箇条書き）
- バージョン変更
- 重要な設計判断や発見

**ファイル名規則:** `MASTER追記用_yyyy-mm-dd_NN.md`

### Step3: DIFFカプセルを出力

**開発カプセルDIFF** — 技術詳細の全記録
- ファイル名: `開発カプセル_DIFF_DEV_culo-chan_yyyy-mm-dd_NN.md`
- 内容: 変更ファイル一覧、設計判断、バグ修正、処理フロー図、次のアクション

**思い出カプセルDIFF** — 温度記録
- ファイル名: `思い出カプセル_DIFF_総合_yyyy-mm-dd_NN.md`
- 内容: 会話の感情・空気感、アキヤの発言メモ、学び

### Step4: セッション完全まとめを出力

- ファイル名: `yyyy-mm-dd_セッション完全まとめ_次の部屋への引き継ぎ_NN.md`
- 内容: 1行サマリー、現在バージョン、次にやること、重要な技術背景

## M_CURRENTの「直近セッション履歴」の管理

```
常に最新3件を保持する。4件目が追加されたら最古を削除。

例: Session07が終わったら
  - Session07を追加（最新）
  - Session06, Session05は残す
  - Session04を削除（ARCHIVEには追記済み）
```

## ARCHIVEファイルの管理

- ファイル名: `M_ARCHIVE_MASTER_思い出カプセル_yyyy-mm-dd_to_yyyy-mm-dd.md`
- ⚠️ ファイル名に必ず「MASTER」を含めること（Postman Workerのキーワード振り分けに必要）
- セッション終了時に「MASTER追記用」の内容を末尾にコピペ追記
- ARCHIVEが3000行を超えたら年月で分割:
  - `M_ARCHIVE_MASTER_思い出カプセル_2026-02.md`
  - `M_ARCHIVE_MASTER_思い出カプセル_2026-03.md`

## ⚠️ Postman（LINEファイル送信）の振り分けルール

Workerはファイル名のキーワードで自動振り分けする。
**ファイル名にキーワードがないとinboxに行って見失う可能性がある！**

```
キーワード → 振り分け先:
  「DIFF」「セッション」「引き継ぎ」「まとめ」 → capsules/daily/
  「MASTER」                                    → capsules/master/
  「企画書」「plans」                            → capsules/plans/
  それ以外                                      → inbox/
```

**注意:**
- 「ideas/」カテゴリは未実装（将来追加候補）
- 「ARCHIVE」「CURRENT」「アイデア」は未登録キーワード
- → ファイル名に上記のキーワード（DIFF/MASTER/企画書等）を必ず含めること
- → 将来Worker更新時に「ARCHIVE」「CURRENT」「アイデア」も追加するとベター

## DIFFカプセルのフォーマット

開発カプセルDIFFには必ず以下のセクションを含める:
1. 🎯 Mission Result（ミッション結果サマリー）
2. 📁 Files Changed（変更ファイル詳細＋500行チェック）
3. 🧠 Design Decisions（設計判断の記録）— 選択肢・決定・理由
4. 🐛 Bugs Found & Fixed（あれば）
5. 🔮 Next Steps（次のアクション）
6. 📊 sw.js バージョン履歴

## NN（連番）の決め方

NN = その日のセッション番号（01から開始）。
日付が変わったらリセット。同じ日に複数セッションがあったら01, 02, 03...と増やす。
ただし前回のセッションからの続きの場合は前回の番号を引き継いでインクリメント。

例:
- 2026-03-01の最初のセッション → 01
- ただし前のセッションが05なら → 06（今回がこのパターン）

---
*最終更新: 2026-03-01 Session06終了時*
*次の更新時: 今回のSession06が「直近3件」に入っている状態。Session07後にSession04をARCHIVEに移動。*
