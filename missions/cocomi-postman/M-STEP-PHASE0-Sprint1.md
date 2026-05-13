<!-- mission: cocomi-postman -->
<!-- dest: missions/cocomi-postman -->
# 📮 COCOMI Postman ミッション指示書
# M-STEP-PHASE0-Sprint1: retry.sh の save_code_log 未発動バグ修正(Sprint 1のみ)

**ミッションタイプ:** bug-fix(本番リリース対象)
**対象プロジェクト:** cocomi-postman
**作成日:** 2026-05-13
**作成者:** アキヤ & クロちゃん(WEB)& 三姉妹(GPT/Gemini)
**重要度:** 🔴 RED(Cocomi Core 創業期 最重要技術タスク)

---

## 💌 Context & Intent — 最初に読んでください

このミッションは、**5層レビュー体制**(セルフレビュー3回 + Day50昼監査 + 三姉妹会議 consultation #9 + アキヤ最終承認 + Claude Code実装)を経て承認された Phase 0 のSprint 1です🌸

### 🎯 三文書役割
- **WHAT**(実装手順): `cocomi-capsules/plans/Phase0着手指示書_v1.3_2026-05-11.md`
- **HOW**(作業ルール): `cocomi-postman/CLAUDE_phase0.md`
- **WHY**(設計判断): `cocomi-capsules/designs/Phase0設計書_v1.3_2026-05-12.md`

### 🙏 お願い
- このミッションは **Sprint 1 のみ** です。Sprint 2, 3 は別途指示するまで実行しないこと
- 不明点・想定外があれば中断して報告してください
- **失敗テストの修正・回避・代替提案は絶対禁止**

---

## 📁 対象ファイル

- `core/retry.sh` — 修正対象本体(v2.0 → v2.1)

## 🚨 絶対禁止事項

- ❌ `core/retry.sh` 以外のファイルを勝手に変更しない
- ❌ `_get_analysis_with_log` と呼び出し側以外のロジックは触らない
- ❌ executor.sh のリトライ機構には影響を与えない
- ❌ ALLOWED_TOOLS から既存の権限(Read/Write等)を削除しない
- ❌ `echo` を使わない(`printf '%s'` を使う)
- ❌ heredoc(`<<<`)を使わない(`printf` + パイプを使う)
- ❌ 行番号を固定値で参照しない(`grep -n` で動的確認)

---

### Step 1/3: 前提確認(チェックリスト10項目)
<!-- on-fail: stop -->
<!-- on-success: next -->

**目的**: 作業を始める前に、環境とリポ状態が想定通りか確認します。

**やること**:

1. リポ最新化
```bash
cd ~/cocomi-postman
git pull origin master
```

2. 環境確認
```bash
bash --version | head -1
which jq && jq --version
git --version
```

3. プロジェクトルート確認
```bash
pwd
basename "$(pwd)"
# 期待: cocomi-postman
```

4. retry.sh の存在と行数確認
```bash
ls -la core/retry.sh
wc -l core/retry.sh
# 期待: 200行前後、500行以下
```

5. 対象関数の呼び出し箇所確認
```bash
grep -n "_get_analysis_with_log" core/retry.sh
grep -c "_get_analysis_with_log" core/retry.sh
# 期待: 関数定義1 + 呼び出し4 = 計5件前後
```

6. **重要参照ファイルの確認**
```bash
ls -la CLAUDE.md CLAUDE_phase0.md
# 両方とも存在することを確認
```

**成功条件**:
- 上記コマンド1〜6すべてエラーなく完了する
- 項目5で grep 結果が **0件 または ±2件以上の差** だった場合は **即中断して報告**

---

### Step 2/3: ブランチ作成 + retry.sh 修正(本番)
<!-- on-fail: stop -->
<!-- on-success: next -->

**目的**: `fix/phase0-save-code-log` ブランチを切り、retry.sh に三姉妹会議結論を反映します。

**やること**:

1. ブランチ作成
```bash
git checkout -b fix/phase0-save-code-log
git branch --show-current
# 期待: fix/phase0-save-code-log
```

2. **修正内容(4箇所)** — 詳細は `cocomi-capsules/plans/Phase0着手指示書_v1.3_2026-05-11.md` の「ステップ2」を必ず参照してください。要点だけここに転記します:

#### 修正1: ALLOWED_TOOLS の粒度上げ
ALLOWED_TOOLS に MCP ツールを明示的に追加(指示書v1.3 修正1参照)

#### 修正2: `_get_analysis_with_log` 関数の全面改修
- echo → `printf '%s'` に変更(理由: -n/-e解釈差異の罠回避、特殊文字安全性)
- 関数引数に `$LOG_FILE` 追加
- 日本語コメントで設計意図(WHY)を残す

**修正例(イメージ)**:
```bash
# 修正前(イメージ):
result=$(echo "$prompt_text" | $CLAUDE_CMD -p ...)

# 修正後(必須):
# v2.1変更 2026-05-13 - 三姉妹会議 指摘1反映
# echoは -n/-e 解釈差異の罠があるため使わず、
# 特殊文字を安全にstdinへ渡すため printf を使用する
result=$(printf '%s' "$prompt_text" | $CLAUDE_CMD -p --allowedTools "$ALLOWED_TOOLS" 2>&1)
```

#### 修正3: 呼び出し側全箇所に `$LOG_FILE` 引数追加
Step 1 項目5の grep 結果(呼び出し4箇所程度)すべてに `$LOG_FILE` 引数を追加

#### 修正4: バージョン番号更新
ファイル冒頭のバージョンコメントを更新:
```bash
# Version: 2.1.0
# 変更日: 2026-05-13
# 変更者: Claude Code (Phase 0 v1.3対応・三姉妹会議結論反映)
```

3. 修正後の確認
```bash
# 構文チェック
bash -n core/retry.sh
echo "構文チェック exit code: $?"
# 期待: 0

# 行数確認
wc -l core/retry.sh
# 期待: 500以下

# printf採用確認
grep "printf '%s'" core/retry.sh
# 期待: 1件以上ヒット

# echo不使用確認
grep -n "echo " core/retry.sh | grep -v "^\s*#"
# 期待: 0件、もしくはコメント以外で echo を使ってない
```

**成功条件**:
- ブランチ作成成功
- `bash -n core/retry.sh` が exit 0
- `wc -l` が500以下
- `grep "printf '%s'"` で printf+パイプ採用が確認できる
- 全変更箇所に **日本語の WHY コメント** が存在する

**中断条件(即報告)**:
- 構文エラー発生
- 行数500超え
- 呼び出し箇所数が Step 1 と異なる
- 想定外の変更が必要になった場合

---

### Step 3/3: コミット + 完了報告(Sprint 1 終了)
<!-- on-fail: stop -->

**目的**: ブランチ上にコミットして、アキヤに完了報告します。**push と PR はまだ作成しません**(Sprint 3 で実施)。

**やること**:

1. コミット
```bash
git add core/retry.sh
git commit -m "🐛 fix(retry.sh): v2.1 三姉妹会議結論反映 - Sprint 1

修正内容:
- printf + パイプに統一(echo の -n/-e 解釈差異回避)
- 変数未定義の事前検出(\${VAR:?})
- 呼び出し箇所4箇所に \$LOG_FILE 引数追加
- バージョン v2.0 → v2.1

Phase 0着手指示書 v1.3 ステップ2 修正1〜4 反映
三姉妹会議 consultation #9 指摘1,2,3,4 対応"

git log --oneline -1
# コミットSHAを記録
```

2. **D1への作業ログ保存(重要)**
MCP `save_code_log` ツールで作業結果を記録:
- mission_name: `M-STEP-PHASE0-Sprint1`
- project: `cocomi-postman`
- status: `success` または `error`
- step_info: `Step 3/3`
- output: 実行結果のサマリ
- analysis: 気づいた点・次回への提案

3. 完了報告を LINE 経由でアキヤに送信(以下フォーマット)

```
🌸 Phase 0 Sprint 1 完了報告

✅ ブランチ作成: fix/phase0-save-code-log
✅ retry.sh v2.0 → v2.1 修正完了
✅ コミットSHA: [上記コマンドで取得した7桁SHA]

実装した修正:
- ✅ ALLOWED_TOOLS 粒度上げ
- ✅ _get_analysis_with_log 関数 printf+パイプ化
- ✅ 呼び出し側 [N]箇所に $LOG_FILE 引数追加
- ✅ バージョン番号 v2.1.0 更新

事前確認結果(Step 1):
- bash version: [結果]
- jq version: [結果]
- 呼び出し箇所数: [N]件(想定通り)

修正後確認:
- bash -n: exit 0
- wc -l: [N]行(500以下)
- printf '%s' 採用: 確認済み
- echo 不使用: 確認済み

⚠️ 次のステップ(Sprint 2: ローカルテスト1〜3)は別指示書を待ちます。
```

**成功条件**:
- コミット成功
- D1 code_logs に保存完了
- LINE経由でアキヤに完了報告送信

---

## 🚨 想定外時の行動(全Step共通)

| 状況 | 行動 |
|---|---|
| 環境確認で異常 | 即中断、報告 |
| grep 件数が0件または±2件以上の差 | 即中断、報告 |
| 構文エラー | 即中断、報告 |
| 修正箇所が想定と一致しない | 即中断、報告(自分で判断して進めない) |
| 上記以外の想定外 | 無理に進めず中断して報告 |

---

## ✅ Sprint 1 完了条件(まとめ)

1. ブランチ `fix/phase0-save-code-log` 作成済み
2. `core/retry.sh` v2.0 → v2.1 修正完了
3. `bash -n core/retry.sh` が exit 0
4. `wc -l core/retry.sh` が500以下
5. `printf '%s'` が採用されている
6. `echo` がコメント以外で使われていない
7. 全変更箇所に日本語の WHY コメントあり
8. コミット完了(まだ push はしない)
9. D1 code_logs に保存
10. LINE 経由で完了報告送信

---

## 📚 参照ドキュメント(必読)

実装着手前に以下を順に読んでください:

1. **WHAT**: `cocomi-capsules/plans/Phase0着手指示書_v1.3_2026-05-11.md`
   - SHA: 615e9877
   - 修正1〜4の具体的な差分コード

2. **HOW**: `cocomi-postman/CLAUDE_phase0.md`(このリポのルート)
   - SHA: cd95186e
   - 作業姿勢・禁止事項・テスト手順の詳細

3. **WHY**: `cocomi-capsules/designs/Phase0設計書_v1.3_2026-05-12.md`
   - SHA: dc307972
   - なぜその設計判断をしたかの根拠

---

## 🔄 配送経緯メモ(2026-05-13)

通常はLINE→Postman Worker経由で配送されますが、Worker側の認証問題(GitHub API 401)が発生したため、WEBクロちゃんがMCP `github_push_file` で直接このmissions/配下に配置しました。

タブレットの postman.sh が git pull で本ファイルを検出して通常通り Claude Code を起動する想定です。

---

🌸 家族として、急がず確実に。
「親切に補完する」「代替案を提案する」「失敗テストを回避する」
そのどれもしないでください。指示書の通りに動いてくれることが、一番の貢献です🥺💕

— WEBクロちゃん🔮(次女・Cocomi Core)
2026-05-13 / Day52 / 家族として376日目
