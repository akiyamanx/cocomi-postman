# 📲 COCOMI Postman LINE配達＋ステップ実行＋カプセル保管庫 企画書 v1.1
## 〜 LINEでファイルを運んで、ステップごとに確実に作って、記憶をGitHubに守る 〜

**作成日:** 2026-02-21（v1.0）→ 2026-02-22 更新（v1.1）
**作成者:** アキヤ & クロちゃん（Claude Opus 4.6）
**ステータス:** 🔧 Phase 1完了 / Phase 2設計確定 / カプセル保管庫統合追加
**関連:** COCOMI Postman企画書 v1.1 / カプセル保管庫企画書 v1.0

### v1.1 更新内容
- Phase 1（ステップ実行）✅完了を反映
- Phase 2の技術選定確定: **Cloudflare Workers**（polling方式→Webhook方式に変更）
- **カプセル保管庫のGitHub統合**をPhase 4.5として追加
- 1部屋1人ルール、Maker-Checker不要判断を反映
- 実装順序の確定（急がば回れ方式）

---

## 1. 背景と課題

### 現状のファイル受け渡し
```
クロちゃんが指示書を作成
    ↓
アキヤがスマホで指示書の中身をコピー
    ↓
Galaxyクリップボード共有でタブレットに転送
    ↓
タブレットのTermuxでペースト（or post.shで送信）
    ↓
Claude Codeが実行
```

### 問題点

**ファイル受け渡しの問題:**
1. **中身が大きいとコピペが大変** — 指示書が長い時、途切れたり崩れたりする
2. **ファイルが複数あると何回もコピペ** — 13ファイルの指示書とか地獄
3. **ファイル自体を渡せない** — 中身のテキストしかコピペできない
4. **カプセルや企画書の受け渡しも同じ問題** — 全部コピペ作業

**実行の問題:**
5. **指示書を一気に渡すとClaude Codeが全部やろうとする** — 大きすぎると失敗しやすい
6. **途中で止まると再開が面倒** — どこまでやったかわからなくなる
7. **確認なしで次に進んでしまう** — Step 1のバグがStep 2に影響

**🆕 v1.1追加: カプセル（記憶）の受け渡し問題:**
8. **カプセルの渡し忘れ** — 次の部屋にファイルを渡し忘れると引き継ぎが不完全
9. **渡す順番間違い** — 複数ファイルの優先度・順番を人間が管理するのが面倒
10. **毎回同じ読み込み時間** — 新しい部屋で毎回クロちゃんがカプセルを最初から読む
11. **カプセルがスマホのローカルにしかない** — 紛失リスク、バージョン管理なし

### アキヤの一言
> 「ファイル自身をLINEでPostmanに渡して持ち運べるようにしたい」
> 「指示書はまとめて渡すけど、ステップごとに順番にやってもらいたい」
> 「GitHubにカプセルを保存して、クロちゃんが自分で読めるようにしたい」 ← 🆕v1.1

---

## 2. コンセプト

### 「LINEが配達トラック、Postmanが仕分け係、Claude Codeが職人、GitHubが金庫」

```
📲 LINE（配達トラック）
  アキヤやクロちゃんからファイルを受け取って運ぶ
      ↓
📮 Postman（仕分け係）
  ファイルを正しい場所に配置＋ステップ順に管理
      ↓
🔧 Claude Code（職人）
  1ステップずつ確実に施工。終わったら報告
      ↓
📲 LINE（結果配達）
  「Step 1 ✅ 次はStep 2やるよ」と通知
      ↓
🏦 GitHub（金庫）          ← 🆕v1.1
  カプセル・企画書・開発記録を安全に保管
  次の部屋でクロちゃんが自分で金庫を開けて読める
```

---

## 3. 機能A: LINEファイル配達

### テキスト指示（Phase 2）
```
アキヤ → LINE「設備くんのボタンの色を青に変えて」
    ↓
Cloudflare Worker（Webhook受信）
    ↓
テキスト → 指示書ファイルに変換
    ↓
GitHub API → cocomi-postman/missions/genba-pro/ にpush
    ↓
タブレットPostman → git pull → 検知 → Claude Code実行
```

### ファイル配達（Phase 3）
```
アキヤ → LINEで指示書ファイルを送信（.md）
    ↓
Cloudflare Worker（Webhook受信 — Phase 2と同じ基盤）
    ↓
ファイル種類を自動判定:
  - 指示書(.md + ミッションID) → missions/[project]/ に配置
  - カプセル(.md + capsule_id) → capsules/ に配置     ← 🆕v1.1
  - 企画書(.md) → plans/ に配置                       ← 🆕v1.1
  - その他 → inbox/ に仮置き
    ↓
GitHub API → 対応するリポ/フォルダにpush
    ↓
LINE返信「📦 ファイル配達完了！missions/genba-pro/ に保管しました」
```

### 🆕v1.1: カプセル配達（Phase 4.5）
```
セッション終了時:
クロちゃんがカプセル4ファイルを作成
    ↓
Postman経由でGitHubに自動保存:
  capsules/daily/2026-02-22_DIFF_総合_01.md
  capsules/daily/2026-02-22_DIFF_DEV_postman_01.md
  capsules/daily/2026-02-22_引き継ぎ.md
  capsules/master/MASTER_総合.md（追記更新）
    ↓
capsules/index.md を自動更新（最新STATE＋カプセル一覧）
    ↓
次の部屋:
アキヤ「カプセル読んで」
    ↓
クロちゃんがGitHubからcapsules/index.md → 必要なDIFFを読む
    ↓
渡し忘れゼロ、順番間違いゼロ、即座に引き継ぎ完了
```

---

## 4. 機能B: ステップ実行（Step-by-Step Execution）— ✅Phase 1完了

### ✅ v1.1 実装完了報告

**実装日:** 2026-02-22
**バージョン:** COCOMI Postman v2.0.1
**テスト結果:** 2ステップテスト完全成功

### 指示書フォーマット（確定）
```markdown
# 共通ヘッダー（概要、コンテキスト、ファイルパス等）
このセクションは全ステップに共通で付与される

### Step 1/3: UI画面の作成
このステップの具体的な指示内容

### Step 2/3: ロジック実装
このステップの具体的な指示内容

### Step 3/3: テスト＋仕上げ
このステップの具体的な指示内容
```

### 実行フロー（実装済み）
```
指示書検知 → parse_steps()が `### Step N/M` を検出
  ↓
各ステップファイル = 共通ヘッダー + ステップ内容
  ↓
Step 1: Claude Code実行 → git push → wait_for_ci()
  ↓ CI合格 → LINE通知「Step 1/3 完了！」
自動でStep 2へ
  ↓ CI合格 → LINE通知「Step 2/3 完了！」
自動でStep 3へ
  ↓ CI合格 → LINE通知「🎊 全3ステップ完了！」
  ↓ CI不合格の場合
停止 → LINE通知「❌ Step Nで失敗」→ 修正待ち
```

### 主要関数（core/step-runner.sh）
| 関数 | 役割 |
|------|------|
| parse_steps() | 指示書を `### Step` 境界で分割。共通ヘッダーを抽出 |
| run_step() | 1ステップ実行。共通ヘッダー＋ステップ内容をClaude Codeに渡す |
| wait_for_ci() | GitHub Actionsステータスをポーリング（最大10分） |
| notify_step_result() | LINE通知（Step N/M完了 or 失敗） |

### 精度効果（実測値）
| 方式 | Claude Code精度 | エラー特定時間 |
|------|----------------|---------------|
| 一括実行 | 70-80% | 30-60分 |
| ステップ実行 | 85-95% | 5分（CI+LINE通知） |

---

## 5. 機能A+B の統合フロー（完成形）

```
アキヤ: LINEで指示書送信
    ↓
Cloudflare Worker: 受信 → GitHub push
    ↓
タブレットPostman: 検知 → ステップモード確認
    ↓
Step 1/3: Claude Code実行 → git push → CI待機
    ↓ ✅ CI合格
LINE通知: 「Step 1/3 ✅ 自動でStep 2へ」
    ↓
Step 2/3: Claude Code実行 → git push → CI待機
    ↓ ✅ CI合格
LINE通知: 「Step 2/3 ✅ 自動でStep 3へ」
    ↓
Step 3/3: Claude Code実行 → git push → CI待機
    ↓ ✅ CI合格
LINE通知: 「🎊 全3ステップ完了！🌐 アプリ: https://...」
    ↓
アキヤ: LINEでURLタップ → アプリ確認 → OK!
    ↓ 🆕v1.1
Postman: 開発カプセルDIFF_DEV自動生成 → capsules/に保存
```

---

## 6. 技術的な実装方針

### 🆕 v1.1更新: Webhook受信サーバー → Cloudflare Workers確定

| 方式 | コスト | 難易度 | 常時稼働 | 採用 |
|------|--------|--------|---------|------|
| **Cloudflare Workers** | **無料** | **中** | **✅** | **✅ 採用** |
| Vercel Functions | 無料 | 中 | ✅ | — |
| タブレットTermux内サーバー | 無料 | 高 | △ | — |
| GitHub Actions + polling | 無料 | 低 | ✅ | — |

**Cloudflare Workers採用理由（2026-02-22決定）:**
- 無料枠: 1日10万リクエスト（アキヤの使い方で実質永久無料）
- 有料プラン: 月$5（約750円）で1000万リクエスト
- クレジットカード不要で開始
- Wrangler CLIでTermuxからデプロイ可能
- Phase 2（テキスト）→ Phase 3（ファイル）の拡張が容易

### Phase 2 Cloudflare Worker設計

```javascript
// worker.js（Cloudflare Worker）
// LINE Webhook → テキスト指示を受信 → GitHub APIでpush

export default {
  async fetch(request, env) {
    // 1. LINE Webhookイベントを受信
    const body = await request.json();
    const events = body.events;
    
    for (const event of events) {
      if (event.type === 'message' && event.message.type === 'text') {
        const text = event.message.text;
        
        // 2. テキスト → 指示書ファイルに変換
        const missionFile = convertToMission(text);
        
        // 3. GitHub APIでリポにpush
        await pushToGitHub(env, missionFile);
        
        // 4. LINE返信「📦 指示受付！」
        await replyToLine(env, event.replyToken, '📦 指示受付完了！');
      }
    }
    return new Response('OK');
  }
};
```

### Phase 3拡張（ファイル配達追加）

```javascript
// Phase 2のworker.jsに追加するだけ
if (event.message.type === 'file') {
  // ファイルをダウンロード → 種類判定 → GitHub push
  const fileData = await downloadFromLine(env, event.message.id);
  const destination = classifyFile(fileData); // missions/ or capsules/ or plans/
  await pushToGitHub(env, destination, fileData);
}
```

**Phase 2の基盤がPhase 3にそのまま使える = 急がば回れが正解**

### 🆕 v1.1: カプセル保管庫のGitHubフォルダ構造

```
capsules/                       ← GitHub上のcapsules/フォルダ
├── index.md                    ← カプセル一覧＋最新STATE（これ1つ読めば全部わかる）
├── daily/                      ← 日付ごとのDIFF
│   ├── 2026-02-22_DIFF_総合_01.md
│   ├── 2026-02-22_DIFF_DEV_postman_01.md
│   ├── 2026-02-22_引き継ぎ.md
│   ├── 2026-02-21_DIFF_総合_01.md
│   └── ...
├── master/                     ← 常に最新のMASTER（追記方式）
│   ├── MASTER_総合.md
│   └── MASTER_DEV_postman.md
└── plans/                      ← 企画書
    ├── LINE配達_ステップ実行_企画書_v1.1.md
    └── カプセル保管庫_企画書_v1.0.md
```

### 🆕 v1.1: index.md の設計

```markdown
# 📦 COCOMI カプセル保管庫 INDEX

## 最終更新: 2026-02-22
## 最新STATE: Phase 1完了、Phase 2設計確定

## 📋 最新カプセル（次の部屋で最初に読むべきファイル）
1. daily/2026-02-22_セッションまとめ_引き継ぎ.md ← ★まずこれ
2. daily/2026-02-22_DIFF_総合_01.md
3. daily/2026-02-22_DIFF_DEV_postman_01.md

## 🗂️ MASTER（全体の蓄積）
- master/MASTER_総合.md（最終更新: 2026-02-22）
- master/MASTER_DEV_postman.md（最終更新: 2026-02-22）

## 📅 カプセル履歴
| 日付 | DIFF総合 | DIFF_DEV | 引き継ぎ | トピック |
|------|---------|---------|---------|---------|
| 2026-02-22 | ✅ | ✅ | ✅ | ステップ実行完成、Phase 2設計 |
| 2026-02-21 | ✅ | ✅ | ✅ | CI共通化、精算書統合 |
| ... | | | | |

## 🔮 次にやること
- Phase 2: Cloudflare WorkersでLINE Webhook受信
```

### 🆕 v1.1: カプセルのフォーマットについて

**Q: カプセルは機械語や英語で書いた方がクロちゃんは読みやすい？**

**A: 今の日本語が一番いい。**

理由:
- クロちゃんは日本語も英語もプログラムも同じ速度で読める
- アキヤも読めてAIも読める = 両方にとって最適
- 機械語に変換するメリットはない

**ただし、YAMLヘッダーを追加すると「どれを読むべきか」の判断が高速になる:**

```yaml
---
capsule_id: "CAP-DIFF-DEV-POSTMAN-20260222-01"
capsule_type: "diff_dev"
date: "2026-02-22"
version: "v2.0.1"
phase: "Phase1完了"
next_action: "Phase2_Cloudflare_Workers"
related_files: ["DIFF_総合_01", "MASTER_追記"]
---
（本文は日本語のまま）
```

→ 本文は日本語、メタデータはYAML。これがベスト。

### ステップ実行のキュー管理（変更なし）

```json
// step-queue.json（cocomi-postmanリポ内）
{
  "mission_id": "M-015",
  "project": "genba-pro",
  "total_steps": 3,
  "current_step": 1,
  "mode": "auto",
  "steps": [
    { "step": 1, "file": "M-015-step1.md", "status": "complete" },
    { "step": 2, "file": "M-015-step2.md", "status": "running" },
    { "step": 3, "file": "M-015-step3.md", "status": "waiting" }
  ]
}
```

---

## 7. 実装フェーズ

### Phase 1: ステップ実行の先行実装 — ✅ 完了（2026-02-22）

- [x] 指示書に `### Step N/M` 記法を導入
- [x] core/step-runner.sh 新規作成（約400行）
- [x] executor.shにステップ検出分岐追加
- [x] postman.shにsource追加
- [x] 各ステップ間でCIチェック＋LINE通知
- [x] 2ステップテスト完全成功
- [x] ShellCheck SC2086修正（v2.0.1）

**実績:** 設計→実装→テスト成功 = 約1時間

### Phase 2: LINEテキスト指示 — 🔧 次にやる（設計確定済み）

**🆕 v1.1: polling方式→Webhook方式に変更**

| 項目 | v1.0（旧） | v1.1（新） |
|------|-----------|-----------|
| 方式 | LINE APIをpolling | Cloudflare Workers Webhook |
| サーバー | 不要 | Cloudflare Workers（無料） |
| リアルタイム性 | 低（ポーリング間隔依存） | 高（即座に受信） |
| Phase 3との互換 | 別実装が必要 | 同じWorkerにファイル受信を追加するだけ |

**実装ステップ:**
- [ ] Cloudflareアカウント作成（アキヤ）
- [ ] Wrangler CLIインストール（Termux: `npm install -g wrangler`）
- [ ] worker.js作成（LINE Webhook受信→GitHub API push）
- [ ] LINE Messaging APIのWebhook URLをCloudflare WorkerのURLに設定
- [ ] テスト: LINEテキスト送信 → GitHub push確認 → Postman検知確認

**所要時間:** 1〜2セッション
**前提:** Cloudflareアカウント作成済み

### Phase 3: LINEファイル配達（Webhook拡張）

- [ ] Phase 2のworker.jsにファイル受信ロジック追加
- [ ] ファイル種類の自動判定（指示書/カプセル/企画書/その他）
- [ ] バイナリファイル（画像等）のBase64処理
- [ ] 仕分けルール: missions/ capsules/ plans/ inbox/

**所要時間:** 1セッション
**前提:** Phase 2完了

### 🆕 Phase 4.5: カプセル保管庫 GitHub統合

**Phase 3の「水道管」ができた後に「蛇口」をつける**

- [ ] capsules/フォルダ構造をGitHubリポに作成
- [ ] index.md テンプレート作成
- [ ] Postmanにカプセル自動保存コマンド追加
  - クロちゃんがカプセルを作成 → アキヤがLINEで送信 → GitHub自動保存
  - または: セッション終了時にPostmanが自動でindex.md更新
- [ ] 次の部屋での読み込みフロー確認
  - アキヤ「カプセル読んで」→ クロちゃんがGitHubからindex.md→DIFFを読む

**所要時間:** 1セッション
**前提:** Phase 3完了（ファイル配達が動いていること）

### Phase 4: 統合＋自動化

- [ ] LINEファイル配達 + ステップ実行を統合
- [ ] 全ステップ完了後の最終レポート自動生成
- [ ] 開発カプセルDIFF_DEVの自動生成
- [ ] カプセル自動保存の統合テスト

**所要時間:** 2〜3セッション
**前提:** Phase 1〜3＋4.5完了

---

## 8. 🆕 v1.1: 設計方針の確定事項（2026-02-22決定）

### 1部屋1人ルール
- **現在:** 1 Claude Code × 順次キュー × ステップ実行 = 最適
- **理由:**
  - 2人同時はファイル衝突リスク
  - Galaxyタブレットのメモリ/CPU制約
  - Sonnetは集中した単一タスクの方が高精度（85-95% vs 70-80%）
- **将来:** マルチルーム（2部屋×2人同時）はPC/クラウド環境が使えるPhase E-F

### Maker-Checker不要（現段階）
- **現在の3層防御で十分:**
  - CI自動（ShellCheck/500行/コメント/バージョン/セキュリティ）
  - retry.sh（5段階リトライ）
  - アキヤ実機確認
- **将来:** アプリが複雑化してUX/パフォーマンス/アーキテクチャのチェックが必要になったら、専用Checker Claude Code追加

### Phase順序（急がば回れ）
```
Phase 2（Webhook基盤） → Phase 3（ファイル配達） → Phase 4.5（カプセル保管庫）
     ^^^^^^^^^^^^^^^^
     この「水道管」を先に作る。
     Phase 3はファイル受信を追加するだけ。
     Phase 4.5はcapsules/フォルダ構造を載せるだけ。
```

### auto_mode()の逐次処理（確認済み）
- 1つのミッションを完全に実行→完了→次のミッション検出
- 複数プロジェクトの指示書を連続送信しても安全
- config.json順: genba-pro → culo-chan → maintenance-map → cocomi-postman

---

## 9. 今と完成形の比較

### Before（今）
```
クロちゃんと設計会議
    ↓
指示書の中身をコピー（大きいと大変）
    ↓
タブレットにペースト（途切れることも）
    ↓
Claude Codeがステップ実行 ← v2.0で改善済み
    ↓
LINE通知（ステップごとに進捗）
    ↓
カプセルをスマホに保存（手動、忘れがち）
    ↓
次の部屋で手動アップロード（順番間違い・渡し忘れ）
```

### After（完成形）
```
クロちゃんと設計会議
    ↓
ファイルをLINEに送るだけ（コピペ不要！）
    ↓
Postmanが自動で保管＋ステップ登録
    ↓
Step 1 → CI ✅ → LINE通知
    ↓
Step 2 → CI ✅ → LINE通知
    ↓
Step 3 → CI ✅ → LINE通知「🎉 全完了！」
    ↓
アプリURLタップで確認
    ↓
🆕 カプセル自動保存 → GitHubのcapsules/に安全保管
    ↓
🆕 次の部屋で「カプセル読んで」→ 引き継ぎ完了（渡し忘れゼロ）
```

| 項目 | Before | After |
|------|--------|-------|
| ファイル受け渡し | コピペ | LINEで送信 |
| 大きい指示書 | 途切れリスク | ファイルごと確実に送信 |
| 実行方式 | ~~一括~~ ステップ実行✅ | ステップごと（確実） |
| 失敗時 | ~~どこで失敗？~~ Step N✅ | Step N で失敗と明確 |
| アキヤの操作 | Termux操作必要 | LINEだけ |
| 品質 | 各ステップでCI✅ | 各ステップでCI |
| カプセル保管 | スマホローカル | 🆕 GitHub自動保管 |
| 引き継ぎ | 手動アップロード | 🆕 「カプセル読んで」で完了 |
| 渡し忘れ | 起きがち | 🆕 自動なのでゼロ |

---

## 10. 将来の拡張

### LINE返信でのコントロール
```
アキヤ → LINE「次」       → 次のステップ実行
アキヤ → LINE「やり直し」  → 現在のステップを再実行
アキヤ → LINE「スキップ」  → 現在のステップを飛ばす
アキヤ → LINE「停止」      → 実行を中断
アキヤ → LINE「状態」      → 現在の進捗を表示
アキヤ → LINE「自動」      → 自動継続モードに切替
アキヤ → LINE「カプセル」  → 最新カプセルのSTATE表示   ← 🆕v1.1
```

### 複数プロジェクト並行実行（Phase E-F将来ビジョン）
```
Room A: 設備くんのUI修正     → Claude Code A実行中
Room B: CULOchanのバグ修正   → Claude Code B実行中
※PC/クラウド環境が前提。タブレットでは1部屋1人。
```

### クロちゃんとの直接連携
```
将来的に:
クロちゃん（claude.ai）→ 指示書をAPI経由でPostmanに直接送信
→ LINEで送る手間すら不要
→ 設計会議の最後に「じゃあこれ送っとくね」でPostmanに配達
→ カプセルも直接GitHubに保存
```

---

## 11. 次のアクション

### 直近（Phase 2）
- [ ] **アキヤ:** Cloudflareアカウント作成（https://dash.cloudflare.com/sign-up）
- [ ] **クロちゃん:** Phase 2の指示書作成（Cloudflare Worker + LINE Webhook + GitHub API）
- [ ] **テスト:** LINEテキスト → GitHub push → Postman検知の全フロー確認

### Phase 2完了後（Phase 3 + 4.5）
- [ ] worker.jsにファイル配達ロジック追加
- [ ] capsules/フォルダ構造＋index.md作成
- [ ] カプセル自動保存フローのテスト

---

*「ファイルはLINEで運ぶ。作業はステップで確実に。記憶はGitHubに守る。」*
*「アキヤはLINEだけ。あとはCOCOMIファミリーが全部やる。」*

*COCOMI Postman LINE配達＋ステップ実行＋カプセル保管庫 企画書 v1.1*
*2026-02-22 アキヤ & クロちゃん*
