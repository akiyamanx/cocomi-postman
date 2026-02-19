#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2012
# このファイルは: COCOMI Postman 自動モード＆ミッション実行エンジン
# postman.shから呼ばれる実行系機能
# v1.1 修正 2026-02-18 - git pushをClaude Code外で実行する設計に変更
# v1.2 修正 2026-02-19 - auto_modeのプロジェクトループをconfig.json動的化
# v1.3 追加 2026-02-19 - LINE通知呼び出し追加
# v1.4 修正 2026-02-19 - ShellCheck対応
# /tmp権限問題の回避: git操作は全てPostman（Termux直接）が行う

# === プロジェクトリポジトリのgit push（Termuxから直接実行） ===
git_push_project() {
    local REPO_PATH=$1
    local COMMIT_MSG=$2

    if [ -n "$REPO_PATH" ] && [ -d "$REPO_PATH" ]; then
        cd "$REPO_PATH" || return 1
        git add -A
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "$COMMIT_MSG" > /dev/null 2>&1
            if git push origin main > /dev/null 2>&1; then
                echo -e "  ${GREEN}📮 プロジェクトをgit push完了${NC}"
                return 0
            else
                echo -e "  ${RED}⚠️ プロジェクトのgit pushに失敗${NC}"
                return 1
            fi
        else
            echo -e "  ${YELLOW}📝 プロジェクトに変更なし（push不要）${NC}"
        fi
    fi
    return 0
}

# === Postmanリポジトリのgit push（レポート送信） ===
git_push_postman() {
    local COMMIT_MSG=$1
    cd "$POSTMAN_DIR" || return 1
    git add -A
    if ! git diff --cached --quiet 2>/dev/null; then
        git commit -m "$COMMIT_MSG" > /dev/null 2>&1
        if git push origin main > /dev/null 2>&1; then
            echo -e "  ${GREEN}📮 レポートをスマホ支店に送りました${NC}"
        else
            echo -e "  ${RED}⚠️ レポートのgit pushに失敗${NC}"
        fi
    fi
}

# === 単一ミッション実行 ===
run_single_mission() {
    local MISSION_FILE=$1
    local MISSION_NAME=$2
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local LOG_FILE
    LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}.log"

    mkdir -p "$REPORT_DIR" "$POSTMAN_DIR/logs/execution"

    {
        echo "=== ミッション実行ログ ==="
        echo "開始: $(date)"
        echo "プロジェクト: $CURRENT_PROJECT_NAME"
    } > "$LOG_FILE"

    if [ -n "$CURRENT_REPO_PATH" ] && [ -d "$CURRENT_REPO_PATH" ]; then
        # STEP 1: プロジェクトを最新に
        cd "$CURRENT_REPO_PATH" || return 1
        echo -e "  ${YELLOW}📡 git pull中...${NC}"
        git pull origin main >> "$LOG_FILE" 2>&1

        # STEP 2: Claude Codeで作業（gitはさせない！）
        echo -e "  ${YELLOW}🤖 Claude Code実行中...${NC}"
        cat "$MISSION_FILE" | claude -p --allowedTools "Read,Write,Edit,Bash(cat *),Bash(ls *),Bash(find *),Bash(head *),Bash(tail *),Bash(wc *),Bash(grep *),Bash(node *),Bash(npm *)" >> "$LOG_FILE" 2>&1
        local EXIT_CODE=$?

        # STEP 3: Postmanがgit push（/tmp問題回避）
        local REPORT_NAME="R-${MISSION_NAME#M-}"
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "  ${GREEN}🤖 Claude Code作業完了！${NC}"
            git_push_project "$CURRENT_REPO_PATH" "📮 $MISSION_NAME by COCOMI Postman"

            cat > "$REPORT_DIR/${REPORT_NAME}.md" << EOF
# ✅ ミッション完了レポート
- **ミッション:** ${MISSION_NAME}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **完了日時:** $(date '+%Y-%m-%d %H:%M')
- **結果:** 成功
EOF
            echo -e "  ${GREEN}✅ $MISSION_NAME 完了！${NC}"

            # v1.3追加 - LINE通知（成功時）
            if type notify_mission_result &>/dev/null; then
                notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "success"
            fi
        else
            echo -e "  ${RED}🤖 エラー発生${NC}"
            git_push_project "$CURRENT_REPO_PATH" "⚠️ $MISSION_NAME 途中成果"

            mkdir -p "$POSTMAN_DIR/errors/$CURRENT_PROJECT"
            cat > "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${MISSION_NAME#M-}.md" << EOF
# ❌ エラーレポート
- **ミッション:** ${MISSION_NAME}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **発生日時:** $(date '+%Y-%m-%d %H:%M')
- **終了コード:** ${EXIT_CODE}
EOF
            echo -e "  ${RED}❌ $MISSION_NAME エラー${NC}"

            # v1.3追加 - LINE通知（エラー時）
            if type notify_mission_result &>/dev/null; then
                notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "error" "Claude Code実行エラー"
            fi
        fi

        # STEP 4: レポートをpush
        echo "完了: $(date)" >> "$LOG_FILE"
        git_push_postman "📋 レポート: $CURRENT_PROJECT/$REPORT_NAME"
    else
        echo -e "  ${RED}❌ リポジトリが見つからない: $CURRENT_REPO_PATH${NC}"
    fi
}

# === 自動モード（放置運転） ===
auto_mode() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🌙 自動モード（放置運転）${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  GitHubを定期チェック→新着ミッション自動実行"
    echo "  ※ git pushはPostmanが直接行います"
    echo ""
    echo "  チェック間隔："
    echo -e "  ${GREEN}1${NC}. 毎1分"
    echo -e "  ${GREEN}2${NC}. 毎5分 ⭐"
    echo -e "  ${GREEN}3${NC}. 毎15分"
    echo ""
    echo -n "  → "
    read -r INTERVAL_CHOICE

    local INTERVAL=300
    case "$INTERVAL_CHOICE" in
        1) INTERVAL=60 ;;
        2) INTERVAL=300 ;;
        3) INTERVAL=900 ;;
    esac

    echo ""
    echo -e "${GREEN}  🌙 自動モード起動！（${INTERVAL}秒間隔）${NC}"
    echo -e "  Ctrl+C で終了"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    while true; do
        local NOW
        NOW=$(date '+%H:%M')
        cd "$POSTMAN_DIR" || return
        git pull origin main > /dev/null 2>&1

        local found=false
        # v1.2修正 - config.jsonから動的にプロジェクト一覧を取得
        while IFS= read -r proj; do
            local mdir="$POSTMAN_DIR/missions/$proj"
            local rdir="$POSTMAN_DIR/reports/$proj"
            local edir="$POSTMAN_DIR/errors/$proj"

            if [ -d "$mdir" ]; then
                for mf in "$mdir"/M-*.md; do
                    [ -f "$mf" ] || continue
                    local mname
                    mname=$(basename "$mf" .md)
                    local rname="R-${mname#M-}"
                    local ename="E-${mname#M-}"

                    if [ ! -f "$rdir/${rname}.md" ] && [ ! -f "$edir/${ename}.md" ]; then
                        echo -e "  ${GREEN}📬 $NOW 新着！[$proj] $mname${NC}"
                        CURRENT_PROJECT="$proj"
                        load_project_info
                        run_single_mission "$mf" "$mname"
                        found=true
                    fi
                done
            fi
        done < <(get_project_ids)

        if ! $found; then
            echo -e "  🟢 $NOW チェック完了 新着なし"
        fi

        sleep "$INTERVAL"
    done
}
