#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2012
# このファイルは: COCOMI Postman スマホ支店（司令官）
# アキヤがスマホのTermuxで使うメインスクリプト
# クロちゃんの部屋と画面分割して使う
# v1.0 作成 2026-02-18
# v1.2 修正 2026-02-19 - config.json動的参照に変更
# v1.4 修正 2026-02-19 - ShellCheck対応
# v1.6 修正 2026-02-21 - git push競合対策（pull --rebase+リトライ追加）
# v1.7 修正 2026-03-25 - プロジェクトID検索バグ修正（grep対象を"ID": {に限定。MCP Phase2）

# === 設定 ===
POSTMAN_DIR="$HOME/cocomi-postman"
CONFIG_FILE="$POSTMAN_DIR/config.json"
CURRENT_PROJECT=""
CURRENT_PROJECT_NAME=""

# === 色の定義 ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # 色リセット
BOLD='\033[1m'

# === 初期化 ===
init() {
    # cocomi-postmanリポジトリの存在確認
    if [ ! -d "$POSTMAN_DIR" ]; then
        echo -e "${RED}❌ cocomi-postmanフォルダが見つかりません${NC}"
        echo "先にGitHubからクローンしてください："
        echo "  cd ~ && git clone https://github.com/akiyamanx/cocomi-postman.git"
        exit 1
    fi
    cd "$POSTMAN_DIR" || exit 1

    # デフォルトプロジェクト読み込み
    if [ -f "$CONFIG_FILE" ]; then
        # jqがなくてもgrepで読める簡易パース
        CURRENT_PROJECT=$(grep '"default_project"' "$CONFIG_FILE" | sed 's/.*: *"\(.*\)".*/\1/')
        load_project_name
    else
        CURRENT_PROJECT="genba-pro"
        CURRENT_PROJECT_NAME="現場Pro設備くん"
    fi
}

# === config.jsonからプロジェクト名を読み込む ===
# v1.2修正 - ハードコードからconfig.json参照に変更
# v1.7修正 - grep対象を"ID": {に限定（誤マッチ防止）
load_project_name() {
    if [ ! -f "$CONFIG_FILE" ]; then
        CURRENT_PROJECT_NAME="$CURRENT_PROJECT"
        return
    fi
    CURRENT_PROJECT_NAME=$(grep -A5 "\"$CURRENT_PROJECT\": {" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
    if [ -z "$CURRENT_PROJECT_NAME" ]; then
        CURRENT_PROJECT_NAME="$CURRENT_PROJECT"
    fi
}

# === config.jsonからプロジェクトID一覧を取得 ===
# v1.2追加 - 動的プロジェクト一覧
get_project_ids() {
    grep -B1 '"name"' "$CONFIG_FILE" | grep '": {' | sed 's/.*"\([^"]*\)".*/\1/'
}

# === メインメニュー表示 ===
show_menu() {
    clear
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📮 COCOMI Postman スマホ支店${NC}"
    echo ""
    echo -e "  📂 現在: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} → 📝 指示書を送る"
    echo -e "  ${GREEN}2${NC} → 📋 レポート確認"
    echo -e "  ${GREEN}3${NC} → 🔄 プロジェクト切替"
    echo -e "  ${GREEN}4${NC} → 📊 ダッシュボード"
    echo -e "  ${GREEN}5${NC} → 💡 アイデアメモ"
    echo -e "  ${GREEN}6${NC} → 🔀 軌道修正"
    echo -e "  ${GREEN}7${NC} → 📂 アイデア振り分け"
    echo -e "  ${GREEN}8${NC} → 📜 開発ヒストリー"
    echo -e "  ${GREEN}9${NC} → 🗺️ プロジェクトマップ"
    echo -e "  ${GREEN}0${NC} → ⚙️ 設定"
    echo -e "  ${RED}q${NC} → 終了"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -n "  番号を選んでね → "
}

# === 1. 指示書を送る ===
send_mission() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📝 指示書送信モード${NC}"
    echo -e "  📂 送り先: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  クロちゃんの指示書を貼り付けて、"
    echo -e "  最後に空行のあと ${GREEN}ok${NC} と入力してね"
    echo ""
    echo -e "${YELLOW}--- ここから貼り付け ---${NC}"

    # 複数行入力を受け取る
    MISSION_CONTENT=""
    while IFS= read -r line; do
        if [ "$line" = "ok" ] || [ "$line" = "OK" ]; then
            break
        fi
        MISSION_CONTENT="${MISSION_CONTENT}${line}
"
    done

    # 空チェック
    if [ -z "$(echo "$MISSION_CONTENT" | tr -d '[:space:]')" ]; then
        echo -e "${RED}❌ 指示書が空だよ！もう一回やってね${NC}"
        return
    fi

    # ファイル名生成（M-001-20260218-1430.md形式）
    local TIMESTAMP
    TIMESTAMP=$(date +%Y%m%d-%H%M)
    local MISSION_DIR="$POSTMAN_DIR/missions/$CURRENT_PROJECT"
    mkdir -p "$MISSION_DIR"

    # 連番を取得
    local LAST_NUM
    LAST_NUM=$(find "$MISSION_DIR" -name "M-*.md" 2>/dev/null | wc -l)
    local NEXT_NUM
    NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))
    local FILENAME="M-${NEXT_NUM}-${TIMESTAMP}.md"
    local FILEPATH="$MISSION_DIR/$FILENAME"

    # ファイル保存
    echo "$MISSION_CONTENT" > "$FILEPATH"

    echo ""
    echo -e "${GREEN}📮 配達処理中...${NC}"

    # git操作
    cd "$POSTMAN_DIR" || return
    git add "missions/$CURRENT_PROJECT/$FILENAME"
    git commit -m "📮 新規ミッション: $CURRENT_PROJECT/$FILENAME" > /dev/null 2>&1

    # v1.6追加 - push前にリモート同期（タブレットとの競合防止）
    echo -e "  ${YELLOW}🔄 リモートと同期中...${NC}"
    git pull --rebase origin main > /dev/null 2>&1

    # v1.6修正 - リトライ付きpush（競合対策）
    if git push origin main > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ ファイル作成: ${FILENAME}${NC}"
        echo -e "${GREEN}  ✅ git push 完了${NC}"
        echo -e "${GREEN}  📮 タブレット支店に届けました！${NC}"
    else
        # 1回だけリトライ（タブレットがpushした直後の可能性）
        echo -e "  ${YELLOW}🔄 再同期中...（リトライ1回目）${NC}"
        git pull --rebase origin main > /dev/null 2>&1
        if git push origin main > /dev/null 2>&1; then
            echo -e "${GREEN}  ✅ ファイル作成: ${FILENAME}${NC}"
            echo -e "${GREEN}  ✅ git push 完了（リトライで成功）${NC}"
            echo -e "${GREEN}  📮 タブレット支店に届けました！${NC}"
        else
            echo -e "${YELLOW}  ✅ ファイル作成: ${FILENAME}${NC}"
            echo -e "${RED}  ⚠️ git pushに失敗。後で手動pushしてね${NC}"
            echo "  コマンド: cd ~/cocomi-postman && git pull --rebase && git push"
        fi
    fi

    echo ""
    echo -e "  何か他にやる？（Enter でメニューに戻る）"
    read -r
}

# === 2. レポート確認 ===
check_reports() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📋 レポート確認${NC}"
    echo -e "  📂 対象: ${YELLOW}${CURRENT_PROJECT_NAME}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # まずgit pullで最新取得
    cd "$POSTMAN_DIR" || return
    git pull origin main > /dev/null 2>&1

    local REPORT_DIR="$POSTMAN_DIR/reports/$CURRENT_PROJECT"
    local ERROR_DIR="$POSTMAN_DIR/errors/$CURRENT_PROJECT"

    # レポート一覧
    if [ -d "$REPORT_DIR" ] && [ "$(ls -A "$REPORT_DIR" 2>/dev/null)" ]; then
        echo -e "  ${GREEN}✅ 完了レポート:${NC}"
        ls -t "$REPORT_DIR"/*.md 2>/dev/null | head -5 | while read -r f; do
            echo -e "    ${GREEN}🟢${NC} $(basename "$f")"
        done
    else
        echo -e "  ${YELLOW}📭 完了レポートはまだないよ${NC}"
    fi

    echo ""

    # エラーレポート一覧
    if [ -d "$ERROR_DIR" ] && [ "$(ls -A "$ERROR_DIR" 2>/dev/null)" ]; then
        echo -e "  ${RED}❌ エラーレポート:${NC}"
        ls -t "$ERROR_DIR"/*.md 2>/dev/null | head -5 | while read -r f; do
            echo -e "    ${RED}🔴${NC} $(basename "$f")"
        done
    fi

    echo ""
    echo "  レポートを読む？ (ファイル名を入力 / Enter でメニュー)"
    read -r CHOICE
    if [ -n "$CHOICE" ]; then
        # レポートを表示してクリップボードにコピー
        local TARGET=""
        [ -f "$REPORT_DIR/$CHOICE" ] && TARGET="$REPORT_DIR/$CHOICE"
        [ -f "$ERROR_DIR/$CHOICE" ] && TARGET="$ERROR_DIR/$CHOICE"

        if [ -n "$TARGET" ]; then
            echo ""
            cat "$TARGET"
            echo ""
            # Termuxのクリップボードにコピー（termux-clipboard-set使用）
            if command -v termux-clipboard-set &> /dev/null; then
                termux-clipboard-set < "$TARGET"
                echo -e "${GREEN}📋 クリップボードにコピーしたよ！${NC}"
                echo "  → クロちゃんの部屋にペーストしてね"
            fi
        else
            echo -e "${RED}ファイルが見つからないよ${NC}"
        fi
        echo ""
        echo "  Enter でメニューに戻る"
        read -r
    fi
}

# === 3. プロジェクト切替 ===
# v1.2修正 - config.jsonから動的にプロジェクト一覧を表示
# v1.7修正 - grep対象を"ID": {に限定
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
        local mcount
        mcount=$(find "$POSTMAN_DIR/missions/$pid" -name "M-*.md" 2>/dev/null | wc -l)
        local mark=""
        [ "$CURRENT_PROJECT" = "$pid" ] && mark=" ⭐"
        echo -e "  ${GREEN}${i}${NC}. ${pname} [ミッション${mcount}件]${mark}"
        i=$((i + 1))
    done < <(get_project_ids)

    echo ""
    echo -n "  番号を選んでね → "
    read -r CHOICE

    # 番号バリデーション
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#proj_ids[@]} ]; then
        echo -e "${RED}  無効な番号だよ${NC}"; sleep 1; return
    fi

    CURRENT_PROJECT="${proj_ids[$((CHOICE - 1))]}"
    load_project_name
    echo -e "  ${GREEN}✅ ${CURRENT_PROJECT_NAME} に切り替えたよ！${NC}"
    sleep 1
}

# === 4. ダッシュボード ===
# v1.7修正 - grep対象を"ID": {に限定
show_dashboard() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📊 COCOMI ダッシュボード${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # git pullで最新取得
    cd "$POSTMAN_DIR" || return
    git pull origin main > /dev/null 2>&1

    echo -e "  ${BOLD}🗂️ プロジェクト状況${NC}"

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
        local pending=$((missions - reports - errors))
        [ "$pending" -lt 0 ] && pending=0

        local status_icon="⏸️"
        [ "$pending" -gt 0 ] && status_icon="🔄"
        [ "$errors" -gt 0 ] && status_icon="⚠️"
        [ "$missions" -eq 0 ] && status_icon="📭"

        echo -e "    ${status_icon} ${pname}: 📝${missions}件 ✅${reports}件 ❌${errors}件 待機${pending}件"
    done < <(get_project_ids)

    echo ""
    echo -e "  ${BOLD}💡 たまってるアイデア${NC}"
    for dir in genba-pro culo-chan new-apps unassigned; do
        local count
        count=$(find "$POSTMAN_DIR/ideas/$dir" -name "*.md" 2>/dev/null | wc -l)
        local label=""
        case "$dir" in
            "genba-pro") label="設備くん向き  " ;;
            "culo-chan") label="CULOchan向き " ;;
            "new-apps") label="新アプリのネタ" ;;
            "unassigned") label="未振り分け    " ;;
        esac
        echo -e "    ${label}: ${count}件"
    done

    echo ""
    echo "  Enter でメニューに戻る"
    read -r
}

# === 5. アイデアメモ ===
save_idea() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  💡 アイデアメモ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  どんなアイデア？（1行でOK）"
    echo -n "  → "
    read -r IDEA_TEXT

    if [ -z "$IDEA_TEXT" ]; then
        echo -e "${RED}  空だよ！${NC}"
        sleep 1
        return
    fi

    echo ""
    echo "  種類は？"
    echo -e "  ${GREEN}1${NC}. 💡 機能アイデア"
    echo -e "  ${GREEN}2${NC}. 🐛 バグ・気になること"
    echo -e "  ${GREEN}3${NC}. 🎨 デザイン・雰囲気"
    echo -e "  ${GREEN}4${NC}. 📋 その他メモ"
    echo -n "  → "
    read -r IDEA_TYPE

    local type_label=""
    case "$IDEA_TYPE" in
        1) type_label="💡 機能アイデア" ;;
        2) type_label="🐛 バグ・気になること" ;;
        3) type_label="🎨 デザイン・雰囲気" ;;
        *) type_label="📋 その他メモ" ;;
    esac

    echo ""
    echo "  どのプロジェクト向き？"
    echo -e "  ${GREEN}1${NC}. 設備くん"
    echo -e "  ${GREEN}2${NC}. CULOchan"
    echo -e "  ${GREEN}3${NC}. マップアプリ"
    echo -e "  ${GREEN}4${NC}. 新アプリのネタ"
    echo -e "  ${GREEN}5${NC}. まだわからん"
    echo -n "  → "
    read -r IDEA_PROJECT

    local idea_dir=""
    case "$IDEA_PROJECT" in
        1) idea_dir="genba-pro" ;;
        2) idea_dir="culo-chan" ;;
        3) idea_dir="maintenance-map" ;;
        4) idea_dir="new-apps" ;;
        *) idea_dir="unassigned" ;;
    esac

    # ファイル保存
    local TIMESTAMP
    TIMESTAMP=$(date +%Y%m%d-%H%M)
    local IDEA_FILE="$POSTMAN_DIR/ideas/$idea_dir/IDEA-${TIMESTAMP}.md"
    mkdir -p "$POSTMAN_DIR/ideas/$idea_dir"

    cat > "$IDEA_FILE" << EOF
# 💡 アイデアメモ
- **日時:** $(date '+%Y-%m-%d %H:%M')
- **種類:** ${type_label}
- **内容:** ${IDEA_TEXT}
EOF

    # git push
    cd "$POSTMAN_DIR" || return
    git add "ideas/$idea_dir/IDEA-${TIMESTAMP}.md"
    git commit -m "💡 アイデア追加: $idea_dir" > /dev/null 2>&1
    # v1.6追加 - push前にリモート同期（競合防止）
    git pull --rebase origin main > /dev/null 2>&1
    if git push origin main > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}  ✅ アイデア保存＆配達完了！${NC}"
    else
        # v1.6追加 - 1回リトライ
        git pull --rebase origin main > /dev/null 2>&1
        if git push origin main > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}  ✅ アイデア保存＆配達完了！（リトライ成功）${NC}"
        else
            echo ""
            echo -e "${YELLOW}  ✅ アイデア保存完了！${NC}"
            echo -e "${RED}  ⚠️ git pushに失敗。後で手動pushしてね${NC}"
            echo "  コマンド: cd ~/cocomi-postman && git pull --rebase && git push"
        fi
    fi
    echo -e "  📂 保存先: ideas/${idea_dir}/"
    echo ""
    echo "  Enter でメニューに戻る"
    read -r
}

# === 6〜9: 今後実装予定のプレースホルダー ===
coming_soon() {
    local feature_name=$1
    echo ""
    echo -e "${YELLOW}  🚧 ${feature_name}は次のバージョンで追加予定！${NC}"
    echo "  Enter でメニューに戻る"
    read -r
}

# === メインループ ===
init

while true; do
    show_menu
    read -r choice
    case "$choice" in
        1) send_mission ;;
        2) check_reports ;;
        3) switch_project ;;
        4) show_dashboard ;;
        5) save_idea ;;
        6) coming_soon "軌道修正" ;;
        7) coming_soon "アイデア振り分け" ;;
        8) coming_soon "開発ヒストリー" ;;
        9) coming_soon "プロジェクトマップ" ;;
        0) coming_soon "設定" ;;
        q|Q)
            echo ""
            echo -e "${GREEN}  📮 お疲れ様！またね〜！${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}  無効な番号だよ${NC}"
            sleep 1
            ;;
    esac
done