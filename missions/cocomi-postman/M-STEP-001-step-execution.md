# 📮 COCOMI Postman ミッション指示書
# M-STEP-001: ステップ実行機能（Step-by-Step Execution）

**ミッションタイプ:** feature-add
**対象プロジェクト:** cocomi-postman
**優先度:** 高
**作成日:** 2026-02-22
**作成者:** アキヤ & クロちゃん（Claude Opus 4.6）

---

## 📋 ミッション概要

指示書に `### Step N/M` 記法でステップが書かれている場合、
1ステップずつ順番にClaude Codeに渡して実行し、
各ステップ完了後にgit push → GitHub Actions CI → CI結果確認を行い、
CI合格なら自動で次のステップに進む機能を実装する。

**ステップなしの従来の指示書は今まで通り一括実行する（既存動作を壊さない）。**

---

## 📁 対象ファイル

### 新規作成
- `core/step-runner.sh` — ステップ分割パーサー＋順序実行エンジン

### 修正
- `core/executor.sh` — run_single_mission()にステップ判定分岐を追加
- `postman.sh` — step-runner.shのsource読み込みを追加

---

## 🔧 実装内容

### Step 1/3: core/step-runner.sh（新規作成）

#### ファイル先頭コメント
```bash
#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162
# このファイルは: COCOMI Postman ステップ実行エンジン
# 指示書の ### Step N/M 記法を認識し、1ステップずつ順番に実行する
# 各ステップ完了後にgit push→CI確認→CI合格で自動的に次のステップへ
# v2.0 追加 2026-02-22 - Phase E: Step-by-Step Execution
```

#### 関数①: has_steps()
**役割:** 指示書にステップ記法があるか判定する
**引数:** $1 = 指示書ファイルパス
**戻り値:** 0 = ステップあり, 1 = ステップなし

```bash
has_steps() {
    local mission_file="$1"
    # ### Step で始まる行が2つ以上あればステップ付き指示書
    local step_count
    step_count=$(grep -c "^### Step [0-9]" "$mission_file" 2>/dev/null || echo "0")
    if [ "$step_count" -ge 2 ]; then
        return 0
    fi
    return 1
}
```

#### 関数②: parse_steps()
**役割:** 指示書を ### Step N/M の区切りでステップごとのファイルに分割する
**引数:** $1 = 指示書ファイルパス, $2 = 一時ディレクトリパス（分割ファイル出力先）
**出力:** 一時ディレクトリに step-1.md, step-2.md, ... を生成
**戻り値:** ステップ数（標準出力にecho）

処理内容:
1. 指示書の先頭から最初の `### Step` の直前までを「共通ヘッダー」として抽出
2. 各 `### Step N/M` から次の `### Step` の直前まで（または末尾まで）を切り出す
3. 各ステップファイルに「共通ヘッダー ＋ そのステップの内容」を結合して保存

```bash
parse_steps() {
    local mission_file="$1"
    local temp_dir="$2"
    mkdir -p "$temp_dir"

    # 共通ヘッダー（最初の ### Step より前の部分）を抽出
    local first_step_line
    first_step_line=$(grep -n "^### Step [0-9]" "$mission_file" | head -1 | cut -d: -f1)

    local header=""
    if [ -n "$first_step_line" ] && [ "$first_step_line" -gt 1 ]; then
        header=$(head -$((first_step_line - 1)) "$mission_file")
    fi

    # ステップの開始行番号を全て取得
    local step_lines=()
    while IFS= read -r line_info; do
        step_lines+=("$(echo "$line_info" | cut -d: -f1)")
    done < <(grep -n "^### Step [0-9]" "$mission_file")

    local total_steps=${#step_lines[@]}
    local total_lines
    total_lines=$(wc -l < "$mission_file")

    # 各ステップを分割してファイルに保存
    local i
    for i in $(seq 0 $((total_steps - 1))); do
        local start=${step_lines[$i]}
        local end
        if [ $i -lt $((total_steps - 1)) ]; then
            end=$((step_lines[$((i + 1))] - 1))
        else
            end=$total_lines
        fi

        local step_num=$((i + 1))
        local step_file="$temp_dir/step-${step_num}.md"

        # 共通ヘッダー + このステップの内容
        {
            if [ -n "$header" ]; then
                echo "$header"
                echo ""
                echo "---"
                echo ""
            fi
            sed -n "${start},${end}p" "$mission_file"
        } > "$step_file"
    done

    echo "$total_steps"
}
```

#### 関数③: wait_for_ci()
**役割:** git push後にGitHub Actions CIの結果を待つ
**引数:** $1 = プロジェクトのリポジトリパス
**戻り値:** 0 = CI合格, 1 = CI不合格 or タイムアウト

処理内容:
1. git pushした直後に呼ばれる
2. 一定間隔（30秒）でGitHub Actionsの最新のワークフロー実行結果を確認
3. 最大10分（20回×30秒）待つ
4. 結果が "completed" + "success" なら0を返す
5. 結果が "completed" + "failure" なら1を返す
6. タイムアウトした場合は1を返す（安全側に倒す）

```bash
wait_for_ci() {
    local repo_path="$1"
    cd "$repo_path" || return 1

    # リモートURLからリポ名を取得（HTTPS/SSH両対応）
    local repo_url
    repo_url=$(git remote get-url origin)
    local repo_name
    repo_name=$(echo "$repo_url" | sed -E 's|.*github\.com[:/]||; s|\.git$||')

    if [ -z "$repo_name" ]; then
        echo -e "  ${RED}⚠️ リポジトリ名を取得できません${NC}"
        return 1
    fi

    echo -e "  ${YELLOW}⏳ CI結果を待機中... (最大10分)${NC}"

    local max_attempts=20
    local wait_interval=30
    local attempt=0

    # push直後のCI起動を待つため最初に15秒待機
    sleep 15

    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))

        # gh CLIでワークフロー実行結果を取得
        # 最新の実行のstatusとconclusionを取得
        local run_info
        run_info=$(gh run list --repo "$repo_name" --limit 1 --json status,conclusion 2>/dev/null)

        if [ -n "$run_info" ]; then
            local status
            status=$(echo "$run_info" | grep -o '"status":"[^"]*"' | head -1 | sed 's/"status":"//;s/"//')
            local conclusion
            conclusion=$(echo "$run_info" | grep -o '"conclusion":"[^"]*"' | head -1 | sed 's/"conclusion":"//;s/"//')

            if [ "$status" = "completed" ]; then
                if [ "$conclusion" = "success" ]; then
                    echo -e "  ${GREEN}✅ CI合格！${NC}"
                    return 0
                else
                    echo -e "  ${RED}❌ CI不合格（conclusion: ${conclusion}）${NC}"
                    return 1
                fi
            fi
        fi

        echo -e "  ${YELLOW}  ⏳ CI実行中... (${attempt}/${max_attempts})${NC}"
        sleep $wait_interval
    done

    echo -e "  ${RED}⚠️ CIタイムアウト（10分経過）${NC}"
    return 1
}
```

**注意:** `gh` (GitHub CLI) コマンドが必要。Termuxでインストール済みの前提（cocomi-repo-setup.shで使っているので入っているはず）。
もし `gh` がない場合はCI待機をスキップして成功扱いにするフォールバック処理を入れること：

```bash
# ghコマンドの存在チェック（wait_for_ciの先頭に追加）
if ! command -v gh &> /dev/null; then
    echo -e "  ${YELLOW}⚠️ gh CLIなし。CI確認をスキップします${NC}"
    return 0
fi
```

#### 関数④: run_step_mission()
**役割:** ステップ付き指示書を1ステップずつ順番に実行するメイン関数
**引数:** $1 = 指示書ファイルパス, $2 = ミッション名
**この関数はexecutor.shのrun_single_mission()から呼ばれる**

処理フロー:
```
① 指示書をparse_steps()でステップ分割
② Step 1のファイルをrun_with_retry()で実行（retry.shの既存関数）
③ 完了 → git_push_project()でgit push
④ wait_for_ci()でCI結果を待つ
⑤ CI合格 → LINE通知「✅ Step 1/3 完了」
⑥ 自動でStep 2へ（②に戻る）
⑦ CI不合格 → LINE通知「❌ Step 2/3 CI不合格」→ 停止
⑧ 全ステップ完了 → LINE通知「🎉 全3ステップ完了！」
⑨ 最終レポート生成
```

```bash
run_step_mission() {
    local MISSION_FILE="$1"
    local MISSION_NAME="$2"
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local LOG_FILE
    LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}-steps.log"

    mkdir -p "$REPORT_DIR" "$POSTMAN_DIR/logs/execution"

    {
        echo "=== ステップ実行ログ ==="
        echo "開始: $(date)"
        echo "プロジェクト: $CURRENT_PROJECT_NAME"
        echo "ミッション: $MISSION_NAME"
    } > "$LOG_FILE"

    # ① ステップ分割
    local TEMP_DIR="$POSTMAN_DIR/.step-temp/${MISSION_NAME}"
    rm -rf "$TEMP_DIR"
    local TOTAL_STEPS
    TOTAL_STEPS=$(parse_steps "$MISSION_FILE" "$TEMP_DIR")

    echo -e "  ${CYAN}📋 ${TOTAL_STEPS}ステップに分割しました${NC}"
    echo "ステップ数: $TOTAL_STEPS" >> "$LOG_FILE"

    # ② ステップを順番に実行
    local step_num
    local all_success=true
    local completed_steps=0

    for step_num in $(seq 1 "$TOTAL_STEPS"); do
        local step_file="$TEMP_DIR/step-${step_num}.md"

        echo ""
        echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${BOLD}📌 Step ${step_num}/${TOTAL_STEPS} 実行中...${NC}"
        echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "--- Step ${step_num}/${TOTAL_STEPS} 開始: $(date) ---" >> "$LOG_FILE"

        # プロジェクトを最新に
        if [ -n "$CURRENT_REPO_PATH" ] && [ -d "$CURRENT_REPO_PATH" ]; then
            cd "$CURRENT_REPO_PATH" || break
            git pull origin main > /dev/null 2>&1
        else
            echo -e "  ${RED}❌ リポジトリが見つからない: $CURRENT_REPO_PATH${NC}"
            all_success=false
            break
        fi

        # retry.sh経由でClaude Code実行
        # shellcheck source=core/retry.sh
        source "$POSTMAN_DIR/core/retry.sh"
        run_with_retry "$step_file" "${MISSION_NAME}-step${step_num}" "$LOG_FILE" "$CURRENT_REPO_PATH"
        local EXIT_CODE=$?

        if [ $EXIT_CODE -ne 0 ]; then
            echo -e "  ${RED}❌ Step ${step_num}/${TOTAL_STEPS} 実行失敗${NC}"
            echo "--- Step ${step_num} 実行失敗: $(date) ---" >> "$LOG_FILE"

            # LINE通知（ステップ失敗）
            if type notify_mission_result &>/dev/null; then
                notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "error" "Step ${step_num}/${TOTAL_STEPS} 実行失敗（リトライ${RETRY_COUNT}回）"
            fi

            all_success=false
            break
        fi

        echo -e "  ${GREEN}✅ Step ${step_num}/${TOTAL_STEPS} Claude Code完了${NC}"
        echo "--- Step ${step_num} Claude Code完了: $(date) ---" >> "$LOG_FILE"

        # git push
        git_push_project "$CURRENT_REPO_PATH" "📮 ${MISSION_NAME} Step ${step_num}/${TOTAL_STEPS} by COCOMI Postman"

        # CI結果を待つ
        if ! wait_for_ci "$CURRENT_REPO_PATH"; then
            echo -e "  ${RED}❌ Step ${step_num}/${TOTAL_STEPS} CI不合格！停止します${NC}"
            echo "--- Step ${step_num} CI不合格: $(date) ---" >> "$LOG_FILE"

            # LINE通知（CI不合格）
            if type notify_mission_result &>/dev/null; then
                notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "error" "Step ${step_num}/${TOTAL_STEPS} CI不合格！GitHub Actionsを確認してね"
            fi

            all_success=false
            break
        fi

        completed_steps=$step_num
        echo "--- Step ${step_num} CI合格: $(date) ---" >> "$LOG_FILE"

        # LINE通知（ステップ完了、ただし最終ステップは後でまとめて通知）
        if [ "$step_num" -lt "$TOTAL_STEPS" ]; then
            if type send_line_notify &>/dev/null; then
                send_line_notify "📮 COCOMI Postman ステップ進捗

プロジェクト: ${CURRENT_PROJECT_NAME}
ミッション: ${MISSION_NAME}
✅ Step ${step_num}/${TOTAL_STEPS} 完了＆CI合格！
⏭️ 自動でStep $((step_num + 1))/${TOTAL_STEPS} に進みます"
            fi
        fi

        echo -e "  ${GREEN}✅ Step ${step_num}/${TOTAL_STEPS} 完了＆CI合格！→ 次のステップへ${NC}"
    done

    # ⑧ 最終レポート生成
    local REPORT_NAME="R-${MISSION_NAME#M-}"

    if $all_success; then
        echo ""
        echo -e "  ${GREEN}🎉 全${TOTAL_STEPS}ステップ完了！${NC}"
        echo "--- 全ステップ完了: $(date) ---" >> "$LOG_FILE"

        cat > "$REPORT_DIR/${REPORT_NAME}.md" << EOF
# ✅ Mission Report: ${MISSION_NAME}（ステップ実行）

## 📱 アキヤ向けサマリー（日本語）
- **状態:** ✅ 全${TOTAL_STEPS}ステップ完了
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **完了日時:** $(date '+%Y-%m-%d %H:%M')
- **完了ステップ:** ${completed_steps}/${TOTAL_STEPS}

---

## 🤖 AI Work Summary (for Claude/Gemini/GPT)

### Execution Context
- **Mission:** ${MISSION_NAME}
- **Project:** ${CURRENT_PROJECT_NAME}
- **Total steps:** ${TOTAL_STEPS}
- **Completed steps:** ${completed_steps}/${TOTAL_STEPS}
- **Execution mode:** step-by-step with CI gate
- **Timestamp:** $(date '+%Y-%m-%dT%H:%M:%S')

### Step Results
All ${TOTAL_STEPS} steps completed successfully with CI passing.
EOF

        # LINE通知（全ステップ完了）
        if type notify_mission_result &>/dev/null; then
            notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "success" "🎉 全${TOTAL_STEPS}ステップ完了！"
        fi
    else
        echo "--- ステップ実行中断: $(date) ---" >> "$LOG_FILE"

        # エラーレポート生成
        mkdir -p "$POSTMAN_DIR/errors/$CURRENT_PROJECT"
        cat > "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${MISSION_NAME#M-}.md" << EOF
# ❌ Error Report: ${MISSION_NAME}（ステップ実行）

## 📱 アキヤ向けサマリー（日本語）
- **状態:** ❌ Step ${completed_steps}まで完了、Step $((completed_steps + 1))で停止
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **発生日時:** $(date '+%Y-%m-%d %H:%M')
- **進捗:** ${completed_steps}/${TOTAL_STEPS} ステップ完了
- **次のアクション:** クロちゃんにこのレポートを見せてね！

---

## 🤖 AI Failure Analysis (for Claude/Gemini/GPT)

### Execution Context
- **Mission:** ${MISSION_NAME}
- **Project:** ${CURRENT_PROJECT_NAME}
- **Failed at:** Step $((completed_steps + 1))/${TOTAL_STEPS}
- **Completed steps:** ${completed_steps}/${TOTAL_STEPS}
- **Timestamp:** $(date '+%Y-%m-%dT%H:%M:%S')

### Claude Code Self-Analysis
${ANALYSIS}
EOF
    fi

    # 一時ファイル削除
    rm -rf "$TEMP_DIR"

    # レポートをpush
    echo "完了: $(date)" >> "$LOG_FILE"
    git_push_postman "📋 レポート: $CURRENT_PROJECT/$REPORT_NAME (ステップ実行)"
}
```

#### ファイル全体の注意点
- 500行以内に収めること
- 全ての関数に日本語コメントを付けること
- グローバル変数（RETRY_COUNT, ANALYSIS等）はretry.shから引き継ぐ
- 色変数（RED, GREEN等）はpostman.shで定義済み、sourceで使える

---

### Step 2/3: core/executor.sh の修正

#### 修正箇所: run_single_mission() 関数の先頭付近

**現在のrun_single_mission()の冒頭（12行目あたり）：**
```bash
run_single_mission() {
    local MISSION_FILE=$1
    local MISSION_NAME=$2
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local LOG_FILE
    LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}.log"

    mkdir -p "$REPORT_DIR" "$POSTMAN_DIR/logs/execution"
```

**この直後（`mkdir -p` の次の行）に以下を追加：**

```bash
    # v2.0追加 - ステップ実行判定
    # 指示書に ### Step N/M 記法があればステップ実行モードへ分岐
    if has_steps "$MISSION_FILE"; then
        echo -e "  ${CYAN}📋 ステップ付き指示書を検出！ステップ実行モードに切り替えます${NC}"
        run_step_mission "$MISSION_FILE" "$MISSION_NAME"
        return $?
    fi
```

**つまりrun_single_mission()は：**
1. ステップ付き指示書 → run_step_mission()（step-runner.sh）に委譲
2. ステップなし指示書 → 今まで通りの一括実行

**既存の処理は一切変えない。分岐を追加するだけ。**

#### バージョンコメント追加

executor.shの先頭コメントに以下を追記：
```bash
# v2.0 追加 2026-02-22 - ステップ実行判定分岐（step-runner.sh連携）
```

---

### Step 3/3: postman.sh の修正

#### 修正箇所: source読み込み部分（postman.shの後半）

**現在のpostman.sh（約453行目付近）：**
```bash
# === 実行エンジン読み込み ===
# shellcheck source=core/executor.sh
source "$POSTMAN_DIR/core/executor.sh"
```

**この直後に以下を追加：**

```bash
# v2.0追加 - ステップ実行エンジン読み込み
# shellcheck source=core/step-runner.sh
if [ -f "$POSTMAN_DIR/core/step-runner.sh" ]; then
    source "$POSTMAN_DIR/core/step-runner.sh"
fi
```

**注意:** `if [ -f ... ]` で存在チェックしているのは、step-runner.shがまだない環境でpostman.shが壊れないようにするため。

#### バージョンコメント追加

postman.shの先頭コメントに以下を追記：
```bash
# v2.0 追加 2026-02-22 - ステップ実行エンジン読み込み
```

---

## ✅ 完了条件

1. `core/step-runner.sh` が新規作成されている
2. `core/executor.sh` の `run_single_mission()` にステップ判定分岐が追加されている
3. `postman.sh` に step-runner.sh の source 読み込みが追加されている
4. 各ファイルにバージョン番号（v2.0）と日本語コメントが入っている
5. 各ファイルの先頭に「このファイルは何をするか」の日本語コメントがある
6. 各ファイルが500行以内である
7. ShellCheckでエラーが出ない（SC1091,SC2034除外）
8. **既存の一括実行ミッション（ステップなし指示書）が壊れていないこと**
9. git commit: "📮 v2.0 feat: ステップ実行機能（Step-by-Step Execution with CI gate）"

---

## ⚠️ 注意事項

- **既存動作を絶対に壊さない。** ステップ記法がない指示書は今まで通りrun_single_mission()で一括実行すること
- step-runner.shの各関数はpostman.shでsource読み込みされる前提
- retry.shの `run_with_retry()` をそのまま使う。リトライ機構はstep-runner.sh側では再実装しない
- notifier.shの `send_line_notify()` と `notify_mission_result()` をそのまま使う
- 一時ファイル（.step-temp/）はミッション完了後に必ず削除する
- `gh` コマンドがない場合のフォールバック処理を必ず入れること
- wait_for_ci()のタイムアウトは安全側（CI不合格扱い）に倒す
- `.step-temp/` ディレクトリは `.gitignore` に追加すること

---

## 🧪 テスト方法

この指示書の実装が完了したら、以下のテスト用指示書で動作確認する（別途送信）：

```markdown
# テスト: ステップ実行動作確認

### Step 1/2: READMEにコメント追加
README.mdの末尾に以下を追加してください：
<!-- Step Execution v2.0 test - Step 1 -->

### Step 2/2: CLAUDE.mdにコメント追加
CLAUDE.mdの末尾に以下を追加してください：
<!-- Step Execution v2.0 test - Step 2 -->
```
