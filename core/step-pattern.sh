#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162
# このファイルは: COCOMI Postman ステップパターン実行エンジン
# アキヤ発案: 「これでダメだったらこっちのパターン試して」を実現する条件分岐型指示書
# on-fail: next/stop/step-N — 失敗時の遷移先
# on-success: next/step-N — 成功時の遷移先（フォールバックステップのスキップに使う）
# type: execute/search/meeting — ステップの種類（Claude Code実行/Brave Search/三姉妹会議）
# v1.0 新規作成 2026-03-27 - step-runner.sh v3.0から分離
# 呼び出し元: executor.sh（has_step_pattern()がtrueの場合）
# 依存: step-runner.sh（parse_steps, wait_for_ci等）, escalation.sh（search/meeting）, retry.sh

# ═══════════════════════════════════════════════════════
# ステップパターン指示書の記法例:
#
# ### Step 1/4: まずTMPDIR方式を試す
# <!-- on-fail: next -->
# <!-- on-success: step-3 -->
# <!-- type: execute -->
# （Claude Codeへの指示内容）
#
# ### Step 2/4: symlink方式を試す（フォールバック）
# <!-- on-fail: next -->
# <!-- on-success: step-3 -->
# （Claude Codeへの指示内容）
#
# ### Step 3/4: Brave Searchで解決策を検索
# <!-- on-fail: next -->
# <!-- type: search -->
# <!-- query: Termux Claude Code /tmp workaround -->
#
# ### Step 4/4: 三姉妹会議に問題を投げる
# <!-- on-fail: stop -->
# <!-- type: meeting -->
# <!-- grade: standard -->
# ═══════════════════════════════════════════════════════

# === ステップパターン付きミッション実行メイン関数 ===
# 引数: $1 = 指示書ファイルパス, $2 = ミッション名
run_step_pattern_mission() {
    local MISSION_FILE="$1"
    local MISSION_NAME="$2"
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local LOG_FILE
    LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}-pattern.log"

    mkdir -p "$REPORT_DIR" "$POSTMAN_DIR/logs/execution"

    # エスカレーション機能を読み込み
    # shellcheck source=core/escalation.sh
    source "$POSTMAN_DIR/core/escalation.sh"

    {
        echo "=== ステップパターン実行ログ ==="
        echo "開始: $(date)"
        echo "プロジェクト: $CURRENT_PROJECT_NAME"
        echo "ミッション: $MISSION_NAME"
        echo "モード: ステップパターン（条件分岐＋エスカレーション）"
    } > "$LOG_FILE"

    # ① ステップ分割（step-runner.shのparse_stepsを流用）
    local TEMP_DIR="$POSTMAN_DIR/.step-temp/${MISSION_NAME}"
    rm -rf "$TEMP_DIR"
    local TOTAL_STEPS
    TOTAL_STEPS=$(parse_steps "$MISSION_FILE" "$TEMP_DIR")

    echo -e "  ${CYAN}📋 ${TOTAL_STEPS}ステップ（パターン分岐付き）に分割しました${NC}"
    echo "ステップ数: $TOTAL_STEPS (パターン指示書)" >> "$LOG_FILE"

    # ② 実行ループ用の変数
    declare -a step_results
    local step_num=1
    local last_context_file=""
    local all_failed=true

    # ③ 条件分岐付きステップ実行ループ
    while [ "$step_num" -le "$TOTAL_STEPS" ]; do
        local step_file="$TEMP_DIR/step-${step_num}.md"

        # ルーティングメタデータをパース（escalation.shのparse_step_meta使用）
        local on_fail
        on_fail=$(parse_step_meta "$step_file" "on-fail")
        on_fail="${on_fail:-stop}"
        local on_success
        on_success=$(parse_step_meta "$step_file" "on-success")
        on_success="${on_success:-next}"
        local step_type
        step_type=$(parse_step_meta "$step_file" "type")
        step_type="${step_type:-execute}"

        echo ""
        echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${BOLD}📌 Step ${step_num}/${TOTAL_STEPS} [${step_type}] fail→${on_fail} / ok→${on_success}${NC}"
        echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "--- Step ${step_num}/${TOTAL_STEPS} [type:${step_type}]: $(date) ---" >> "$LOG_FILE"

        # 前のステップの結果（検索/会議）を注入
        if [ -n "$last_context_file" ] && [ -f "$last_context_file" ]; then
            local prev_type
            prev_type=$(parse_step_meta "$TEMP_DIR/step-$((step_num - 1)).md" "type" 2>/dev/null)
            inject_context_to_step "$step_file" "$last_context_file" "${prev_type:-execute}"
            last_context_file=""
        fi

        local step_exit=0

        # === ステップタイプ別の実行 ===
        case "$step_type" in
            search)
                local search_query
                search_query=$(parse_step_meta "$step_file" "query")
                if [ -z "$search_query" ]; then
                    echo -e "  ${RED}❌ queryが指定されていません${NC}"
                    step_exit=1
                else
                    last_context_file="$TEMP_DIR/search-result-${step_num}.md"
                    run_search_step "$search_query" "$last_context_file"
                    step_exit=$?
                fi
                ;;
            meeting)
                local meeting_topic
                meeting_topic=$(sed -n '/^### Step/,/^### Step\|^$/p' "$step_file" \
                    | grep -v "^### Step\|^<!--" | head -20)
                local meeting_grade
                meeting_grade=$(parse_step_meta "$step_file" "grade")
                meeting_grade="${meeting_grade:-standard}"
                last_context_file="$TEMP_DIR/meeting-result-${step_num}.md"
                run_meeting_step "$meeting_topic" "$last_context_file" "$meeting_grade"
                step_exit=$?
                ;;
            *)
                # 通常のClaude Code実行
                if [ -n "$CURRENT_REPO_PATH" ] && [ -d "$CURRENT_REPO_PATH" ]; then
                    cd "$CURRENT_REPO_PATH" || break
                    git pull origin main > /dev/null 2>&1
                fi
                # shellcheck source=core/retry.sh
                source "$POSTMAN_DIR/core/retry.sh"
                run_with_retry "$step_file" "${MISSION_NAME}-step${step_num}" "$LOG_FILE" "$CURRENT_REPO_PATH"
                step_exit=$?
                # 成功時はgit push + CI待ち
                if [ "$step_exit" -eq 0 ]; then
                    git_push_project "$CURRENT_REPO_PATH" \
                        "📮 ${MISSION_NAME} Step ${step_num}/${TOTAL_STEPS} by COCOMI Postman"
                    local push_result=$?
                    if [ "$push_result" -eq 2 ]; then
                        echo -e "  ${YELLOW}⏭️ 変更なし — CI待ちスキップ${NC}"
                    elif ! wait_for_ci "$CURRENT_REPO_PATH"; then
                        echo -e "  ${RED}❌ Step ${step_num} CI不合格${NC}"
                        step_exit=1
                    fi
                fi
                ;;
        esac

        # === 結果に基づくルーティング ===
        if [ "$step_exit" -eq 0 ]; then
            step_results[$step_num]="success"
            all_failed=false
            echo -e "  ${GREEN}✅ Step ${step_num} 成功${NC}"
            echo "--- Step ${step_num} 成功: $(date) ---" >> "$LOG_FILE"

            local next_step
            next_step=$(_resolve_routing "$on_success" "$step_num" "$TOTAL_STEPS")
            if [ "$next_step" -eq 0 ]; then
                break
            fi
            # スキップされるステップを記録
            local skip_i
            for skip_i in $(seq "$((step_num + 1))" "$((next_step - 1))"); do
                step_results[$skip_i]="skipped"
                echo -e "  ${YELLOW}⏭️ Step ${skip_i} スキップ${NC}"
            done
            step_num=$next_step
        else
            step_results[$step_num]="failed"
            echo -e "  ${RED}❌ Step ${step_num} 失敗${NC}"
            echo "--- Step ${step_num} 失敗: $(date) ---" >> "$LOG_FILE"

            if [ "$on_fail" = "stop" ]; then
                echo -e "  ${RED}🛑 on-fail: stop — 実行停止${NC}"
                break
            fi
            local next_step
            next_step=$(_resolve_routing "$on_fail" "$step_num" "$TOTAL_STEPS")
            if [ "$next_step" -eq 0 ]; then
                break
            fi
            echo -e "  ${YELLOW}→ on-fail: Step ${next_step} へ${NC}"
            step_num=$next_step
        fi
    done

    # ④ レポート生成（ステップ結果サマリー付き）
    local REPORT_NAME="R-${MISSION_NAME#M-}"
    local step_summary=""
    local s
    for s in $(seq 1 "$TOTAL_STEPS"); do
        local result="${step_results[$s]:-not_reached}"
        local icon="⬜"
        case "$result" in
            success) icon="✅" ;;
            failed)  icon="❌" ;;
            skipped) icon="⏭️" ;;
        esac
        step_summary="${step_summary}  ${icon} Step ${s}: ${result}\n"
    done

    if ! $all_failed; then
        echo ""
        echo -e "  ${GREEN}🎉 ステップパターン実行完了！${NC}"
        cat > "$REPORT_DIR/${REPORT_NAME}.md" << EOF
# ✅ Mission Report: ${MISSION_NAME}（ステップパターン実行）

## 📱 アキヤ向けサマリー
- **状態:** ✅ 完了
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **完了日時:** $(date '+%Y-%m-%d %H:%M')
- **モード:** ステップパターン v1.0（条件分岐＋エスカレーション）

### ステップ結果
$(echo -e "$step_summary")

---

## 🤖 AI Work Summary
- **Mission:** ${MISSION_NAME}
- **Mode:** step-pattern v1.0
- **Timestamp:** $(date '+%Y-%m-%dT%H:%M:%S')

### Claude Code Self-Analysis
${ANALYSIS}
EOF
        if type notify_mission_result &>/dev/null; then
            notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "success" \
                "🎉 ステップパターン完了！"
        fi
    else
        echo -e "  ${RED}❌ 全ステップ失敗${NC}"
        mkdir -p "$POSTMAN_DIR/errors/$CURRENT_PROJECT"
        cat > "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${MISSION_NAME#M-}.md" << EOF
# ❌ Error Report: ${MISSION_NAME}（ステップパターン実行）

## 📱 アキヤ向けサマリー
- **状態:** ❌ 全ステップ失敗
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **発生日時:** $(date '+%Y-%m-%d %H:%M')
- **次のアクション:** クロちゃんにこのレポートを見せてね！

### ステップ結果
$(echo -e "$step_summary")

---

## 🤖 AI Failure Analysis
- **Mission:** ${MISSION_NAME}
- **Mode:** step-pattern v1.0
- **Timestamp:** $(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')

### Claude Code Self-Analysis
${ANALYSIS}
EOF
        if type notify_mission_result &>/dev/null; then
            notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "error" \
                "❌ 全ステップ失敗"
        fi
    fi

    rm -rf "$TEMP_DIR"
    echo "完了: $(date)" >> "$LOG_FILE"
    git_push_postman "📋 レポート: $CURRENT_PROJECT/$REPORT_NAME (ステップパターン)"
}

# === ルーティング先のステップ番号を解決する ===
# "next" → 次のステップ番号, "step-N" → N, "stop" → 0
# 引数: $1 = ルーティング値, $2 = 現在のステップ番号, $3 = 総ステップ数
_resolve_routing() {
    local routing="$1"
    local current="$2"
    local total="$3"

    case "$routing" in
        next)
            local next_num=$((current + 1))
            if [ "$next_num" -gt "$total" ]; then
                echo 0
            else
                echo "$next_num"
            fi
            ;;
        stop)
            echo 0
            ;;
        step-*)
            local target="${routing#step-}"
            if [ "$target" -gt "$total" ]; then
                echo 0
            else
                echo "$target"
            fi
            ;;
        *)
            echo $((current + 1))
            ;;
    esac
}
