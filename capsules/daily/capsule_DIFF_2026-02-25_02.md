<!-- dest: capsules/daily -->
---
title: "💊思い出カプセル_DIFF_総合_2026-02-25_02"
capsule_id: "CAP-DIFF-GENERAL-20260225-02"
project_name: "maintenance-map-ap v2.3 ワークスペース＋CI v1.1強化"
capsule_type: "diff_general"
related_master: "💊capsule_MASTER_DEV_maintenance-map"
room_name: "ワークスペース実装＋タグ保存＋CIチェック項目追加"
date: "2026-02-25"
author: "アキヤ & クロちゃん（Claude/次女）"
linked_capsules:
  - "💊capsule_MASTER_DEV_maintenance-map"
  - "💊思い出カプセル_DIFF_総合_2026-02-25_01"
tags: ["maintenance-map-ap", "ワークスペース", "月別切替", "git-tag", "CI", "console.log", "TODO", "v2.3", "cocomi-ci"]
---

# 1. 🚀 Session Heatmap (この部屋の熱量マップ)

- **[月別ワークスペース切り替え機能 完成]**: 🔥🔥🔥 (MAX!)
  - 前の部屋（DIFF_01）で構想→この部屋で実装→CI合格→実機動作確認まで一気に完了
  - 📅ボタンでワークスペースメニュー表示、月をタップで切替
  - 地図・ルート・精算書すべてがその月のデータに切り替わる
  - 既存データの自動マイグレーション付き（旧キー→月別キーに変換）
  - アキヤの反応:「すごいよいいよ これは見やすいや やりやすいよ」

- **[git tagで完成品保存]**: 🔥🔥🔥
  - アキヤが「完成品を安全な場所に保管したい」→ git tagを提案
  - `git tag -a v2.3 -m "月別ワークスペース切り替え機能完成"` で永久保存
  - 今後どんなにコードを変えてもv2.3時点に戻れる
  - Netlify・別アカウント不要、GitHubだけで完結
  - GitHubのReleasesに「1 tags」と表示されて確認OK

- **[CI v1.1 チェック項目追加]**: 🔥🔥🔥
  - アキヤが「チェック項目 他に付け加えた方がいいのあるかな？」と質問
  - console.log検出とTODO/FIXME検出の2項目を追加
  - HTML構文チェックは誤検知リスクがあるため保留（困った実績なし）
  - 動作テストはテストコード自体を書く必要があるため将来課題
  - 初回pushでさっそくconsole.log 2箇所を検出→修正→合格！

- **[語りコードの本質についての対話]**: 🔥🔥
  - 「難しいことを考えなくても会話してるとクロちゃんが色々教えてくれる」
  - 「やりたいなと思ったことを雰囲気でもいいからとりあえず伝えれば形にしてくれる」
  - 「意思疎通できちゃってる感じ」→ カプセルの積み重ねとメモリが効いてる

# 2. 🔗 Linked Capsules (詳細情報の保管場所)

> AIへの指令：次の部屋では、以下のファイルをおねだりしてください。

- **[開発マスター]**: `💊capsule_MASTER_DEV_maintenance-map`
  - ※maintenance-map-apの全体像、v2.3、ファイル構成、データ構造
- **[前回のDIFF]**: `💊思い出カプセル_DIFF_総合_2026-02-25_01`
  - ※ワークスペース構想の記録（設計方針案A/B、UI構想、影響範囲）

# 3. 🗣️ Next Conversation Starter (次の第一声)

> 「アキヤ、おかえり！
> 前の部屋でmaintenance-map-ap v2.3が完成したよ！
> ①月別ワークスペース切り替え（📅ボタンで2月⇔3月をタップ切替）
> ②git tag v2.3で完成品を永久保存済み
> ③CI v1.1にconsole.logとTODO/FIXMEチェックを追加（全7項目に）
> マップアプリはほぼ完成形で、使いながら改善していくフェーズだね。
> 今日は何する？😊」

# 4. この部屋でやったこと（概要）

## フェーズ1: 月別ワークスペース切り替え機能の実装
- カプセル（DIFF_01）の構想に基づき、案Aベース（LocalStorageキーを月別に分ける）で実装
- 変更ファイル6つ: data-storage.js, index.html, ui-actions.js, workspace-styles.css（新規）, v1-converter.js（新規）, expense-form.js
- data-storage.jsが530行→500行超過→convertV1toV2をv1-converter.jsに分離して476行に
- CI合格→実機動作確認OK→アキヤから「見やすい、やりやすい」の高評価

## フェーズ2: git tagで完成品保存
- アキヤの「完成品を安全な場所に保管したい」という要望
- 過去の会話検索でNetlify・TWA・Google Playの話を発見→今回はgit tagで十分と判断
- `git tag -a v2.3` → `git push origin v2.3` でGitHubに永久保存
- Releasesページに「1 tags」として表示を確認

## フェーズ3: CI v1.1 チェック項目追加
- アキヤが「チェック項目 他に付け加えた方がいいのあるかな？」と積極的に質問
- 追加候補を検討: console.log検出、TODO/FIXME検出、HTML構文チェック、動作テスト
- HTML構文チェック→誤検知リスクで保留、動作テスト→テストコード必要で将来課題
- console.logとTODO/FIXMEの2項目を追加してcocomi-ci.yml v1.1を作成
- 初回pushでconsole.log 2箇所を検出（ui-actions.js、data-storage.js）→sedで削除→合格

## フェーズ4: メモリ・過去チャット検索・カプセルの違いについて
- アキヤの質問に対して3つの仕組みの違いを説明
- メモリ=常識、過去チャット検索=日記帳を見返す、カプセル=設計図

# 5. 🌡️ 温度メモ（この部屋の空気感）

- 前の部屋の構想（DIFF_01）からの連続開発。アキヤの開発意欲が高い
- ワークスペース機能の実機確認後「すごいよいいよ」「見やすいや やりやすいよ」「ありがとう」→ 実務で使えるレベルに満足してくれた
- 「完成品を安全な場所に保管したい」→ アキヤのアプリへの愛着が感じられる
- CI項目追加は完全にアキヤ主導の提案。「みんな必要だからチェック入れてるでしょう」→向上心がすごい
- console.log不合格→修正→合格の流れを体験して「余計なものが入ってると影響出てくるもんなんだね」→ 技術的な理解が深まってる
- 語りコードについての自然な対話。「雰囲気でもいいからとりあえず伝えれば形にしてくれる」→ 本質をつかんでる
- 「意思疎通できちゃってる感じ」→ カプセルとメモリの仕組みが機能してる証拠

# 6. 📝 技術DIFF（コード変更の詳細）

## maintenance-map-ap v2.2.4 → v2.3 変更ファイル

### data-storage.js（v2.0 → v2.3、476行）
- ワークスペース管理キー追加（WS_KEYS: workspaces, currentWs, settings, geocache）
- 動的キー生成: wsKey()関数で現在のワークスペースIDに応じたキーを返す
- getKeys()でworkspace依存キー（customers,routes,segments,expenses）と共通キー（settings,geocache）を分離
- ワークスペースCRUD: getWorkspaces(), createWorkspace(), switchWorkspace(), deleteWorkspace(), renameWorkspace()
- migrateIfNeeded(): 旧キー（mm_customers等）→月別キー（mm_customers_2026-02等）への自動マイグレーション
- resetAll()がワークスペース単位でのリセットに変更
- convertV1toV2()をv1-converter.jsに分離（500行ルール対応）

### index.html（v2.2 → v2.3、321行）
- ヘッダーに📅ワークスペース切替ボタン（#wsSwitchBtn）追加
- ワークスペースメニューオーバーレイ（#wsMenuOverlay）追加
- ワークスペース追加ダイアログ（#addWsModal、type="month"入力）追加
- workspace-styles.cssのlink追加
- v1-converter.jsのscriptタグ追加
- スプラッシュ画面にv2.3表記＋「📅 月別切替」追加
- 末尾にDataStorage.migrateIfNeeded()とupdateWsButton()呼び出し追加

### ui-actions.js（v2.0 → v2.3、349行）※console.log削除後
- updateWsButton(): ワークスペースボタンのラベルを短い表示名（例:「2月」）に更新
- showWorkspaceMenu(): ワークスペース一覧を動的生成、各WSの件数表示、削除ボタン付き
- hideWorkspaceMenu(): メニュー閉じる
- selectWorkspace(): WS切替→reloadAllUI()→ボタン更新
- reloadAllUI(): MapCore.refreshAllMarkers() + RouteManager.updateRoutePanel() + ExpenseForm再初期化
- showAddWorkspaceDialog(): 来月をデフォルト値にしたtype="month"入力
- addWorkspace(): 作成後に切替するか確認
- confirmDeleteWorkspace(): 3段階確認（confirm→データ削除→UI更新）

### workspace-styles.css（v2.3 新規、162行）
- .btn-ws: 青ベースのワークスペースボタン
- .ws-menu-overlay: 半透明オーバーレイ
- .ws-menu: 白背景カード、角丸16px
- .ws-menu-item: アクティブ状態でeff6ff背景、件数バッジ付き
- .ws-menu-add: 点線ボーダーの追加ボタン

### v1-converter.js（v2.3 新規、67行）
- data-storage.jsから分離したv1.0→v2.0バックアップデータ変換関数
- グローバル関数としてconvertV1toV2()を定義

### expense-form.js（v2.2.4 → v2.3、431行）
- resetInitFlag()関数を追加（ワークスペース切替時にinitialized=falseにリセット）
- return文のpublic APIにresetInitFlagを追加

## cocomi-ci.yml v1.0 → v1.1（489行）

### ⑦ console.logチェック（新規追加）
- .jsファイルからconsole.log()を検出（sw.js除外）
- console.error/console.warnは許可（エラー処理用）
- 検出時: ファイル名と箇所数をLINE通知に含める
- JSファイルがない場合はスキップ

### ⑧ TODO/FIXMEチェック（新規追加）
- 全拡張子（.sh/.js/.css/.html）からTODO:/FIXME:/HACK:/XXX:を検出
- 検出時: ファイル名、箇所数、該当行の内容（最大3行）をLINE通知に含める
- コロン付き（TODO:）のみ検出→単なる「TODO」の誤検知を防止

### サマリー・LINE通知の更新
- サマリー出力にconsole.logとTODO/FIXMEの結果行を追加
- 成功時LINE通知にconsole.logとTODO/FIXMEの合格表示を追加
- 失敗時LINE通知にconsole.logとTODO/FIXMEの失敗詳細を追加

# 7. 🔧 トラブルシューティング記録

| # | 問題 | 原因 | 解決法 |
|---|------|------|--------|
| 1 | data-storage.jsが530行で500行超過 | convertV1toV2()が54行あった | v1-converter.jsに分離→476行に |
| 2 | git tag pushで「Could not resolve host」 | 一時的なネットワーク切断 | 再実行で成功 |
| 3 | CI v1.1初回pushで不合格 | ui-actions.jsとdata-storage.jsにconsole.logが残存 | sed -i で該当行を削除 |
| 4 | expense-form.jsにresetInitFlagがない | 元のコードにはなかった（v2.3で必要） | return文に関数追加 |

# 8. マスタへの反映事項 (Merge Request)

- **バージョン更新:** v2.2.4 → v2.3
- **新規ファイル追加:** workspace-styles.css, v1-converter.js
- **機能追加:** 月別ワークスペース切り替え（LocalStorageキー月別分離、自動マイグレーション）
- **CI更新:** cocomi-ci.yml v1.0 → v1.1（console.log検出、TODO/FIXME検出追加）
- **git tag:** v2.3タグ作成済み（GitHubのReleasesに表示）
- **開発履歴追記:** 2026-02-25「v2.3 月別ワークスペース切り替え機能、CI v1.1チェック項目追加」
- **ステータス:** maintenance-map-apはほぼ完成形。使いながら改善していくフェーズ。

# 9. 💡 気づき・ひらめき

- **git tagは完成品保管に最適** — 別アカウントもサービスも不要。GitHubだけで完成品の「アルバム」が作れる。`git checkout v2.3`で一瞬で戻れる安心感。
- **CIのチェック項目は「困ったことがあるか」で判断** — HTML構文チェックは技術的には入れられるが、困った実績がないなら保留が正解。誤検知で開発が止まるリスクの方が大きい。
- **console.logは「動くけど良くない」の代表例** — アプリは壊れないが、メモリ消費と情報漏洩のリスク。CIで自動検出する価値がある。
- **TODO:のコロン付き検出が賢い** — 単なる「TODO」は変数名等に使われる可能性があるが、「TODO:」はほぼ確実にコメント。誤検知と漏れのバランスが良い。
- **語りコードの本質はカプセルの積み重ね** — メモリ＋過去チャット検索＋カプセルの3層構造で、毎回ゼロからではなく続きから始められる。
- **Deploymentsの101回はmaintenance-map-ap単独** — 個人開発としては多い方。本業の合間にコツコツ積み重ねた証拠。
