#!/bin/bash
# このファイルは: COCOMI Postman タブレット支店（本店）
# タブレットのTermuxで動く実行管理メインスクリプト
# v1.1 修正 2026-02-18 - git pushをClaude Code外で実行する設計に変更

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
    cd "$POSTMAN_DIR"

    # デフォルトプロジェクト読み込み
    CURRENT_PROJECT=$(grep '"default_project"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*: *"\(.*\)".*/\1/')
    [ -z "$CURRENT_PROJECT" ] && CURRENT_PROJECT="genba-pro"
    load_project_info
}

# === プロジェクト情報を読み込む ===
load_project_info() {
    case "$CURRENT_PROJECT" in
        "genba-pro")
            CURRENT_PROJECT_NAME="現場Pro設備くん"
            CURRENT_REPO_PATH="$HOME/GenbaProSetsubikunN"
            ;;
        "culo-chan")
            CURRENT_PROJECT_NAME="CULOchanKAIKEIpro"
            CURRENT_REPO_PATH="$HOME/akiyamanx.github.io/CULOchanKAIKEIpro"
            ;;
        "maintenance-map")
            CURRENT_PROJECT_NAME="メンテナンスマップ"
            CURRENT_REPO_PATH="$HOME/akiyamanx.github.io/maintenance-map-ap"
            ;;
        *)
            CURRENT_PROJECT_NAME="$CURRENT_PROJECT"
            CURRENT_REPO_PATH=""
            ;;
    esac
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
    cd "$POSTMAN_DIR"
    echo -e "  ${YELLOW}📡 GitHubから最新を取得中...${NC}"
    git pull origin main > /dev/null 2>&1
    echo ""

    local MISSION_DIR="$POSTMAN_DIR/missions/$CURRENT_PROJECT"
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"

    # 全ミッションを確認し、レポートがないものを「未実行」とする
    local has_pending=false
    local has_done=false

    echo -e "  ${BOLD}📂 ${CURRENT_PROJECT_NAME} のミッション${NC}"
    echo ""

    if [ -d "$MISSION_DIR" ] && [ "$(ls "$MISSION_DIR"/M-*.md 2>/dev/null)" ]; then
        for mission_file in $(ls -t "$MISSION_DIR"/M-*.md 2>/dev/null); do
            local mname=$(basename "$mission_file" .md)
            local rname="R-${mname#M-}"

            if [ -f "$REPORT_DIR/${rname}.md" ]; then
                echo -e "    ${GREEN}✅${NC} $mname （完了）"
                has_done=true
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
        read
    fi
}

# === 2. ミッション実行 ===
execute_mission() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🏭 ミッション実行${NC}"
    echo -e "  📂 対象: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # git pull
    cd "$POSTMAN_DIR"
    git pull origin main > /dev/null 2>&1

    local MISSION_DIR="$POSTMAN_DIR/missions/$CURRENT_PROJECT"
    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    mkdir -p "$REPORT_DIR"

    # 未実行ミッション一覧
    local pending_missions=()
    local i=1

    if [ -d "$MISSION_DIR" ]; then
        for mission_file in $(ls -t "$MISSION_DIR"/M-*.md 2>/dev/null); do
            local mname=$(basename "$mission_file" .md)
            local rname="R-${mname#M-}"
            if [ ! -f "$REPORT_DIR/${rname}.md" ] && [ ! -f "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${mname#M-}.md" ]; then
                echo -e "  ${GREEN}${i}${NC}. ${YELLOW}$mname${NC}"
                # 指示書の最初の数行を表示
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
        read
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
    local MISSION_NAME=$(basename "$TARGET_MISSION" .md)

    echo ""
    echo -e "${GREEN}  🚀 ミッション実行開始: ${MISSION_NAME}${NC}"
    echo ""

    # プロジェクトリポジトリに移動
    if [ -z "$CURRENT_REPO_PATH" ] || [ ! -d "$CURRENT_REPO_PATH" ]; then
        echo -e "${RED}  ❌ プロジェクトのリポジトリが見つかりません${NC}"
        echo "  パス: $CURRENT_REPO_PATH"
        echo "  Enter でメニューに戻る"
        read
        return
    fi

    # 実行ログ開始
    local LOG_FILE="$POSTMAN_DIR/logs/execution/$(date +%Y%m%d-%H%M)-${MISSION_NAME}.log"
    mkdir -p "$POSTMAN_DIR/logs/execution"
    echo "=== ミッション実行ログ ===" > "$LOG_FILE"
    echo "開始: $(date)" >> "$LOG_FILE"
    echo "ミッション: $MISSION_NAME" >> "$LOG_FILE"
    echo "プロジェクト: $CURRENT_PROJECT_NAME" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # プロジェクトディレクトリへ移動してgit pull
    cd "$CURRENT_REPO_PATH"
    echo -e "  ${YELLOW}📡 プロジェクトを最新に更新中...${NC}"
    git pull origin main >> "$LOG_FILE" 2>&1

    # v1.1変更: Claude Codeにはgitをさせない（/tmp権限問題回避）
    echo -e "  ${YELLOW}🤖 Claude Codeに指示書を渡します...${NC}"
    echo ""
    echo -e "${MAGENTA}━━━ Claude Code 実行中 ━━━${NC}"
    echo ""

    cat "$TARGET_MISSION" | claude -p --allowedTools "Read,Write,Edit,Bash(cat *),Bash(ls *),Bash(find *),Bash(head *),Bash(tail *),Bash(wc *),Bash(grep *),Bash(node *),Bash(npm *)" 2>&1 | tee -a "$LOG_FILE"

    local EXIT_CODE=$?

    echo ""
    echo -e "${MAGENTA}━━━ Claude Code 完了 ━━━${NC}"
    echo ""

    # v1.1: Postmanがgit push（Claude Codeの外で実行）
    local REPORT_NAME="R-${MISSION_NAME#M-}"

    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}  🤖 Claude Code作業完了！${NC}"

        # プロジェクトリポジトリをgit push
        echo -e "  ${YELLOW}📮 Postmanがgit pushします...${NC}"
        cd "$CURRENT_REPO_PATH"
        git add -A
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "📮 $MISSION_NAME by COCOMI Postman" > /dev/null 2>&1
            git push origin main > /dev/null 2>&1 && \
                echo -e "${GREEN}  📮 プロジェクトgit push完了${NC}" || \
                echo -e "${RED}  ⚠️ git pushに失敗${NC}"
        fi

        cat > "$REPORT_DIR/${REPORT_NAME}.md" << EOF
# ✅ ミッション完了レポート
- **ミッション:** ${MISSION_NAME}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **完了日時:** $(date '+%Y-%m-%d %H:%M')
- **結果:** 成功
EOF
        echo -e "${GREEN}  ✅ ミッション完了！${NC}"
    else
        # エラーでも途中成果をpush
        cd "$CURRENT_REPO_PATH"
        git add -A
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "⚠️ $MISSION_NAME 途中成果" > /dev/null 2>&1
            git push origin main > /dev/null 2>&1
        fi

        mkdir -p "$POSTMAN_DIR/errors/$CURRENT_PROJECT"
        cat > "$POSTMAN_DIR/errors/$CURRENT_PROJECT/E-${MISSION_NAME#M-}.md" << EOF
# ❌ エラーレポート
- **ミッション:** ${MISSION_NAME}
- **プロジェクト:** ${CURRENT_PROJECT_NAME}
- **発生日時:** $(date '+%Y-%m-%d %H:%M')
- **終了コード:** ${EXIT_CODE}
EOF
        echo -e "${RED}  ❌ エラー発生。レポート作成済み${NC}"
    fi

    # レポートをgit push（Postmanリポジトリ）
    cd "$POSTMAN_DIR"
    echo "完了: $(date)" >> "$LOG_FILE"
    git add -A
    git commit -m "📋 レポート: ${CURRENT_PROJECT}/${REPORT_NAME}" > /dev/null 2>&1
    git push origin main > /dev/null 2>&1

    echo -e "${GREEN}  📮 レポートをスマホ支店に送りました！${NC}"
    echo ""
    echo "  Enter でメニューに戻る"
    read
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
        ls -t "$REPORT_DIR"/*.md 2>/dev/null | head -10 | while read f; do
            echo "    🟢 $(basename "$f")"
        done
    else
        echo "    なし"
    fi

    echo ""
    echo -e "  ${RED}❌ エラーレポート:${NC}"
    if [ -d "$ERROR_DIR" ] && [ "$(ls -A "$ERROR_DIR" 2>/dev/null)" ]; then
        ls -t "$ERROR_DIR"/*.md 2>/dev/null | head -10 | while read f; do
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
        read
    fi
}

# === 4. ダッシュボード ===
show_dashboard() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📊 COCOMI ダッシュボード（本店）${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    cd "$POSTMAN_DIR"
    git pull origin main > /dev/null 2>&1

    for proj in genba-pro culo-chan maintenance-map; do
        local pname=""
        case "$proj" in
            "genba-pro") pname="現場Pro設備くん  " ;;
            "culo-chan") pname="CULOchanKAIKEIpro" ;;
            "maintenance-map") pname="メンテナンスマップ " ;;
        esac

        local missions=$(ls "$POSTMAN_DIR/missions/$proj"/M-*.md 2>/dev/null | wc -l)
        local reports=$(ls "$POSTMAN_DIR/reports/$proj"/R-*.md 2>/dev/null | wc -l)
        local errors=$(ls "$POSTMAN_DIR/errors/$proj"/E-*.md 2>/dev/null | wc -l)
        local ideas=$(ls "$POSTMAN_DIR/ideas/$proj"/*.md 2>/dev/null | wc -l)

        echo -e "  ${BOLD}📂 ${pname}${NC}"
        echo "     📝ミッション:${missions} ✅完了:${reports} ❌エラー:${errors} 💡アイデア:${ideas}"
        echo ""
    done

    echo "  Enter でメニューに戻る"
    read
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
        read
        return
    fi

    cd "$CURRENT_REPO_PATH"
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
    cd "$POSTMAN_DIR"
}

# === 6. プロジェクト切替 ===
switch_project() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🔄 プロジェクト切替${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local mark1="" mark2="" mark3=""
    [ "$CURRENT_PROJECT" = "genba-pro" ] && mark1=" ⭐"
    [ "$CURRENT_PROJECT" = "culo-chan" ] && mark2=" ⭐"
    [ "$CURRENT_PROJECT" = "maintenance-map" ] && mark3=" ⭐"

    echo -e "  ${GREEN}1${NC}. 現場Pro設備くん${mark1}"
    echo -e "  ${GREEN}2${NC}. CULOchanKAIKEIpro${mark2}"
    echo -e "  ${GREEN}3${NC}. メンテナンスマップ${mark3}"
    echo ""
    echo -n "  → "
    read -r CHOICE

    case "$CHOICE" in
        1) CURRENT_PROJECT="genba-pro" ;;
        2) CURRENT_PROJECT="culo-chan" ;;
        3) CURRENT_PROJECT="maintenance-map" ;;
        *) echo -e "${RED}  無効${NC}"; sleep 1; return ;;
    esac

    load_project_info
    echo -e "  ${GREEN}✅ ${CURRENT_PROJECT_NAME} に切り替えたよ！${NC}"
    sleep 1
}

# === 実行エンジン読み込み ===
source "$POSTMAN_DIR/core/executor.sh"

# === プレースホルダー ===
coming_soon() {
    echo ""
    echo -e "${YELLOW}  🚧 $1 は次のバージョンで追加予定！${NC}"
    echo "  Enter でメニューに戻る"
    read
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
        7) coming_soon "ログ・履歴" ;;
        8) coming_soon "プロジェクト管理" ;;
        9) coming_soon "設定" ;;
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
