#!/bin/bash
# このファイルは: COCOMI Postman 自動モード＆ミッション実行エンジン
# postman.shから呼ばれる実行系機能
# v1.0 作成 2026-02-18

# === 自動モード用の単一ミッション実行 ===
# 引数: $1=ミッションファイルパス $2=ミッション名
run_single_mission() {
    local MISSION_FILE=$1
    local MISSION_NAME=$2
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}.log"

    mkdir -p "$REPORT_DIR" "$POSTMAN_DIR/logs/execution"

    echo "=== 自動実行ログ ===" > "$LOG_FILE"
    echo "開始: $(date)" >> "$LOG_FILE"

    if [ -n "$CURRENT_REPO_PATH" ] && [ -d "$CURRENT_REPO_PATH" ]; then
        cd "$CURRENT_REPO_PATH"
        git pull origin main >> "$LOG_FILE" 2>&1

        # Claude Codeにパイプで指示書を渡して実行
        cat "$MISSION_FILE" | claude -p --allowedTools "Bash(git *),Read,Write,Edit" >> "$LOG_FILE" 2>&1
        local EXIT_CODE=$?

        local REPORT_NAME="R-${MISSION_NAME#M-}"
        if [ $EXIT_CODE -eq 0 ]; then
            # 成功レポート生成
            cat > "$REPORT_DIR/${REPORT_NAME}.md" << EOF
# ✅ 自動実行完了レポート
- **ミッション:** ${MISSION_NAME}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **完了日時:** $(date '+%Y-%m-%d %H:%M')
- **実行モード:** 🌙 自動モード

## 実行ログ（末尾30行）
\`\`\`
$(tail -30 "$LOG_FILE")
\`\`\`
EOF
            echo -e "  ${GREEN}✅ $(date '+%H:%M') $MISSION_NAME 完了！${NC}"
        else
            # エラーレポート生成
            mkdir -p "$POSTMAN_DIR/errors/$CURRENT_PROJECT"
            cat > "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${MISSION_NAME#M-}.md" << EOF
# ❌ 自動実行エラーレポート
- **ミッション:** ${MISSION_NAME}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **発生日時:** $(date '+%Y-%m-%d %H:%M')
- **終了コード:** ${EXIT_CODE}

## エラーログ（末尾30行）
\`\`\`
$(tail -30 "$LOG_FILE")
\`\`\`
EOF
            echo -e "  ${RED}❌ $(date '+%H:%M') $MISSION_NAME エラー（コード:${EXIT_CODE}）${NC}"
        fi

        # レポートをGitHubにpush
        cd "$POSTMAN_DIR"
        echo "完了: $(date)" >> "$LOG_FILE"
        git add -A
        git commit -m "📋 自動実行レポート: $CURRENT_PROJECT/$REPORT_NAME" > /dev/null 2>&1
        git push origin main > /dev/null 2>&1
    else
        echo -e "  ${RED}❌ リポジトリパスが無効: $CURRENT_REPO_PATH${NC}"
    fi
}

# === 自動モード（放置運転） ===
auto_mode() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🌙 自動モード（放置運転）${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  GitHubを定期チェックして新着ミッションを自動実行します"
    echo ""
    echo "  チェック間隔："
    echo -e "  ${GREEN}1${NC}. 毎1分（すぐ反応）"
    echo -e "  ${GREEN}2${NC}. 毎5分（バランス型）⭐"
    echo -e "  ${GREEN}3${NC}. 毎15分（省エネ）"
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
    echo -e "${GREEN}  🌙 自動モード起動！${NC}"
    echo -e "  チェック間隔: $((INTERVAL / 60))分"
    echo -e "  Ctrl+C で終了"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 自動モードループ
    while true; do
        local NOW=$(date '+%H:%M')
        cd "$POSTMAN_DIR"
        git pull origin main > /dev/null 2>&1

        # 全プロジェクトの未実行ミッションをチェック
        local found=false
        for proj in genba-pro culo-chan maintenance-map; do
            local mdir="$POSTMAN_DIR/missions/$proj"
            local rdir="$POSTMAN_DIR/reports/$proj"
            local edir="$POSTMAN_DIR/errors/$proj"

            if [ -d "$mdir" ]; then
                for mf in $(ls "$mdir"/M-*.md 2>/dev/null); do
                    local mname=$(basename "$mf" .md)
                    local rname="R-${mname#M-}"
                    local ename="E-${mname#M-}"

                    if [ ! -f "$rdir/${rname}.md" ] && [ ! -f "$edir/${ename}.md" ]; then
                        echo -e "  ${GREEN}📬 $NOW 新着発見！ [$proj] $mname${NC}"
                        CURRENT_PROJECT="$proj"
                        load_project_info
                        echo -e "  ${YELLOW}🏭 自動実行中...${NC}"
                        run_single_mission "$mf" "$mname"
                        found=true
                    fi
                done
            fi
        done

        if ! $found; then
            echo -e "  🟢 $NOW チェック... 新着なし"
        fi

        sleep $INTERVAL
    done
}
