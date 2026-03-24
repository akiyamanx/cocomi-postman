#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2012,SC1090,SC2001,SC2129
# このファイルは: COCOMI Postman タブレット支店（本店）
# タブレットのTermuxで動く実行管理メインスクリプト
# v1.1 修正 2026-02-18 - git pushをClaude Code外で実行する設計に変更
# v1.2 修正 2026-02-19 - config.json動的参照＋postman自身プロジェクト登録
# v1.3 追加 2026-02-19 - LINE Messaging API通知機能
# v1.4 修正 2026-02-19 - ShellCheck対応＋execute_missionリファクタリング
# v2.0 追加 2026-02-22 - ステップ実行エンジン読み込み
# v2.1 追加 2026-02-26 - ログ・履歴機能（core/logger.sh連携）
# v2.2 追加 2026-02-26 - プロジェクト管理機能（core/project-manager.sh + config-helper.py連携）
# v2.3 追加 2026-02-26 - 設定管理機能（core/settings.sh連携）
# v2.4 修正 2026-03-25 - プロジェクトID検索バグ修正（MCP Phase2テスト。grep対象を"ID": {に限定し誤マッチ防止）

# === 設定 ===
POSTMAN_DIR="$HOME/cocomi-postman"
CONFIG_FILE="$POSTMAN_DIR/config.json"
CURRENT_PROJECT=""
CURRENT_PROJECT_NAME=""
CURRENT_REPO_PATH=""

# === 色の定義 ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# === 初期化 ===
init() {
    if [ ! -d "$POSTMAN_DIR" ]; then
        echo -e "${RED}❌ cocomi-postmanフォルダが見つかりません${NC}"
        echo "先にGitHubからクローンしてください："
        echo "  cd ~ && git clone https://github.com/akiyamanx/cocomi-postman.git"
        exit 1
    fi
    cd "$POSTMAN_DIR" || exit 1

    # デフォルトプロジェクト読み込み
    CURRENT_PROJECT=$(grep '"default_project"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/')
    [ -z "$CURRENT_PROJECT" ] && CURRENT_PROJECT="genba-pro"
    load_project_info
}

# === config.jsonからプロジェクト情報を読み込む ===
# v1.2修正 - ハードコードからconfig.json参照に変更
# v2.4修正 - grep対象を"ID": {に限定（postman_repoキー等との誤マッチ防止）
load_project_info() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ config.jsonが見つかりません${NC}"
        echo "config.jsonを作成してください"
        CURRENT_PROJECT_NAME="$CURRENT_PROJECT"
        CURRENT_REPO_PATH=""
        return
    fi

    # config.jsonからプロジェクト名を取得（v2.4修正: ": {"で厳密マッチ）
    CURRENT_PROJECT_NAME=$(grep -A5 "\"$CURRENT_PROJECT\": {" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)

    # config.jsonからローカルパスを取得（$HOMEを展開）
    local raw_path
    raw_path=$(grep -A5 "\"$CURRENT_PROJECT\": {" "$CONFIG_FILE" | grep '"local_path"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
    CURRENT_REPO_PATH="${raw_path//\$HOME/$HOME}"

    # 取得できなかった場合のフォールバック
    if [ -z "$CURRENT_PROJECT_NAME" ]; then
        CURRENT_PROJECT_NAME="$CURRENT_PROJECT"
    fi
    if [ -z "$CURRENT_REPO_PATH" ]; then
        echo -e "${YELLOW}⚠️ プロジェクト '$CURRENT_PROJECT' のパスがconfig.jsonに見つかりません${NC}"
    fi
}

# === config.jsonからプロジェクトID一覧を取得 ===
# v1.2追加 - 動的プロジェクト一覧
get_project_ids() {
    # "name"の直前行にあるプロジェクトIDキーを抽出
    grep -B1 '"name"' "$CONFIG_FILE" | grep '": {' | sed 's/.*"\([^"]*\)".*/\1/'
}

# === メインメニュー表示 ===
show_menu() {
    clear
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📮 COCOMI Postman タブレット支店（本店）${NC}"
    echo ""
    echo -e "  📂 現在: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} → 📬 受信BOX確認"
    echo -e "  ${GREEN}2${NC} → 🏭 ミッション実行"
    echo -e "  ${GREEN}3${NC} → 📋 レポート管理"
    echo -e "  ${GREEN}4${NC} → 📊 ダッシュボード"
    echo -e "  ${GREEN}5${NC} → 🔨 Claude Code直接操作"
    echo -e "  ${GREEN}6${NC} → 🔄 プロジェクト切替"
    echo -e "  ${GREEN}7${NC} → 📜 ログ・履歴"
    echo -e "  ${GREEN}8${NC} → 🗂️ プロジェクト管理"
    echo -e "  ${GREEN}9${NC} → ⚙️ 設定"
    echo -e "  ${GREEN}0${NC} → 🌙 自動モード（放置運転）"
    echo -e "  ${RED}q${NC} → 終了"
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -n "  番号を選んでね → "
}

# === 1. 受信BOX確認 ===
check_inbox() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📬 受信BOX${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # git pullで最新取得
    cd "$POSTMAN_DIR" || return
    echo -e "  ${YELLOW}📡 GitHubから最新を取得中...${NC}"
    git pull origin main > /dev/null 2>&1
    echo ""

    local MISSION_DIR="$POSTMAN_DIR/missions/$CURRENT_PROJECT"
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"

    # 全ミッションを確認し、レポートがないものを「未実行」とする
    local has_pending=false

    echo -e "  ${BOLD}📂 ${CURRENT_PROJECT_NAME} のミッション${NC}"
    echo ""

    if [ -d "$MISSION_DIR" ] && ls "$MISSION_DIR"/M-*.md &>/dev/null; then
        for mission_file in "$MISSION_DIR"/M-*.md; do
            local mname
            mname=$(basename "$mission_file" .md)
            local rname="R-${mname#M-}"

            if [ -f "$REPORT_DIR/${rname}.md" ]; then
                echo -e "    ${GREEN}✅${NC} $mname （完了）"
            elif [ -f "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${mname#M-}.md" ]; then
                echo -e "    ${RED}❌${NC} $mname （エラー）"
            else
                echo -e "    ${YELLOW}📬 $mname （新着！未実行）${NC}"
                has_pending=true
            fi
        done
    else
        echo -e "    ${YELLOW}📭 ミッションはまだないよ${NC}"
    fi

    echo ""
    if $has_pending; then
        echo -e "  ${GREEN}未実行のミッションがあるよ！${NC}"
        echo "  「2」でミッション実行に進めるよ"
    fi

    echo ""
    echo "  ミッション内容を見る？ (ファイル名を入力 / Enter でメニュー)"
    read -r CHOICE
    if [ -n "$CHOICE" ]; then
        local TARGET="$MISSION_DIR/${CHOICE}.md"
        [ ! -f "$TARGET" ] && TARGET="$MISSION_DIR/$CHOICE"
        if [ -f "$TARGET" ]; then
            echo ""
            cat "$TARGET"
        else
            echo -e "${RED}  ファイルが見つからないよ${NC}"
        fi
        echo ""
        echo "  Enter でメニューに戻る"
        read -r
    fi
}

# === 2. ミッション実行 ===
# v1.4修正 - run_single_missionを呼び出すリファクタリング
execute_mission() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🏭 ミッション実行${NC}"
    echo -e "  📂 対象: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # git pull
    cd "$POSTMAN_DIR" || return
    git pull origin main > /dev/null 2>&1

    local MISSION_DIR="$POSTMAN_DIR/missions/$CURRENT_PROJECT"
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    mkdir -p "$REPORT_DIR"

    # 未実行ミッション一覧
    local pending_missions=()
    local i=1

    if [ -d "$MISSION_DIR" ]; then
        for mission_file in "$MISSION_DIR"/M-*.md; do
            [ -f "$mission_file" ] || continue
            local mname
            mname=$(basename "$mission_file" .md)
            local rname="R-${mname#M-}"
            if [ ! -f "$REPORT_DIR/${rname}.md" ] && [ ! -f "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${mname#M-}.md" ]; then
                echo -e "  ${GREEN}${i}${NC}. ${YELLOW}$mname${NC}"
                head -5 "$mission_file" | sed 's/^/     /'
                echo ""
                pending_missions+=("$mission_file")
                i=$((i + 1))
            fi
        done
    fi

    if [ ${#pending_missions[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}📭 未実行のミッションはないよ${NC}"
        echo "  スマホ支店から指示書を送ってね！"
        echo ""
        echo "  Enter でメニューに戻る"
        read -r
        return
    fi

    echo -n "  実行する番号を選んでね → "
    read -r CHOICE

    # 番号バリデーション
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#pending_missions[@]} ]; then
        echo -e "${RED}  無効な番号だよ${NC}"
        sleep 1
        return
    fi

    local TARGET_MISSION="${pending_missions[$((CHOICE - 1))]}"
    local MISSION_NAME
    MISSION_NAME=$(basename "$TARGET_MISSION" .md)

    echo ""
    echo -e "${GREEN}  🚀 ミッション実行開始: ${MISSION_NAME}${NC}"
    echo ""

    # run_single_missionを使って実行（executor.shで定義）
    run_single_mission "$TARGET_MISSION" "$MISSION_NAME"

    echo ""
    echo "  Enter でメニューに戻る"
    read -r
}

# === 3. レポート管理 ===
manage_reports() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📋 レポート管理${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local ERROR_DIR="$POSTMAN_DIR/errors/$CURRENT_PROJECT"

    echo -e "  ${GREEN}✅ 完了レポート:${NC}"
    if [ -d "$REPORT_DIR" ] && [ "$(ls -A "$REPORT_DIR" 2>/dev/null)" ]; then
        ls -t "$REPORT_DIR"/*.md 2>/dev/null | head -10 | while read -r f; do
            echo "    🟢 $(basename "$f")"
        done
    else
        echo "    なし"
    fi

    echo ""
    echo -e "  ${RED}❌ エラーレポート:${NC}"
    if [ -d "$ERROR_DIR" ] && [ "$(ls -A "$ERROR_DIR" 2>/dev/null)" ]; then
        ls -t "$ERROR_DIR"/*.md 2>/dev/null | head -10 | while read -r f; do
            echo "    🔴 $(basename "$f")"
        done
    else
        echo "    なし"
    fi

    echo ""
    echo "  ファイル名を入力で詳細表示 / Enter でメニュー"
    read -r CHOICE
    if [ -n "$CHOICE" ]; then
        for dir in "$REPORT_DIR" "$ERROR_DIR"; do
            [ -f "$dir/$CHOICE" ] && cat "$dir/$CHOICE" && break
            [ -f "$dir/${CHOICE}.md" ] && cat "$dir/${CHOICE}.md" && break
        done
        echo ""
        echo "  Enter でメニューに戻る"
        read -r
    fi
}

# === 4. ダッシュボード ===
# v2.4修正 - grep対象を"ID": {に限定
show_dashboard() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📊 COCOMI ダッシュボード（本店）${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    cd "$POSTMAN_DIR" || return
    git pull origin main > /dev/null 2>&1

    # v1.2修正 - config.jsonから動的にプロジェクト一覧を取得
    while IFS= read -r proj; do
        local pname
        pname=$(grep -A5 "\"$proj\": {" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)

        local missions
        missions=$(find "$POSTMAN_DIR/missions/$proj" -name "M-*.md" 2>/dev/null | wc -l)
        local reports
        reports=$(find "$POSTMAN_DIR/reports/$proj" -name "R-*.md" 2>/dev/null | wc -l)
        local errors
        errors=$(find "$POSTMAN_DIR/errors/$proj" -name "E-*.md" 2>/dev/null | wc -l)
        local ideas
        ideas=$(find "$POSTMAN_DIR/ideas/$proj" -name "*.md" 2>/dev/null | wc -l)

        echo -e "  ${BOLD}📂 ${pname}${NC}"
        echo "     📝ミッション:${missions} ✅完了:${reports} ❌エラー:${errors} 💡アイデア:${ideas}"
        echo ""
    done < <(get_project_ids)

    echo "  Enter でメニューに戻る"
    read -r
}

# === 5. Claude Code直接操作 ===
direct_claude() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🔨 Claude Code 直接操作${NC}"
    echo -e "  📂 対象: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. 🆕 新規セッション"
    echo -e "  ${GREEN}2${NC}. ▶️ 前回の続き（--continue）"
    echo -e "  ${GREEN}3${NC}. 📂 セッション選択（--resume）"
    echo ""
    echo -n "  → "
    read -r CHOICE

    if [ -z "$CURRENT_REPO_PATH" ] || [ ! -d "$CURRENT_REPO_PATH" ]; then
        echo -e "${RED}  ❌ プロジェクトのリポジトリが見つかりません${NC}"
        echo "  パス: $CURRENT_REPO_PATH"
        echo "  Enter でメニューに戻る"
        read -r
        return
    fi

    cd "$CURRENT_REPO_PATH" || return
    echo ""
    echo -e "${YELLOW}  📂 ${CURRENT_REPO_PATH} に移動しました${NC}"
    echo -e "${YELLOW}  🤖 Claude Codeを起動します...${NC}"
    echo -e "${YELLOW}  /exit で郵便屋さんに戻れるよ${NC}"
    echo ""

    case "$CHOICE" in
        1) claude ;;
        2) claude --continue ;;
        3) claude --resume ;;
        *) claude ;;
    esac

    # Claude Code終了後、postmanディレクトリに戻る
    cd "$POSTMAN_DIR" || return
}

# === 6. プロジェクト切替 ===
# v1.2修正 - config.jsonから動的にプロジェクト一覧を表示
# v2.4修正 - grep対象を"ID": {に限定
switch_project() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🔄 プロジェクト切替${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # config.jsonからプロジェクト一覧を取得
    local proj_ids=()
    local i=1
    while IFS= read -r pid; do
        proj_ids+=("$pid")
        local pname
        pname=$(grep -A5 "\"$pid\": {" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
        local mark=""
        [ "$CURRENT_PROJECT" = "$pid" ] && mark=" ⭐"
        echo -e "  ${GREEN}${i}${NC}. ${pname}${mark}"
        i=$((i + 1))
    done < <(get_project_ids)

    echo ""
    echo -n "  → "
    read -r CHOICE

    # 番号バリデーション
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#proj_ids[@]} ]; then
        echo -e "${RED}  無効${NC}"; sleep 1; return
    fi

    CURRENT_PROJECT="${proj_ids[$((CHOICE - 1))]}"
    load_project_info
    echo -e "  ${GREEN}✅ ${CURRENT_PROJECT_NAME} に切り替えたよ！${NC}"
    sleep 1
}

# v1.3追加 - LINE通知モジュール読み込み
NOTIFIER_SCRIPT="$POSTMAN_DIR/core/notifier.sh"
if [ -f "$NOTIFIER_SCRIPT" ]; then
    # shellcheck source=core/notifier.sh
    source "$NOTIFIER_SCRIPT"
fi

# === 実行エンジン読み込み ===
# shellcheck source=core/executor.sh
source "$POSTMAN_DIR/core/executor.sh"

# v2.0追加 - ステップ実行エンジン読み込み
# shellcheck source=core/step-runner.sh
if [ -f "$POSTMAN_DIR/core/step-runner.sh" ]; then
    source "$POSTMAN_DIR/core/step-runner.sh"
fi

# v2.1追加 - ログ・履歴モジュール読み込み
# shellcheck source=core/logger.sh
if [ -f "$POSTMAN_DIR/core/logger.sh" ]; then
    source "$POSTMAN_DIR/core/logger.sh"
fi

# v2.2追加 - プロジェクト管理モジュール読み込み
# shellcheck source=core/project-manager.sh
if [ -f "$POSTMAN_DIR/core/project-manager.sh" ]; then
    source "$POSTMAN_DIR/core/project-manager.sh"
fi

# v2.3追加 - 設定管理モジュール読み込み
# shellcheck source=core/settings.sh
if [ -f "$POSTMAN_DIR/core/settings.sh" ]; then
    source "$POSTMAN_DIR/core/settings.sh"
fi

# === プレースホルダー ===
coming_soon() {
    echo ""
    echo -e "${YELLOW}  🚧 $1 は次のバージョンで追加予定！${NC}"
    echo "  Enter でメニューに戻る"
    read -r
}

# === メインループ ===
init

while true; do
    show_menu
    read -r choice
    case "$choice" in
        1) check_inbox ;;
        2) execute_mission ;;
        3) manage_reports ;;
        4) show_dashboard ;;
        5) direct_claude ;;
        6) switch_project ;;
        7) show_logs ;;
        8) manage_projects ;;
        9) show_settings ;;
        0) auto_mode ;;
        q|Q)
            echo ""
            echo -e "${GREEN}  📮 本店閉店！お疲れ様！${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}  無効な番号だよ${NC}"
            sleep 1
            ;;
    esac
done