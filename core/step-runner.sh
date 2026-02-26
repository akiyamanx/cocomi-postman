#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162
# このファイルは: COCOMI Postman ステップ実行エンジン
# 指示書の ### Step N/M 記法を認識し、1ステップずつ順番に実行する
# 各ステップ完了後にgit push→CI確認→CI合格で自動的に次のステップへ
# v2.0 追加 2026-02-22 - Phase E: Step-by-Step Execution
# v2.0.1 修正 2026-02-22 - ShellCheck SC2086修正（算術展開・変数のダブルクォート追加）
# v2.0.2 修正 2026-02-23 - has_steps/wait_for_ci grep -c 整数判定バグ修正
# v2.1 改修 2026-02-24 - 全体コンテキスト注入: Claude Codeが毎回全体を把握してからステップ実行
# v2.2 修正 2026-02-27 - push不要（変更なし）時のCI待ちスキップ対応

# === ステップ記法判定 ===
# 指示書に ### Step で始まる行が2つ以上あればステップ付き指示書
# 引数: $1 = 指示書ファイルパス
# 戻り値: 0 = ステップあり, 1 = ステップなし
has_steps() {
    local mission_file="$1"
    step_count=$(grep -c "^### Step [0-9]" "$mission_file" 2>/dev/null) || true
    step_count="${step_count:-0}"
    if [ "$step_count" -ge 2 ]; then
        return 0
    fi
    return 1
}

# === ステップ見出し一覧を抽出 ===
# 全ステップの ### Step N/M 行を一覧で返す（コンテキスト注入用）
# 引数: $1 = 指示書ファイルパス
# 出力: 各行に "Step N/M: タイトル" 形式
extract_step_titles() {
    local mission_file="$1"
    grep "^### Step [0-9]" "$mission_file" 2>/dev/null
}

# === ステップ分割パーサー（v2.1 全体コンテキスト注入対応） ===
# 指示書を ### Step N/M の区切りでステップごとのファイルに分割する
# v2.1追加: 各ステップファイルに「全体指示書パス＋進捗情報」を自動注入
# Claude Codeはこの情報を見て、全体指示書を読んでから作業に入る
# 引数: $1 = 指示書ファイルパス, $2 = 一時ディレクトリパス
# 出力: 一時ディレクトリに step-1.md, step-2.md, ... を生成
# 戻り値: ステップ数（標準出力にecho）
parse_steps() {
    local mission_file="$1"
    local temp_dir="$2"
    mkdir -p "$temp_dir"

    # v2.1追加 - 全体指示書をコピー（Claude Codeが参照できるように）
    cp "$mission_file" "$temp_dir/full-instruction.md"

    # 共通ヘッダー（最初の ### Step より前の部分）を抽出
    local first_step_line
    first_step_line=$(grep -n "^### Step [0-9]" "$mission_file" | head -1 | cut -d: -f1)

    local header=""
    if [ -n "$first_step_line" ] && [ "$first_step_line" -gt 1 ]; then
        header=$(head -"$((first_step_line - 1))" "$mission_file")
    fi

    # ステップの開始行番号を全て取得
    local step_lines=()
    while IFS= read -r line_info; do
        step_lines+=("$(echo "$line_info" | cut -d: -f1)")
    done < <(grep -n "^### Step [0-9]" "$mission_file")

    local total_steps=${#step_lines[@]}
    local total_lines
    total_lines=$(wc -l < "$mission_file")

    # v2.1追加 - 全ステップの見出し一覧を取得
    local step_titles
    step_titles=$(extract_step_titles "$mission_file")

    # 各ステップを分割してファイルに保存
    local i
    for i in $(seq 0 "$((total_steps - 1))"); do
        local start="${step_lines[$i]}"
        local end
        if [ "$i" -lt "$((total_steps - 1))" ]; then
            end="$((step_lines[$((i + 1))] - 1))"
        else
            end="$total_lines"
        fi

        local step_num="$((i + 1))"
        local step_file="$temp_dir/step-${step_num}.md"

        # v2.1追加 - 完了済みステップのリストを生成
        local completed_list=""
        if [ "$step_num" -gt 1 ]; then
            local j
            for j in $(seq 1 "$((step_num - 1))"); do
                completed_list="${completed_list}  - Step ${j}: ✅ 完了済み（git push＆CI合格済み）
"
            done
        else
            completed_list="  - なし（これが最初のステップです）
"
        fi

        # 共通ヘッダー + コンテキスト情報 + このステップの内容
        {
            if [ -n "$header" ]; then
                echo "$header"
                echo ""
                echo "---"
                echo ""
            fi

            # v2.1追加 - 全体コンテキスト注入ブロック
            cat << CONTEXT_EOF
## ⚠️ 作業前に必ず読んでください（自動生成・コンテキスト情報）

この指示書はステップ分割されており、あなたは今 **Step ${step_num}/${total_steps}** を担当します。

### 🔍 全体指示書を確認してください
**全体指示書のパス:** \`${temp_dir}/full-instruction.md\`

**必ず全体指示書を最初に読んで**、プロジェクト全体の目標・アーキテクチャ・ファイル構成を把握してから、今回のステップの作業に入ってください。

### 📋 全ステップ一覧
${step_titles}

### ✅ 完了済みステップ
${completed_list}
### 📌 今回の作業
**→ Step ${step_num}/${total_steps} を実行してください**

前のステップの成果物は既にリポジトリに反映済みです。リポジトリの現在の状態を確認してから作業を開始してください。

---

CONTEXT_EOF

            # このステップの実際の内容
            sed -n "${start},${end}p" "$mission_file"
        } > "$step_file"
    done

    echo "$total_steps"
}

# === CI結果待機 ===
# git push後にGitHub Actions CIの結果を待つ
# 引数: $1 = プロジェクトのリポジトリパス
# 戻り値: 0 = CI合格, 1 = CI不合格 or タイムアウト
wait_for_ci() {
    local repo_path="$1"
    cd "$repo_path" || return 1

    # ghコマンドの存在チェック
    if ! command -v gh &> /dev/null; then
        echo -e "  ${YELLOW}⚠️ gh CLIなし。CI確認をスキップします${NC}"
        return 0
    fi

    # リモートURLからリポ名を取得（HTTPS/SSH両対応）
    local repo_url
    repo_url=$(git remote get-url origin)
    local repo_name
    repo_name=$(echo "$repo_url" | sed -E 's|.*github\.com[:/]||; s|\.git$||')

    if [ -z "$repo_name" ]; then
        echo -e "  ${RED}⚠️ リポジトリ名を取得できません${NC}"
        return 1
    fi

    # CIワークフローが設定されているか確認
    local workflow_count
    workflow_count=$(gh workflow list --repo "$repo_name" --json name 2>/dev/null | grep -c '"name"') || true
    workflow_count="${workflow_count:-0}"
    if [ "$workflow_count" -eq 0 ]; then
        echo -e "  ${YELLOW}⚠️ GitHub Actionsワークフローなし。CI確認をスキップします${NC}"
        return 0
    fi

    echo -e "  ${YELLOW}⏳ CI結果を待機中... （最大10分）${NC}"

    local max_attempts=20
    local wait_interval=30
    local attempt=0

    # push直後のCI起動を待つため最初に15秒待機
    sleep 15

    while [ "$attempt" -lt "$max_attempts" ]; do
        attempt="$((attempt + 1))"

        # gh CLIでワークフロー実行結果を取得
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

        echo -e "  ${YELLOW}  ⏳ CI実行中... （${attempt}/${max_attempts}）${NC}"
        sleep "$wait_interval"
    done

    echo -e "  ${RED}⚠️ CIタイムアウト（10分経過）${NC}"
    return 1
}

# === ステップ付きミッション実行メイン関数 ===
# ステップ付き指示書を1ステップずつ順番に実行する
# 引数: $1 = 指示書ファイルパス, $2 = ミッション名
# この関数はexecutor.shのrun_single_mission()から呼ばれる
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

    # ① ステップ分割（v2.1: 全体コンテキスト注入付き）
    local TEMP_DIR="$POSTMAN_DIR/.step-temp/${MISSION_NAME}"
    rm -rf "$TEMP_DIR"
    local TOTAL_STEPS
    TOTAL_STEPS=$(parse_steps "$MISSION_FILE" "$TEMP_DIR")

    echo -e "  ${CYAN}📋 ${TOTAL_STEPS}ステップに分割しました（全体コンテキスト注入済み）${NC}"
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

        if [ "$EXIT_CODE" -ne 0 ]; then
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
        local push_result=$?

        # v2.2修正 - push不要（変更なし）の場合はCI待ちをスキップ
        if [ "$push_result" -eq 2 ]; then
            echo -e "  ${YELLOW}⏭️ 変更なしのためCI待ちスキップ${NC}"
            echo "--- Step ${step_num} 変更なし・CI待ちスキップ: $(date) ---" >> "$LOG_FILE"
        elif ! wait_for_ci "$CURRENT_REPO_PATH"; then
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
        echo "--- Step ${step_num} 完了: $(date) ---" >> "$LOG_FILE"

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
- **Execution mode:** step-by-step with CI gate + full context injection (v2.1)
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
- **Execution mode:** step-by-step with full context injection (v2.1)
- **Timestamp:** $(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')

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
