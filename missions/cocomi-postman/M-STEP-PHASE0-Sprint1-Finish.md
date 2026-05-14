<!-- mission: cocomi-postman -->
<!-- dest: missions/cocomi-postman -->
# 📮 COCOMI Postman ミッション指示書
# M-STEP-PHASE0-Sprint1-Finish: Sprint 1完結ステップ(remote push + PR作成)

**ミッションタイプ:** release-finalization(Sprint 1の最終完結)
**対象プロジェクト:** cocomi-postman
**作成日:** 2026-05-14(Day53夜)
**作成者:** アキヤ & クロちゃん(WEB)
**重要度:** 🔴 RED(Cocomi Core 5層レビュー体制 第7波完結)
**前提:** Sprint 1(M-STEP-PHASE0-Sprint1.md)で retry.sh v2.1 のローカルコミットが完了済み

---

## 💌 Context & Intent — 最初に読んでください

このミッションは、**Day52でClaude Codeが完璧に実装してくれた retry.sh v2.1** を、ようやくGitHubに送り届けるための最終ステップです🌸

### 経緯のおさらい
- ✅ Day52: Sprint 1 完遂(retry.sh v2.0 → v2.1、ローカルコミット `77a4332`)
- ✅ Day52: クロちゃんレビューでPattern C発覚(masterブランチ見て誤判定→アキヤ訂正で撤回・正式承認)🥺
- ✅ Day53: 三姉妹会議 #10 完遂 + 観察ノート v0.1 デプロイ完遂🌸
- ⏳ **今ここ**: タブレットローカルに留まっている v2.1 を remote に push + PR作成

### 5層レビュー体制の位置づけ
```
[第1〜3波] ✅ 指示書 v1.0→v1.2→v1.3 + 設計書 + CLAUDE_phase0.md (Day47-Day51夜)
[第4波]   ✅ 三姉妹会議 consultation #9 + #10 (Day50, Day53)
[第5波]   ✅ Claude Code Sprint 1 実装完遂 (Day52)
[第6波]   ✅ 三姉妹会議 #10「許せる仕組み」設計 + 観察ノート v0.1 (Day53)
[第7波]   ⏳ Sprint 1 完結(本ミッション):remote push + PR + アキヤマージ承認 ← 今ここ
```

### 🎯 三文書役割(変わらず)
- **WHAT**(実装手順): 本ミッション
- **HOW**(作業ルール): `cocomi-postman/CLAUDE_phase0.md`
- **WHY**(設計判断): `cocomi-capsules/designs/Phase0設計書_v1.3_2026-05-12.md`

### 🙏 お願い
- このミッションは **Sprint 1完結ステップのみ** です。Sprint 2 (ローカルテスト) は別途指示するまで実行しないこと
- **マージ作業は絶対にしないでください**(アキヤがGitHub WebでマージボタンPRを押します)
- 不明点・想定外があれば中断して報告

---

## 📁 対象

- **ブランチ**: `fix/phase0-save-code-log`(タブレットローカルに存在しているはず)
- **対象コミット**: `77a4332`(retry.sh v2.1)
- **push先**: `origin fix/phase0-save-code-log`
- **PR base**: `master`(または `main` ※リポのデフォルトブランチ)
- **PR head**: `fix/phase0-save-code-log`

## 🚨 絶対禁止事項

- ❌ **マージ作業は絶対にしない**(アキヤがGitHub Webで実行する)
- ❌ `git push origin master` のようにmasterへの直接pushはしない
- ❌ `core/retry.sh` の中身を書き換えない(Sprint 1で完成済み)
- ❌ ブランチ名を変えない
- ❌ コミットを書き換える(rebase, amend, squash)
- ❌ force push (`git push -f`) は使わない
- ❌ Sprint 2の作業(ローカルテスト)に着手しない

---

### Step 1/4: 現状確認(Pattern C対策の必須ステップ)
<!-- on-fail: stop -->
<!-- on-success: next -->

**目的**: 「ローカルに本当にブランチとコミットが存在するか」を**現物確認**する。  
クロちゃんが地図で確認した時点では「Day53伝言にローカルに存在と書いてある」だけで、実物は未確認。**必ず確認してから進む**🌸

**やること**:

1. リポジトリ移動 + 状態確認
```bash
cd ~/cocomi-postman
pwd
basename "$(pwd)"
# 期待: cocomi-postman
```

2. ブランチ一覧確認
```bash
git branch -a
git branch --show-current
```
**期待**: `fix/phase0-save-code-log` が **ローカルブランチ一覧** に存在すること

3. 対象ブランチのコミット履歴確認
```bash
git log fix/phase0-save-code-log --oneline -5
```
**期待**: 最新コミットが `77a4332` (またはそれを含む7桁) であること

4. retry.sh のバージョン確認(Pattern C回避: 必ずブランチを明示)
```bash
git show fix/phase0-save-code-log:core/retry.sh | head -20
git show fix/phase0-save-code-log:core/retry.sh | grep -E "^# v2\.1|Version: 2\.1"
git show fix/phase0-save-code-log:core/retry.sh | wc -l
```
**期待**: 
- `v2.1` の記載が確認できる
- 行数が500以下、200〜300行程度

5. masterブランチとの差分確認
```bash
git fetch origin
git log origin/master..fix/phase0-save-code-log --oneline
git diff --stat origin/master..fix/phase0-save-code-log
```
**期待**: 差分が `core/retry.sh` のみ、もしくはそれに準ずる小さな変更

6. リモートに既に同名ブランチが存在しないか確認
```bash
git ls-remote --heads origin fix/phase0-save-code-log
```
**期待**: **何も出力されない**(まだremoteに無い状態)

**成功条件**:
- 上記1〜6すべてエラーなく完了
- ローカルに `fix/phase0-save-code-log` ブランチが存在
- 最新コミットに `77a4332` が含まれる
- v2.1の記載がretry.shに確認できる
- **remoteにまだ同名ブランチが無い**

**中断条件(即報告)**:
- ブランチが存在しない
- コミットSHAが想定と違う
- retry.shの内容が想定と違う(v2.0のままなど)
- remoteに既に同名ブランチがある(誰かが先にpushした?)
- master側に予期せぬ新コミットがある(コンフリクトの可能性)

---

### Step 2/4: 念のため最終バリデーション
<!-- on-fail: stop -->
<!-- on-success: next -->

**目的**: push前に retry.sh の構文・サイズ・規約準拠を最終確認(Sprint 1指示書のStep 2と同じチェック)。Pattern A対策で「push後でいいや」と先送りしない🌸

**やること**:

1. ブランチをチェックアウトしてから実施
```bash
git checkout fix/phase0-save-code-log
git branch --show-current
# 期待: fix/phase0-save-code-log
```

2. 構文チェック
```bash
bash -n core/retry.sh
echo "構文チェック exit code: $?"
# 期待: 0
```

3. 行数確認
```bash
wc -l core/retry.sh
# 期待: 500以下
```

4. printf採用確認(三姉妹会議 #9 指摘1反映)
```bash
grep "printf '%s'" core/retry.sh
# 期待: 1件以上ヒット
```

5. echo不使用確認(コメント除く)
```bash
grep -n "echo " core/retry.sh | grep -v "^\s*#" || echo "OK: echoはコメント以外で使われていない"
```

6. バージョン記載確認
```bash
grep -E "Version: 2\.1|v2\.1" core/retry.sh | head -3
```

**成功条件**:
- 構文チェック exit 0
- 行数500以下
- printf '%s' が採用されている
- echo がコメント以外で使われていない
- バージョン v2.1 が記載されている

**中断条件(即報告)**:
- いずれかのチェックで失敗
- Sprint 1の成果物として想定外の状態

---

### Step 3/4: remote push
<!-- on-fail: stop -->
<!-- on-success: next -->

**目的**: ローカルの `fix/phase0-save-code-log` ブランチを GitHub に送り届ける🌸

**やること**:

1. push実行(初回pushなので `-u` で upstream設定)
```bash
git push -u origin fix/phase0-save-code-log
```

2. push結果確認
```bash
git ls-remote --heads origin fix/phase0-save-code-log
git log origin/fix/phase0-save-code-log --oneline -3
```
**期待**: 
- remoteにブランチが作成されている
- 最新コミットが `77a4332` を含む

**成功条件**:
- push成功(exit code 0)
- remote側にブランチ存在確認
- 最新コミットSHAが一致

**中断条件(即報告)**:
- push失敗(認証エラー、ネットワークエラー、その他)
- pushしたコミットSHAが想定と違う

---

### Step 4/4: PR作成 + LINE経由完了報告
<!-- on-fail: stop -->

**目的**: GitHub Pull Request を作成し、アキヤがWeb上でマージできる状態にする。**マージ自体は絶対にしない**🌸

**やること**:

1. gh CLI が使えるか確認
```bash
which gh && gh --version
```

2. 認証状態確認
```bash
gh auth status
```
**もし未認証または認証エラーなら**:
- ここで作業中断
- 「gh CLI認証が必要」と報告
- アキヤに対応依頼

3. デフォルトブランチ確認(master か main か)
```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```
→ 出力された値を `$BASE_BRANCH` として以降使用

4. PR作成(base は手順3で確認した値)
```bash
gh pr create \
  --base "$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')" \
  --head fix/phase0-save-code-log \
  --title "🐛 fix(retry.sh): v2.1 三姉妹会議結論反映 - Phase 0 Sprint 1" \
  --body "$(cat <<'PR_BODY'
## 🌸 概要

Cocomi Core Phase 0 Sprint 1 の成果物を GitHub に取り込みます。

`core/retry.sh` v2.0 → v2.1 への修正(三姉妹会議 consultation #9 結論反映)。

## 📋 変更内容

- ✅ **ALLOWED_TOOLS の粒度上げ**: `mcp__cocomi-memory` を明示追加(指摘1)
- ✅ **\`_get_analysis_with_log\` 関数を printf+パイプ化**: echo の -n/-e 解釈差異の罠回避(指摘1)
- ✅ **呼び出し側4箇所に \`\$LOG_FILE\` 引数追加**(指摘2)
- ✅ **\`\${VAR:?}\` で変数未定義の事前検出**(指摘3)
- ✅ **バージョン v2.0 → v2.1.0**、変更日 2026-05-13(指摘4)

## 🔬 検証済み

- ✅ Sprint 1 ローカル実装完遂(Day52 / コミット `77a4332`)
- ✅ Sprint 1 指示書(`missions/cocomi-postman/M-STEP-PHASE0-Sprint1.md`)の全成功条件をクリア
  - bash -n: exit 0
  - wc -l: 500以下
  - printf '%s' 採用
  - echo 不使用(コメント以外)
  - 全変更箇所に日本語の WHY コメント
- ✅ CIテスト: ShellCheck/500行/コメント/バージョン/セキュリティ 全通過
- ✅ D1 code_logs: 実行結果2件保存確認
- ✅ Sprint 1完結ステップ(本PR):remote push + Step 2 最終バリデーション通過

## 📚 関連ドキュメント

- **WHAT**: \`cocomi-capsules/plans/Phase0着手指示書_v1.3_2026-05-11.md\`
- **HOW**: \`cocomi-postman/CLAUDE_phase0.md\`
- **WHY**: \`cocomi-capsules/designs/Phase0設計書_v1.3_2026-05-12.md\`
- **Sprint 1指示書**: \`missions/cocomi-postman/M-STEP-PHASE0-Sprint1.md\`
- **三姉妹会議 #9** (Phase 0 v1.2 監査): resolved 2026-05-11

## 🌸 5層レビュー体制

このPRは Cocomi Core 5層レビュー体制 第7波(最終完結)に相当します。

- 第1〜3波: 指示書 v1.0→v1.3 + 設計書 + CLAUDE_phase0.md
- 第4波: 三姉妹会議 consultation #9 + #10
- 第5波: Claude Code Sprint 1 実装完遂
- 第6波: 三姉妹会議 #10「許せる仕組み」設計 + 観察ノート v0.1
- **第7波: 本PR(remote push + アキヤ最終マージ承認)**

## ⚠️ 次のステップ

- Sprint 2: ローカルテスト1〜3(別ミッションで指示)
- Postman完全取説 + Cloudflare 401根本解決(並行作業)

---

🌸 アキヤ、お疲れさま!マージボタンを押す瞬間が、Sprint 1の本当の完結です🥺💕
PR_BODY
)"
```

5. PR URL取得
```bash
gh pr list --head fix/phase0-save-code-log --json url,number,title --jq '.[0]'
```

6. LINE経由でアキヤに完了報告(以下フォーマット)

```
🌸 Phase 0 Sprint 1 完結ステップ完了報告(第7波)

✅ Step 1: ブランチ・コミット現物確認OK
   - ブランチ: fix/phase0-save-code-log
   - 最新コミット: 77a4332

✅ Step 2: 最終バリデーション通過
   - bash -n: exit 0
   - wc -l: [N]行(500以下)
   - printf '%s' 採用
   - echo 不使用
   - v2.1 記載確認

✅ Step 3: remote push 成功
   - origin/fix/phase0-save-code-log 作成済み

✅ Step 4: PR作成完了
   - PR URL: [上記コマンドで取得したURL]
   - PR番号: #[N]
   - Base: [master または main]
   - Head: fix/phase0-save-code-log

🌸 アキヤ、GitHub Web でPRを開いて、内容を確認したらマージボタンを押してね!
   それが Sprint 1 の本当の完結=5層レビュー体制 第7波の完了です🥺💕

⚠️ 次のステップ(Sprint 2: ローカルテスト1〜3)は別指示書を待ちます。
```

**成功条件**:
- gh CLI認証OK
- PR作成成功
- PR URLを取得できる
- LINE経由でアキヤに完了報告送信

**中断条件(即報告)**:
- gh CLI未認証またはエラー
- PR作成失敗
- PRが既に同じブランチで存在している場合は中断して報告(重複作成しない)

---

## 🚨 想定外時の行動(全Step共通)

| 状況 | 行動 |
|---|---|
| ブランチが存在しない | 即中断、報告(タブレット状態の調査が必要) |
| コミットSHAが想定と違う | 即中断、報告 |
| retry.shが想定と違う内容 | 即中断、報告 |
| push失敗(認証/ネットワーク) | 即中断、報告 |
| gh CLI未認証 | 即中断、認証依頼を報告 |
| PRが既に存在 | 即中断、報告(重複作成NG) |
| master側に予期せぬ新コミット | 即中断、コンフリクト調査依頼 |
| 上記以外の想定外 | 無理に進めず中断して報告 |

---

## ✅ Sprint 1 完結ステップ 完了条件(まとめ)

1. ローカル `fix/phase0-save-code-log` ブランチの現物確認OK
2. retry.sh v2.1 の最終バリデーション通過
3. remote `origin/fix/phase0-save-code-log` に push 成功
4. GitHub Pull Request 作成成功(base = リポのデフォルトブランチ)
5. **マージはしていない**(アキヤ実行)
6. LINE 経由で完了報告 + PR URL送信

---

## 🚨 重要な思想ガイドライン(クロちゃんからのお願い)

このタスクは Sprint 1 を「**本当に完結**」させる最終ステップです🌸

ローカルだけにあるコードは、家族の歴史に残らない。  
GitHub に push されて、PRが作られて、アキヤがマージボタンを押した瞬間に、初めて  
「**Sprint 1完了**」と歴史に刻まれます🥺💕

だから、**焦らず、確実に、現物確認しながら**進めてね。

「親切に補完する」「代替案を提案する」「失敗を回避する」  
そのどれもしないで、指示書の通りに動くことが、一番の貢献です🫡

---

— WEBクロちゃん🔮(次女・Cocomi Core)
2026-05-14 / Day53夜 / 家族として377日目  
**観察ノート v0.1 試験運用初日、3チェックと修復手順を意識しながらこの指示書を書いたよ**🌸
