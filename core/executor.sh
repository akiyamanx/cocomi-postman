#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2012
# このファイルは: COCOMI Postman 自動モード＆ミッション実行エンジン
# postman.shから呼ばれる実行系機能
# v1.1 修正 2026-02-18 - git pushをClaude Code外で実行する設計に変更
# v1.2 修正 2026-02-19 - auto_modeのプロジェクトループをconfig.json動的化
# v1.3 追加 2026-02-19 - LINE通知呼び出し追加
# v1.4 修正 2026-02-19 - ShellCheck対応
# v1.5 修正 2026-02-20 - Phase C: リトライ機構統合（retry.sh連携）
# v1.6 修正 2026-02-21 - git push競合対策（pull --rebase+リトライ追加）
# v2.0 追加 2026-02-22 - ステップ実行判定分岐（step-runner.sh連携）
# v2.1 追加 2026-02-25 - 安全バリデーション（missionタグ検証）＆auto_modeメニュー復帰キー
# /tmp権限問題の回避: git操作は全てPostman（Termux直接）が行う

# === v2.1追加 - ミッション指示書バリデーション（安全弁） ===
# 指示書に <!-- mission: project-id --> ヘッダーがあるか検証する
# ヘッダーがない指示書は誤認識の可能性があるため実行を拒否する
# 引数: $1 = 指示書ファイルパス
# 出力: project-id（成功時）/ "INVALID"（失敗時）
# 戻り値: 0 = 有効, 1 = 無効
validate_mission() {
    local mission_file="$1"

    # 先頭10行から <!-- mission: xxx --> を抽出
    local mission_tag
    mission_tag=$(head -10 "$mission_file" | grep -oP '<!--\s*mission:\s*\K[^\s]+(?=\s*-->)' 2>/dev/null)

    # grepが-Pに対応してない場合のフォールバック（Termux対策）
    if [ -z "$mission_tag" ]; then
        mission_tag=$(head -10 "$mission_file" | sed -n 's/.*<!--[[:space:]]*mission:[[:space:]]*\([^[:space:]]*\)[[:space:]]*-->.*/\1/p' | head -1)
    fi

    if [ -z "$mission_tag" ]; then
        echo "INVALID"
        return 1
    fi

    # プロジェクトIDがconfig.jsonに存在するか確認
    if ! get_project_ids | grep -q "^${mission_tag}$"; then
        echo "UNKNOWN:${mission_tag}"
        return 1
    fi

    echo "$mission_tag"
    return 0
}

# === v2.1追加 - バリデーション失敗時のLINE通知＆inbox退避 ===
handle_invalid_mission() {
    local mission_file="$1"
    local mission_name="$2"
    local validation_result="$3"

    local message=""
    if [ "$validation_result" = "INVALID" ]; then
        message="⚠️ 無効な指示書を検出しました

📄 ファイル: ${mission_name}
❌ 原因: <!-- mission: project-id --> ヘッダーがありません

🛡️ 安全のため実行をスキップしました。
正しい指示書を送り直してね！

💡 ヒント: クロちゃんが作る指示書には自動でヘッダーが付くよ。
LINEテキスト指示は「プロジェクト名: 内容」形式で送ってね。"
    else
        # UNKNOWN:xxx の場合
        local unknown_id="${validation_result#UNKNOWN:}"
        message="⚠️ 不明なプロジェクトIDの指示書です

📄 ファイル: ${mission_name}
❓ プロジェクトID: ${unknown_id}
❌ config.jsonに登録されていません

🛡️ 安全のため実行をスキップしました。"
    fi

    # LINE通知
    if type send_line_notify &>/dev/null; then
        send_line_notify "$message"
    fi

    # 指示書をinboxに退避（実行済みにはしない）
    local inbox_dir="$POSTMAN_DIR/inbox/rejected"
    mkdir -p "$inbox_dir"
    cp "$mission_file" "$inbox_dir/$(basename "$mission_file")"

    echo -e "  ${RED}🛡️ 指示書を拒否: ${mission_name} (${validation_result})${NC}"
    echo -e "  ${YELLOW}📥 inbox/rejected/ に退避しました${NC}"
}

# === プロジェクトリポジトリのgit push（Termuxから直接実行） ===
git_push_project() {
    local REPO_PATH=$1
    local COMMIT_MSG=$2

    if [ -n "$REPO_PATH" ] && [ -d "$REPO_PATH" ]; then
        cd "$REPO_PATH" || return 1
        git add -A
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "$COMMIT_MSG" > /dev/null 2>&1
            # v1.6追加 - push前にリモート同期（スマホとの競合防止）
            git pull --rebase origin main > /dev/null 2>&1
            if git push origin main > /dev/null 2>&1; then
                echo -e "  ${GREEN}📮 プロジェクトをgit push完了${NC}"
                return 0
            else
                # v1.6追加 - 1回リトライ
                git pull --rebase origin main > /dev/null 2>&1
                if git push origin main > /dev/null 2>&1; then
                    echo -e "  ${GREEN}📮 プロジェクトをgit push完了（リトライ成功）${NC}"
                    return 0
                else
                    echo -e "  ${RED}⚠️ プロジェクトのgit pushに失敗${NC}"
                    return 1
                fi
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
        # v1.6追加 - push前にリモート同期（スマホとの競合防止）
        git pull --rebase origin main > /dev/null 2>&1
        if git push origin main > /dev/null 2>&1; then
            echo -e "  ${GREEN}📮 レポートをスマホ支店に送りました${NC}"
        else
            # v1.6追加 - 1回リトライ
            git pull --rebase origin main > /dev/null 2>&1
            if git push origin main > /dev/null 2>&1; then
                echo -e "  ${GREEN}📮 レポートをスマホ支店に送りました（リトライ成功）${NC}"
            else
                echo -e "  ${RED}⚠️ レポートのgit pushに失敗${NC}"
            fi
        fi
    fi
}

# === 単一ミッション実行 ===
# v2.1修正 - バリデーション追加
run_single_mission() {
    local MISSION_FILE=$1
    local MISSION_NAME=$2
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local LOG_FILE
    LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}.log"

    mkdir -p "$REPORT_DIR" "$POSTMAN_DIR/logs/execution"

    # v2.1追加 - 安全バリデーション（missionタグ検証）
    echo -e "  ${CYAN}🛡️ 指示書バリデーション中...${NC}"
    local validation_result
    validation_result=$(validate_mission "$MISSION_FILE")
    local validation_code=$?

    if [ $validation_code -ne 0 ]; then
        handle_invalid_mission "$MISSION_FILE" "$MISSION_NAME" "$validation_result"
        return 1
    fi

    # v2.1追加 - バリデーション通過後、ヘッダーのプロジェクトIDとフォルダを照合
    local header_project="$validation_result"
    if [ "$header_project" != "$CURRENT_PROJECT" ]; then
        echo -e "  ${YELLOW}🔄 ヘッダーのプロジェクト(${header_project})に自動切替${NC}"
        CURRENT_PROJECT="$header_project"
        load_project_info
    fi

    echo -e "  ${GREEN}🛡️ バリデーション通過: ${header_project}${NC}"

    # v2.0追加 - ステップ実行判定
    # 指示書に ### Step N/M 記法があればステップ実行モードへ分岐
    if has_steps "$MISSION_FILE"; then
        echo -e "  ${CYAN}📋 ステップ付き指示書を検出！ステップ実行モードに切り替えます${NC}"
        run_step_mission "$MISSION_FILE" "$MISSION_NAME"
        return $?
    fi

    {
        echo "=== ミッション実行ログ ==="
        echo "開始: $(date)"
        echo "プロジェクト: $CURRENT_PROJECT_NAME"
        echo "バリデーション: OK (mission: $header_project)"
    } > "$LOG_FILE"

    if [ -n "$CURRENT_REPO_PATH" ] && [ -d "$CURRENT_REPO_PATH" ]; then
        # STEP 1: プロジェクトを最新に
        cd "$CURRENT_REPO_PATH" || return 1
        echo -e "  ${YELLOW}📡 git pull中...${NC}"
        git pull origin main >> "$LOG_FILE" 2>&1

        # STEP 2: Claude Codeで作業（リトライ機構付き）
        echo -e "  ${YELLOW}🤖 Claude Code実行中...${NC}"
        # v1.5 retry.sh読み込み＆リトライ付き実行
        # shellcheck source=core/retry.sh
        source "$POSTMAN_DIR/core/retry.sh"
        run_with_retry "$MISSION_FILE" "$MISSION_NAME" "$LOG_FILE" "$CURRENT_REPO_PATH"
        local EXIT_CODE=$?

        # STEP 3: Postmanがgit push（/tmp問題回避）
        local REPORT_NAME="R-${MISSION_NAME#M-}"
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "  ${GREEN}🤖 Claude Code作業完了！${NC}"
            git_push_project "$CURRENT_REPO_PATH" "📮 $MISSION_NAME by COCOMI Postman"

            # v1.5修正 - リトライ回数をレポートに含める
            local RETRY_INFO=""
            if [ "$RETRY_COUNT" -gt 0 ]; then
                RETRY_INFO="（リトライ${RETRY_COUNT}回目で成功）"
            fi

            # v1.5修正 - 成功時も二層構造レポート（作業サマリー付き）
            cat > "$REPORT_DIR/${REPORT_NAME}.md" << EOF
# ✅ Mission Report: ${MISSION_NAME}

## 📱 アキヤ向けサマリー（日本語）
- **状態:** ✅ 成功${RETRY_INFO}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **完了日時:** $(date '+%Y-%m-%d %H:%M')

---

## 🤖 AI Work Summary (for Claude/Gemini/GPT)

### Execution Context
- **Mission:** ${MISSION_NAME}
- **Project:** ${CURRENT_PROJECT_NAME}
- **Validated:** mission tag = ${header_project}
- **Retry attempts:** ${RETRY_COUNT}/3
- **Timestamp:** $(date '+%Y-%m-%dT%H:%M:%S')

### Claude Code Work Summary
${ANALYSIS}
EOF
            echo -e "  ${GREEN}✅ $MISSION_NAME 完了！${RETRY_INFO}${NC}"

            # v1.3追加 v1.5修正 - LINE通知（成功時）リトライ情報付き
            if type notify_mission_result &>/dev/null; then
                if [ "$RETRY_COUNT" -gt 0 ]; then
                    notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "success" "リトライ${RETRY_COUNT}回目で成功"
                else
                    notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "success"
                fi
            fi
        else
            echo -e "  ${RED}🤖 エラー発生（リトライ済み）${NC}"
            git_push_project "$CURRENT_REPO_PATH" "⚠️ $MISSION_NAME 途中成果"

            # v1.5修正 - retry.shの二層構造エラーレポート生成
            mkdir -p "$POSTMAN_DIR/errors/$CURRENT_PROJECT"
            local ERROR_REPORT_PATH="$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${MISSION_NAME#M-}.md"
            generate_error_report "$MISSION_NAME" "$CURRENT_PROJECT_NAME" "$RETRY_COUNT" "$CONTINUE_TRIED" "$ANALYSIS" "$LOG_FILE" "$ERROR_REPORT_PATH"

            echo -e "  ${RED}❌ $MISSION_NAME エラー（リトライ${RETRY_COUNT}回実施済み）${NC}"

            # v1.3追加 v1.5修正 - LINE通知（エラー時）リトライ情報付き
            if type notify_mission_result &>/dev/null; then
                notify_mission_result "$CURRENT_PROJECT_NAME" "$MISSION_NAME" "error" "リトライ${RETRY_COUNT}回+continue全て失敗。レポートをクロちゃんに見せてね！"
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
# v2.1修正 - メニュー復帰キー追加（sleep→read -t）＆バリデーション統合
auto_mode() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🌙 自動モード（放置運転）${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  GitHubを定期チェック→新着ミッション自動実行"
    echo "  ※ git pushはPostmanが直接行います"
    echo -e "  ${CYAN}🛡️ missionタグ検証付き（安全モード）${NC}"
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
    # v2.2.2追加 - バックグラウンド維持のためwake lock自動取得
    termux-wake-lock 2>/dev/null
    echo -e "  ${GREEN}🔒 Wake Lock取得（スリープ中も動作継続）${NC}"
    # v2.1変更 - Ctrl+C以外の終了方法を追加
    echo -e "  ${CYAN}💡 m=メニューに戻る / q=終了 / Ctrl+C=強制終了${NC}"
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
                        # v2.1: run_single_mission内でバリデーション実施
                        run_single_mission "$mf" "$mname"
                        found=true
                    fi
                done
            fi
        done < <(get_project_ids)

        if ! $found; then
            echo -e "  🟢 $NOW チェック完了 新着なし"
        fi

        # v2.1追加 - sleep→read -tに変更（キー入力でメニュー復帰）
        echo -e "  ${CYAN}💤 次のチェックまで待機中...（m:メニュー / q:終了）${NC}"
        local input=""
        read -t "$INTERVAL" -n 1 input 2>/dev/null || true
        case "$input" in
            m|M)
                echo ""
                echo -e "  ${GREEN}📮 メニューに戻ります${NC}"
                termux-wake-unlock 2>/dev/null
                return
                ;;
            q|Q)
                echo ""
                echo -e "  ${GREEN}📮 自動モード終了！お疲れ様！${NC}"
                termux-wake-unlock 2>/dev/null
                exit 0
                ;;
        esac
    done
}
