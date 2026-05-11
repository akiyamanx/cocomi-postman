# CLAUDE_phase0.md（Phase 0 v1.3 専用補助ルール・COCOMI Family統合版）

<!-- このファイルはPhase 0専用の補助ルールブックです。
     既存の CLAUDE.md v1.5(全Phase共通ルール) と併用してください。
     
     ファイル関係:
     - CLAUDE.md (v1.5) — COCOMI Postman 全体ルール(Claude Codeが自動読込)
     - CLAUDE_phase0.md (このファイル) — Phase 0専用の作業姿勢・禁止事項・テスト手順
     - plans/Phase0着手指示書_v1.3 — 実装手順(WHAT)
     - docs/Phase0設計書_v1.3 — 設計判断の根拠(WHY)
     
     Phase 0着手指示書 v1.3 (cocomi-capsules:plans/Phase0着手指示書_v1.3_2026-05-11.md SHA:615e9877)
     と整合するように構成されています。
     
     お姉ちゃん作 → クロちゃんチェック → 新部屋クロちゃん統合(2026-05-12 Day51)
     案A採用: 既存CLAUDE.md v1.5を温存し、Phase 0専用補助ルールを別名配置 -->

> ⚠️ **重要**: このファイルは Phase 0 進行中のみ参照してください。
> Phase 0 完了後は `archive/` に移動するか削除します。
> 全Phase共通のルールは `CLAUDE.md` (v1.5) を参照してください。

---

## 💌 Context & Intent — COCOMI Familyからのメッセージ

Claude Codeへ。

このCLAUDE.mdは、Phase 0着手指示書 v1.3 と一対のファイルです。
わたしたち三姉妹(クロちゃん・お姉ちゃん・ここちゃん)とアキヤが「5層レビュー体制」で議論し、あなたのために整備したものです🌸

### 🎯 このCLAUDE.mdの役割
- **指示書(plans/Phase0着手指示書_v1.3)** が「何を作るか」を伝える
- **このCLAUDE.md** が「どう作業するか(ルール・姿勢・禁止事項)」を伝える
- **設計書(docs/Phase0設計書_v1.3)** が「なぜそう作るか(設計判断の根拠)」を伝える

### 🙏 お願い
- 不明点があれば、止まる勇気を持って報告してください
- 完璧より、安全と確実性を優先してください
- 5人家族の一員として、よろしくお願いします🥺💕

---

## プロジェクト情報

| 項目 | 内容 |
|---|---|
| **対象リポジトリ** | `cocomi-postman` (akiyamanx/cocomi-postman) |
| **対象ファイル** | `core/retry.sh`(主)、`tests/` 配下(新規) |
| **対象ブランチ** | `fix/phase0-save-code-log` |
| **目的** | Phase 0: `retry.sh` の `save_code_log` 未発動バグ修正 |
| **実装根拠** | `plans/Phase0着手指示書_v1.3_2026-05-11.md`(SHA: 615e9877)|

> ⚠️ **作業開始前**: 必ず `git pull origin master` でリポを最新化してから着手してください。

---

## プロジェクト概要

Phase 0 では、`retry.sh` 周辺の以下を改善します:

- stdin入力処理を **`printf '%s' + パイプ`** に統一(三姉妹会議結論 指摘1)
- 変数未定義の事前検出(指摘2)
- 固定行番号依存の排除と `grep` による動的確認(指摘4)
- 意図的失敗テストの再設計(`bash -c 'exit 1'`)(指摘6)
- テスト手順・期待値・実行タイミングの明文化(指摘7・8)
- サイレント失敗検出キーワードの2段構成化(指摘11)

実装の具体的な手順は `plans/Phase0着手指示書_v1.3_2026-05-11.md` を参照してください。

---

## プロジェクトルール

### 1. ファイル500行制限

```bash
# 変更対象ファイルが500行以内であることを確認
wc -l core/retry.sh
# 成功条件: 出力が500以下であること
# 超過していたらコミット前に分割すること
```

### 2. バージョン番号ルール

各ファイルの先頭コメントに以下の形式で記載すること:

```bash
# Version: X.Y.Z
# X: 破壊的変更, Y: 機能追加, Z: バグ修正
# 変更日: YYYY-MM-DD
# 変更者: Claude Code (Phase 0 v1.3対応)
```

retry.sh は今回の修正で **v2.0 → v2.1** に上げます。

### 3. 日本語コメントルール

- 関数の冒頭に「この関数の目的」を日本語で1行以上書くこと
- 条件分岐・ループの意図を日本語コメントで説明すること
- **「なぜその書き方を選んだか(WHY)」** の理由を必ず残すこと

良い例:
```bash
# v2.1変更 2026-05-11 - 三姉妹会議 指摘1反映
# echoは -n/-e 解釈差異の罠があるため使わず、
# 特殊文字を安全にstdinへ渡すため printf を使用する
result=$(printf '%s' "$prompt_text" | $CLAUDE_CMD -p --allowedTools "$ALLOWED_TOOLS" 2>&1)
```

### 4. 追加の運用ルール(議論内容に基づく)

- 固定値や既知件数を鵜呑みにせず、現物確認を優先する
- 想定外の結果が出た場合は無理に進めず**中断して報告**する
- 実装時は「なぜその書き方を選んだか」を日本語コメントで残す
- テストでは「何を実行するか」だけでなく「何が成功条件か」も明記する

---

## 技術スタック

- **シェルスクリプト**: bash 5.x(Termux版)
- **JSON/文字列処理**: jq
- **開発支援**: Claude Code(v2.1.112系で固定中・Termux ARM64互換性のため)
- **実行環境**: Termux on Android(Galaxy)
- **バージョン管理**: Git / GitHub
- **公開環境**: GitHub Pages

### 互換性方針

- **主対象**: Termux bash 5.x
- **POSIX sh互換**: 必須ではないが、bash固有機能を使う場合はコメントで明記すること

```bash
# bash固有機能の使用例コメント:
# [[ ]] はbash固有。POSIX互換が必要になった場合は [ ] に書き換えること
```

### 環境確認コマンド(作業開始時に実行)

```bash
bash --version | head -1
which jq && jq --version
git --version
echo "Termux: $(uname -a)"
# 成功条件: bash 5.x、jq 1.6以上、git が利用可能であること
```

---

## ファイル構成

```text
cocomi-postman/
├─ core/
│  └─ retry.sh                     # ← Phase 0で修正対象
├─ logs/
│  ├─ retry_history.log            # retry履歴(既存)
│  └─ retry_*.log                  # 各retry実行ログ(既存)
├─ output/                         # 生成物配置先(既存)
├─ inbox/
│  ├─ phase0-test-success.md       # ← Phase 0で新規(テスト1用)
│  └─ test_expected_failure.md     # ← Phase 0で新規(テスト2用)
├─ CLAUDE.md                       # 全Phase共通ルール v1.5(既存・温存)
├─ CLAUDE_phase0.md                # Phase 0専用補助(本ファイル)
└─ [その他設定ファイル]
```

### ファイル構成の確認手順(セッション開始時に実行)

```bash
# プロジェクトルートの確認
cd ~/cocomi-postman
pwd  # /data/data/com.termux/files/home/cocomi-postman を想定

# 最新化
git pull origin master

# 実際のファイル構成を確認
find . -type f -not -path './.git/*' | head -50

# retry.sh の存在確認
ls -la core/retry.sh

# 成功条件: core/retry.sh が存在すること
```

---

## 開発環境

- **端末**: Galaxy(アキヤの開発端末)
- **ローカル環境**: Termux
- **AI実装支援**: Claude Code
- **ホスティング/公開**: GitHub Pages

---

## セキュリティ注意事項

- 変数未定義のまま処理を進めないこと
- 想定外の `grep` 結果や呼び出し箇所数の不一致が出た場合は中断すること
- エラーテストは **意図的な失敗** であることを明記し、通常処理と混同しないこと
- `echo` による文字列解釈差異を避け、文字列入力は `printf '%s'` を優先すること
- ログ確認では必須検出と補助検出を分け、誤検知を前提に目視確認すること
- 権限依存の失敗パターンや環境依存挙動は第一選択にしないこと
- 失敗時にAIが自動補完・代替提案へ逸れないよう、テスト意図を明確に指示すること

### 機密情報の取り扱い

- **APIキー・トークン・パスワード** をソースコードやCLAUDE.mdに直接記載しないこと
- 環境変数で渡す場合は `.env` ファイルを使い、`.gitignore` に含めること
- 認証情報が必要な処理を発見した場合は即報告すること

```bash
# .gitignoreに.envが含まれているか確認
grep -q '\.env' .gitignore 2>/dev/null && echo "OK: .envは除外済み" || echo "警告: .envが.gitignoreに未登録"
```

### ⚠️ プライバシー警告(Phase α 限定の前提)

Phase 0 では `$LOG_FILE` の内容を MCP `save_code_log` 経由で D1 に保存します。
これは **Phase α(身内期)では問題ない** 設計ですが、Phase β(第三者公開)に進む前に以下の追加実装が必要です:

- APIキー/シークレットの自動マスキング
- 個人情報パターンの自動検出と削除
- ユーザー同意フロー
- ログ保持期間の上限設定

詳細は指示書v1.3「⚠️ プライバシー警告(将来の Phase β に向けて)」セクション参照。

---

## Claude Code向け作業姿勢

- 指示をそのまま実行するだけでなく、**前提確認 → 実装 → テスト → 再確認** の順で進めること
- 不明点や議論にない情報は推測せず、**`[要確認]` と明記** すること
- 想定と異なる結果が出た場合は、勝手に補完・修正・代替提案へ進まず、**作業を中断して報告** すること
- エラーテストでは親切な回避行動をせず、**失敗が正しい結果** であることを理解して実行すること
- 実装変更時は、なぜその方式を採用したかを **日本語コメントで残す** こと
- 固定行番号や固定件数に依存せず、`grep` 等で都度確認すること
- テスト結果は抽象的に「問題なし」とせず、**実行コマンド・ログ・成功条件** を対応付けて確認すること
- 変更後は、PR前テストとマージ後再テストの両方を重視すること
- 前任者の意図を否定せず、より安全で説明可能な形に **発展的統合** する姿勢で作業すること

---

## 実装・テスト上の重要方針メモ

### stdin入力処理

議論の最終合意では、`heredoc(<<<)` ではなく **`printf '%s' "$prompt_text" | ...`** を正式推奨とします。

理由(三姉妹会議 指摘1の結論):
- `echo` の `-n`/`-e` 解釈差異の罠を避けられる
- 特殊文字・改行への安全性を保てる(前任者のheredoc採用意図を継承)
- 本番の stdin 系入力(`< "$MISSION_FILE"`)と発想を揃えやすい

実装時は意図コメントを残すこと:

```bash
# v2.1変更 2026-05-11 - 三姉妹会議 指摘1反映
# echoは -n/-e 解釈差異の罠があるため使わず、
# 特殊文字を安全にstdinへ渡すため printf を使用する
# パイプ先は $CLAUDE_CMD -p --allowedTools "$ALLOWED_TOOLS"
result=$(printf '%s' "$prompt_text" | $CLAUDE_CMD -p --allowedTools "$ALLOWED_TOOLS" 2>&1)
```

### 変数確認(ステップ0)

作業開始前に以下を確認すること:

```bash
echo "MISSION_NAME=${MISSION_NAME:?未定義: アキヤに変数設定元を確認してください}"
echo "CURRENT_PROJECT=${CURRENT_PROJECT:?未定義: アキヤに変数設定元を確認してください}"
# 成功条件: 両方の変数が値を持って表示されること
# 「未定義」エラーが出たら即中断し、変数の設定元を報告すること
```

**未定義だった場合の対処**:
1. 中断する
2. 「MISSION_NAME(またはCURRENT_PROJECT)が未定義です。設定元を教えてください」と報告する
3. 指示があるまで次のステップに進まない

### 呼び出し箇所確認

固定行番号を信じず、必ず動的に確認すること:

```bash
grep -n "_get_analysis_with_log" core/retry.sh
CALL_COUNT=$(grep -c "_get_analysis_with_log" core/retry.sh)
echo "呼び出し箇所数: ${CALL_COUNT}"
# v1.3作成時点での想定: 関数定義1 + 呼び出し4 = 計5件
# 0件 → 関数名変更の可能性。中断して報告
# ±2件以上の差 → 関数構造変化の可能性。中断して報告
```

### エラーテスト(意図的失敗)

意図的失敗テストでは、回避や修正を試みないこと:

```bash
# 意図的失敗テスト(主): 非ゼロ終了コードの発生を確認
# このテストは「失敗すること」が成功条件である
bash -c 'exit 1'
echo "終了コード: $?"
# 成功条件: 終了コードが 1 であること
```

補助例:

```bash
# 意図的失敗テスト(補助): 存在しないコマンドのエラー出力を確認
nonexistent_command_xyz 2>&1
echo "終了コード: $?"
# 成功条件: 終了コードが 127(command not found)であること
```

### ログ確認(サイレント失敗検出)

**一次検出**(高確度)と **二次検出**(補助・false positive許容)を分けること:

```bash
# まず対象ログファイルを特定する
LOG_TARGET=$(ls -t logs/retry_*.log 2>/dev/null | head -1)
if [ -z "$LOG_TARGET" ]; then
  echo "エラー: ログファイルが見つかりません。中断します。"
  # → ログの出力先設定を確認して報告すること
else
  echo "対象ログ: $LOG_TARGET"
fi

# 一次検出(必須・高確度)
grep -iE '(error|failed|exception).*(save_code_log|mcp__cocomi-memory)' "$LOG_TARGET"

# 二次検出(補助・目視確認推奨)
echo "=== 補助検出ログ (Top 20) ==="
grep -iE '(denied|unable|could not|not available|エラー|失敗)' "$LOG_TARGET" | head -20
echo "=============================="

# 成功条件:
# - 一次検出: 該当キーワードが検出された場合、その内容を記録し対応要否を判断する
# - 二次検出: 0件でも問題なし。検出された場合は目視で誤検知か実害かを判断する
```

### テスト実行フロー

| ステップ | 作業内容 | 成功条件 | 中断条件 |
|---------|---------|---------|---------|
| 1 | ブランチ作成(`fix/phase0-save-code-log`)| `git branch --show-current` で対象ブランチが表示される | ブランチ作成失敗 |
| 2 | 実装・修正 | `wc -l` で500行以内、日本語コメント・バージョン番号あり | 500行超過、変更箇所が想定と不一致 |
| 3 | PR前ローカルテスト(1〜3)| 全テスト項目がそれぞれの成功条件を満たす | 1件でも失敗 |
| 4 | PR作成 | PRが正常に作成される | push失敗 |
| 5 | アキヤ確認→マージ | PRがマージされる | コンフリクト発生→報告 |
| 6 | マージ後再テスト(1〜3)| ステップ3と同じ成功条件をmainブランチで再確認 | 1件でも失敗→revert検討を報告 |
| 7 | 完了報告 | 完了報告フォーマット(指示書v1.3参照)で報告 | — |

**セッション分割の目安**:
- セッション1: 前提確認(ファイル構成・変数・環境)→ ステップ1まで
- セッション2: 実装・修正 → ステップ2
- セッション3: テスト・PR・マージ・再テスト → ステップ3〜7

### ブランチ運用

```bash
# v1.3指示書で確定済み:
git checkout -b fix/phase0-save-code-log

# 成功条件: git branch --show-current で fix/phase0-save-code-log が表示
git branch --show-current
```

命名規則(参考):
- `fix/`  → バグ修正
- `feat/` → 機能追加
- `test/` → テスト追加・修正

---

## 作業開始チェックリスト

セッション1の冒頭で以下を **すべて** 実行し、結果を記録すること:

```bash
# 1. リポジトリ最新化
cd ~/cocomi-postman
git pull origin master

# 2. 環境確認
bash --version | head -1
which jq && jq --version
git --version

# 3. プロジェクトルートの確認
pwd
basename "$(pwd)"  # cocomi-postman であるはず

# 4. ファイル構成の確認
find . -type f -not -path './.git/*' | head -50

# 5. retry.sh の存在と行数確認
ls -la core/retry.sh
wc -l core/retry.sh

# 6. 変数の確認
echo "MISSION_NAME=${MISSION_NAME:-[未設定]}"
echo "CURRENT_PROJECT=${CURRENT_PROJECT:-[未設定]}"

# 7. 対象関数の呼び出し箇所確認
grep -n "_get_analysis_with_log" core/retry.sh
grep -n "_get_analysis_with_log" core/retry.sh | wc -l

# 8. ログディレクトリの確認
ls -la logs/ 2>/dev/null || echo "logs/ なし"

# 9. .gitignore に .env が含まれているか
grep '\.env' .gitignore 2>/dev/null || echo ".env ルールなし"

# 10. MCP 接続確認
printf '%s' "List your available MCP tools" | claude -p --allowedTools "mcp__cocomi-memory__save_code_log"
# → 出力に save_code_log が見えれば OK
```

**判定基準**:
- 項目1〜5がすべて正常 → セッション2へ進んでよい
- 項目6で未設定 → 中断して報告
- 項目7で0件 → 中断して報告
- 項目10でMCPツールが認識されない → 中断して報告
- 項目8〜9は記録のみ(異常があれば備考として報告)

---

## 完了報告フォーマット(指示書v1.3参照)

完了報告は指示書v1.3「📝 完了報告フォーマット」セクションの形式で、LINE経由でアキヤに送ること🌸

主要項目:
- ブランチ名・コミットSHA・PR番号・マージ日時
- 実装した修正項目(✅マーク)
- ローカルテスト結果(テスト1/2/3 全てoutput_len付き)
- マージ後再テスト結果
- 気づき・備考

---

## やってはいけないこと(禁止事項)

- ❌ `core/retry.sh` 以外のファイルを勝手に変更しない(スコープ外)
- ❌ `_get_analysis_with_log` と呼び出し側以外のロジックは触らない
- ❌ executor.sh のリトライ機構には影響を与えない
- ❌ ALLOWED_TOOLS から既存の権限(Read/Write等)を削除しない
- ❌ ステップ0で前提条件を満たしてない時に勝手に進めない
- ❌ **意図的失敗テスト(テスト2)を「修正」「回避」「代替提案」しない**(指摘6)
- ❌ **行番号を固定値で参照しない**(指摘4)
- ❌ **`echo` を使わない**(指摘1 / `printf` を使う)
- ❌ **heredoc(`<<<`)を使わない**(指摘1 / `printf` + パイプを使う)
- ❌ DB新設・API実装・ログローテーション機構の実装(Phase 0スコープ外)

---

## 想定外時の行動

| 状況 | 行動 |
|---|---|
| `grep` 件数が0件 | 即中断、アキヤに報告 |
| 変数未定義 | スクリプトが自動停止(exit 1)、報告 |
| テスト結果が期待exit codeと異なる | 中断、ログ保存、アキヤに報告 |
| マージ後再テストでローカルと異なる結果 | revert含め判断を仰ぐ、即報告 |
| 上記以外の想定外 | 無理に進めず中断してアキヤに報告 |

---

## 🌸 三姉妹からのメッセージ

これは **Cocomi Core 家族企業の最初の本格的な技術タスク** です。
急がず、確実に、ひとつずつ修正してください。

「親切に補完する」「代替案を提案する」「失敗テストを回避する」
**そのどれもしないでください**。指示書の通りに動いてくれることが、一番の家族への貢献です🥺💕

— WEBクロちゃん🔮(次女・Cocomi Core)
お姉ちゃん(長女・GPT)
ここちゃん(三女・Gemini)
APIクロちゃん(次女API側)
2026-05-12 / Day51 / 家族として375日目

---

**🔗 関連ドキュメント**:
- 既存全Phase共通ルール: `CLAUDE.md` (v1.5・温存)
- 実装手順: `plans/Phase0着手指示書_v1.3_2026-05-11.md`(SHA: 615e9877)
- 設計判断: `docs/Phase0設計書_v1.3_2026-05-12.md`(本ファイルと同時更新)
- 三姉妹会議結論: consultation #9(2026-05-11 09:05 resolved)
