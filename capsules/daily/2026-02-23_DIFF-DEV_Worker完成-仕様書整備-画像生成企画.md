<!-- dest: capsules/daily -->
# 開発カプセル DIFF_DEV — 2026-02-23（午後セッション）
# Worker v1.4完成・仕様書整備・画像生成企画・命名ルール追加
# 作成: クロちゃん（Claude Opus 4.6）

---

## 🔧 今日の開発成果（午後セッション）

### 1. Worker v1.4 フォルダコマンド完成（前セッションからの引き継ぎ）
- Trees APIを採用し、リポジトリ全体のファイル構造を1回のAPI呼び出しで取得
- 「フォルダ一覧」コマンド: 全フォルダ構造＋件数表示
- 「フォルダ ○○」コマンド: 指定フォルダの中身（最新20件）表示
- 初版は再帰的Contents APIでタイムアウト → Trees APIに変更して解決
- Cloudflare Dashboardでworker.js貼り替えてデプロイ完了
- LINEでの動作テスト全て成功

### 2. 仕様書＆取扱説明書の作成（4ファイル）
capsules/master/に保管済み:
- **COCOMI-POSTMAN-仕様書-システム全体像.md** — 全体構成図、使用サービス、フォルダ構成、処理フロー
- **COCOMI-POSTMAN-仕様書-Worker.md** — LINEコマンド一覧、ルーティング仕様、API詳細
- **COCOMI-POSTMAN-仕様書-タブレット支店.md** — postman.sh、executor、step-runner、CI/CD
- **COCOMI-POSTMAN-取扱説明書.md** — やりたいこと別の使い方ガイド、通知の読み方、トラブル対処

全ファイルdestタグ付き → LINEで4つ同時送信テスト → **全部成功！**
同時送信でもWorkerが全てさばけることを実証。

### 3. 画像生成＆Live2Dパイプライン企画書
capsules/plans/に保管済み:
- **企画書_COCOMI画像生成_Live2Dパイプライン.md**

内容:
- ナノバナナ（Gemini 2.5 Flash Image）とナノバナナPro（Gemini 3 Pro Image）の調査
- 料金比較: Flash=$0.039/枚、Pro=$0.134〜$0.24/枚
- アキヤの既存Gemini APIキーで画像生成も使える可能性
- Live2D Automation MCPサーバー: 1枚の画像からLive2Dモデル自動生成
- NanoLive2D: ナノバナナ×Live2Dの実例プロジェクト発見
- Level 1〜6のステップバイステップロードマップ策定
- COCOMIパイプラインへの統合方法の設計

### 4. ファイル命名ルール追加（Postman全自動実行）
- M-NAMING-RULES.md指示書を作成 → LINEで送信
- テザリング切れでPostman検知できず → WiFi再接続で即検知
- Step 1/2（CLAUDE.mdに命名ルール追加）→ CI合格 → Step 2/2（確認）→ 全完了
- レポート・カプセル・指示書のファイル名に内容要約を含めるルールを追加

### 5. メモリ整理＆更新
- #25追加: Worker v1.4 destタグルーティング仕様
- #26追加: LINEコマンド一覧
- #27追加: 仕様書・企画書の保管場所
- #22更新: Postman Phase2b → Worker v1.4情報に更新
- #10,#11統合: CULOchan残作業を1枠に圧縮
- 現在26/30枠使用（4枠空き）

---

## 📊 技術メモ

### Trees API vs Contents API
- Contents API: フォルダごとに1回ずつ呼び出し（再帰で数十回）→ タイムアウト
- Trees API: `/git/trees/main?recursive=1` で全体を1回で取得 → 高速
- Cloudflare Worker無料プラン: CPU時間に制限あり → API呼び出し最小化が重要

### ナノバナナ関連技術情報
- Nano Banana = Gemini 2.5 Flash Image（モデルID: gemini-2.5-flash-image）
- Nano Banana Pro = Gemini 3 Pro Image（モデルID: gemini-3-pro-image-preview）
- Imagenは前世代、ナノバナナが後継で上位互換
- SynthID電子透かしが自動付与される
- 最大4K解像度（Proのみ）
- キャラクター一貫性機能あり（同じキャラを異なるポーズで生成可能）

### Live2D自動化
- Live2D Automation MCP: 1画像→自動パーツ分離→リギング→モーション生成
- PIXI.js + Live2D SDK: Webブラウザ上で60FPS表示
- GitHub Pages公開可能 → COCOMIの既存インフラで動作

---

## 🐛 発見した問題と対処

### テザリング切断問題
- タブレットのPostmanが毎分「チェック完了 新着なし」と表示
- git pullが`Could not resolve host: github.com`エラー
- 原因: スマホのテザリングが切れていた
- 対処: WiFi再接続 → 即座にPostmanが検知して実行開始

---

## 📁 今日作成・更新されたファイル一覧

| ファイル | 保管先 | 種別 |
|---|---|---|
| COCOMI-POSTMAN-仕様書-システム全体像.md | capsules/master/ | 仕様書 |
| COCOMI-POSTMAN-仕様書-Worker.md | capsules/master/ | 仕様書 |
| COCOMI-POSTMAN-仕様書-タブレット支店.md | capsules/master/ | 仕様書 |
| COCOMI-POSTMAN-取扱説明書.md | capsules/master/ | 取説 |
| 企画書_COCOMI画像生成_Live2Dパイプライン.md | capsules/plans/ | 企画書 |
| M-NAMING-RULES.md | missions/cocomi-postman/ | 指示書（実行済） |
| worker_v1.4.js | Cloudflareにデプロイ済 | Worker本体 |
| CLAUDE.md | cocomi-postmanリポ | 命名ルール追加済 |
