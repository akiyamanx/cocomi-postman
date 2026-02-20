#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2129
# このファイルは: COCOMI Postman リトライ＆自動継続エンジン
# Claude Code実行失敗時の自動リトライ、--continue継続、自己分析レポート生成
# v1.5 追加 2026-02-20 - Phase C: Retry + Continue + AI Self-Analysis

# === グローバル変数（executor.shへの受け渡し用） ===
RETRY_COUNT=0
CONTINUE_TRIED="false"
ANALYSIS=""

# === Claude Code実行（リトライ機構付き） ===
# 引数: $1=MISSION_FILE, $2=MISSION_NAME, $3=LOG_FILE, $4=CURRENT_REPO_PATH
# 戻り値: 0=成功, 1=全て失敗
# グローバル変数をセット: RETRY_COUNT, CONTINUE_TRIED, ANALYSIS
run_with_retry() {
    local MISSION_FILE="$1"
    local MISSION_NAME="$2"
    local LOG_FILE="$3"
    local REPO_PATH="$4"
    local EXIT_CODE=0

    # グローバル変数初期化
    RETRY_COUNT=0
    CONTINUE_TRIED="false"
    ANALYSIS=""

    # v1.5 リトライ用のallowedTools（executor.shと同じ）
    local ALLOWED_TOOLS="Read,Write,Edit,Bash(cat *),Bash(ls *),Bash(find *),Bash(head *),Bash(tail *),Bash(wc *),Bash(grep *),Bash(node *),Bash(npm *)"

    # --- Step 1: 初回実行 ---
    echo "--- 初回実行開始: $(date) ---" >> "$LOG_FILE"
    claude -p --allowedTools "$ALLOWED_TOOLS" < "$MISSION_FILE" >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "--- 初回実行成功: $(date) ---" >> "$LOG_FILE"
        return 0
    fi

    echo "--- 初回実行失敗 (EXIT_CODE=$EXIT_CODE): $(date) ---" >> "$LOG_FILE"

    # --- Step 2: リトライループ（最大3回） ---
    local MAX_RETRY=3
    for i in $(seq 1 $MAX_RETRY); do
        RETRY_COUNT=$i
        echo -e "  ${YELLOW}🔄 リトライ ${i}/${MAX_RETRY}（5秒待機）...${NC}"
        echo "--- リトライ ${i}/${MAX_RETRY} 待機開始: $(date) ---" >> "$LOG_FILE"
        sleep 5

        echo "--- リトライ ${i}/${MAX_RETRY} 実行開始: $(date) ---" >> "$LOG_FILE"
        claude -p --allowedTools "$ALLOWED_TOOLS" < "$MISSION_FILE" >> "$LOG_FILE" 2>&1
        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            echo "--- リトライ ${i} で成功: $(date) ---" >> "$LOG_FILE"
            echo -e "  ${GREEN}🔄 リトライ${i}回目で成功！${NC}"
            return 0
        fi

        echo "--- リトライ ${i} 失敗 (EXIT_CODE=$EXIT_CODE): $(date) ---" >> "$LOG_FILE"
    done

    # --- Step 3: --continue試行（1回） ---
    CONTINUE_TRIED="true"
    echo -e "  ${YELLOW}🔄 --continue で継続試行中...${NC}"
    echo "--- --continue 試行開始: $(date) ---" >> "$LOG_FILE"
    claude --continue >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "--- --continue 成功: $(date) ---" >> "$LOG_FILE"
        echo -e "  ${GREEN}🔄 --continueで成功！${NC}"
        return 0
    fi

    echo "--- --continue 失敗 (EXIT_CODE=$EXIT_CODE): $(date) ---" >> "$LOG_FILE"

    # --- Step 4: 自己分析（Claude Codeに失敗原因を聞く） ---
    echo -e "  ${YELLOW}🔍 Claude Codeに失敗原因を分析させています...${NC}"
    echo "--- 自己分析開始: $(date) ---" >> "$LOG_FILE"
    ANALYSIS=$(claude -p "The previous task failed. Analyze the failure:
- What was attempted
- How far it progressed
- Root cause of failure
- Which file and line caused the issue
- Suggested fix for the next attempt
Report in English. Be concise and technical." --continue 2>&1)

    if [ -z "$ANALYSIS" ]; then
        ANALYSIS="（自己分析失敗: Claude Codeからの応答なし）"
    fi

    echo "--- 自己分析完了: $(date) ---" >> "$LOG_FILE"
    echo "$ANALYSIS" >> "$LOG_FILE"

    # --- Step 5: 全て失敗 ---
    echo "--- 全リトライ失敗。最終EXIT_CODE=$EXIT_CODE: $(date) ---" >> "$LOG_FILE"
    return 1
}

# === 二層構造エラーレポート生成 ===
# 引数: $1=MISSION_NAME, $2=PROJECT_NAME, $3=RETRY_COUNT, $4=CONTINUE_TRIED,
#       $5=ANALYSIS, $6=LOG_FILE, $7=ERROR_REPORT_PATH
generate_error_report() {
    local MISSION_NAME="$1"
    local PROJECT_NAME="$2"
    local RETRY_COUNT="$3"
    local CONTINUE_TRIED="$4"
    local ANALYSIS="$5"
    local LOG_FILE="$6"
    local ERROR_REPORT_PATH="$7"

    # ANALYSISから「Suggested fix」行を抽出して一言を生成
    local HITOKOTO
    local SUGGESTED_FIX
    SUGGESTED_FIX=$(echo "$ANALYSIS" | grep -i "suggested fix" | head -1)
    if [ -z "$SUGGESTED_FIX" ]; then
        HITOKOTO="Claude Codeが作業中にエラーが発生しました"
    else
        HITOKOTO="$SUGGESTED_FIX"
    fi

    # continue実施状況の日本語表記
    local CONTINUE_STATUS="未実施"
    if [ "$CONTINUE_TRIED" = "true" ]; then
        CONTINUE_STATUS="tried"
    fi

    # ログ末尾50行を取得
    local LOG_TAIL=""
    if [ -f "$LOG_FILE" ]; then
        LOG_TAIL=$(tail -50 "$LOG_FILE")
    fi

    # v1.5 二層構造エラーレポート生成
    cat > "$ERROR_REPORT_PATH" << REPORT_EOF
# ❌ Error Report: ${MISSION_NAME}

## 📱 アキヤ向けサマリー（日本語）
- **状態:** ❌ リトライ${RETRY_COUNT}回＋continue ${CONTINUE_STATUS}→全部失敗
- **プロジェクト:** ${PROJECT_NAME}
- **発生日時:** $(date '+%Y-%m-%d %H:%M')
- **一言:** ${HITOKOTO}
- **次のアクション:** クロちゃんにこのレポートを見せてね！

---

## 🤖 AI Failure Analysis (for Claude/Gemini/GPT)

### Execution Context
- **Mission:** ${MISSION_NAME}
- **Project:** ${PROJECT_NAME}
- **Retry attempts:** ${RETRY_COUNT}/3
- **Continue attempted:** ${CONTINUE_TRIED}
- **Timestamp:** $(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')

### Claude Code Self-Analysis
${ANALYSIS}

### Execution Log (last 50 lines)
\`\`\`
${LOG_TAIL}
\`\`\`

### Full Log Path
${LOG_FILE}
REPORT_EOF

    echo -e "  ${YELLOW}📝 エラーレポート生成: $(basename "$ERROR_REPORT_PATH")${NC}"
}
