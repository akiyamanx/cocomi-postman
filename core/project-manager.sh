#!/bin/bash
# shellcheck disable=SC2001
# このファイルは: COCOMI Postman プロジェクト管理機能
# postman.shのメニュー8から呼ばれるプロジェクト管理モジュール
# v1.0 新規作成 2026-02-26 - 一覧表示/追加/削除/デフォルト変更/編集
# v1.0.1 修正 2026-04-07 - ShellCheck SC2001対応（sed置換スタイル警告抑制）
# config.jsonの読み書きはcore/config-helper.py（Python）で安全に処理

# v1.0 Pythonヘルパーのパス
CONFIG_HELPER="$POSTMAN_DIR/core/config-helper.py"

# === Pythonヘルパー呼び出し ===
_config_cmd() {
    python3 "$CONFIG_HELPER" "$@"
}

# === プロジェクト管理メインメニュー ===
manage_projects() {
    if ! command -v python3 &>/dev/null; then
        echo -e "  ${RED}❌ python3が必要です。pkg install python で入れてね${NC}"
        echo "  Enter で戻る"
        read -r
        return
    fi
    if [ ! -f "$CONFIG_HELPER" ]; then
        echo -e "  ${RED}❌ config-helper.py が見つかりません${NC}"
        echo "  core/config-helper.py を配置してください"
        echo "  Enter で戻る"
        read -r
        return
    fi

    while true; do
        local proj_count
        proj_count=$(_config_cmd list_ids | wc -l)

        echo ""
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}  🗂️ プロジェクト管理${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  📂 登録済み: ${proj_count}件"
        echo ""
        echo -e "  ${GREEN}1${NC} → 📋 プロジェクト一覧（詳細）"
        echo -e "  ${GREEN}2${NC} → ➕ 新規プロジェクト追加"
        echo -e "  ${GREEN}3${NC} → ✏️ プロジェクト情報の編集"
        echo -e "  ${GREEN}4${NC} → 🗑️ プロジェクト削除"
        echo -e "  ${GREEN}5${NC} → ⭐ デフォルトプロジェクト変更"
        echo -e "  ${RED}b${NC} → 戻る"
        echo ""
        echo -n "  → "
        read -r pm_choice

        case "$pm_choice" in
            1) _show_project_list ;;
            2) _add_project ;;
            3) _edit_project ;;
            4) _remove_project ;;
            5) _change_default ;;
            b|B) return ;;
            *) echo -e "${RED}  無効な番号だよ${NC}"; sleep 1 ;;
        esac
    done
}

# === 1. プロジェクト一覧（詳細表示） ===
_show_project_list() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📋 プロジェクト一覧${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local index=1
    while IFS=$'\t' read -r pid name repo path status version desc github_star; do
        local status_icon="🟢"
        [ "$status" = "inactive" ] && status_icon="⚪"

        local default_mark=""
        if echo "$github_star" | grep -q "⭐"; then
            default_mark=" ⭐デフォルト"
            github_star=$(echo "$github_star" | sed 's/ ⭐//')
        fi

        echo -e "  ${GREEN}${index}${NC}. ${BOLD}${name}${NC}${default_mark}"
        echo -e "     ID: ${pid}  ${status_icon}${status}  ver.${version}"
        echo -e "     📁 ${path}"
        [ -n "$github_star" ] && echo -e "     🔗 ${github_star}"
        [ -n "$desc" ] && echo -e "     📝 ${desc}"
        echo ""
        index=$((index + 1))
    done < <(_config_cmd list)

    echo "  Enter で戻る"
    read -r
}

# === 2. 新規プロジェクト追加 ===
_add_project() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ➕ 新規プロジェクト追加${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}💡 例: my-app / 私のアプリ / akiyamanx/my-app${NC}"
    echo ""

    echo -n "  プロジェクトID（英数字-のみ）: "
    read -r new_pid
    if [ -z "$new_pid" ]; then
        echo -e "  ${RED}キャンセルしたよ${NC}"; sleep 1; return
    fi
    if ! echo "$new_pid" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
        echo -e "  ${RED}❌ IDは英小文字・数字・ハイフンだけ使えるよ${NC}"
        sleep 2; return
    fi

    echo -n "  プロジェクト名（日本語OK）: "
    read -r new_name
    [ -z "$new_name" ] && new_name="$new_pid"

    echo -n "  GitHubリポジトリ名（例: my-app）: "
    read -r new_repo
    [ -z "$new_repo" ] && new_repo="$new_pid"

    local gh_user
    gh_user=$(grep '"github_user"' "$CONFIG_FILE" | sed 's/.*: *"\(.*\)".*/\1/')
    [ -z "$gh_user" ] && gh_user="akiyamanx"

    local new_local_path="\$HOME/${new_repo}"
    local new_github_url="https://github.com/${gh_user}/${new_repo}"

    echo -n "  説明（短く）: "
    read -r new_desc

    echo ""
    echo -e "  ${BOLD}確認:${NC}"
    echo -e "    ID: ${new_pid}"
    echo -e "    名前: ${new_name}"
    echo -e "    リポジトリ: ${gh_user}/${new_repo}"
    echo -e "    ローカルパス: ${new_local_path}"
    echo -e "    GitHub: ${new_github_url}"
    echo -e "    説明: ${new_desc}"
    echo ""
    echo -n -e "  ${YELLOW}これでいい？ (y/N) ${NC}"
    read -r confirm

    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        local result
        result=$(_config_cmd add "$new_pid" "$new_name" "$new_repo" "$new_local_path" "$new_github_url" "$new_desc" 2>&1)
        if echo "$result" | grep -q "^OK:"; then
            echo -e "  ${GREEN}✅ ${result#OK: }${NC}"
            mkdir -p "$POSTMAN_DIR/missions/$new_pid"
            mkdir -p "$POSTMAN_DIR/reports/$new_pid"
            mkdir -p "$POSTMAN_DIR/errors/$new_pid"
            echo -e "  ${GREEN}📁 missions/${new_pid}/ reports/${new_pid}/ errors/${new_pid}/ を作成${NC}"

            local real_path="${new_local_path//\$HOME/$HOME}"
            if [ ! -d "$real_path" ]; then
                echo ""
                echo -n -e "  ${YELLOW}リポジトリをcloneする？ (y/N) ${NC}"
                read -r clone_confirm
                if [ "$clone_confirm" = "y" ] || [ "$clone_confirm" = "Y" ]; then
                    echo -e "  ${YELLOW}📡 git clone中...${NC}"
                    if git clone "$new_github_url" "$real_path" 2>/dev/null; then
                        echo -e "  ${GREEN}✅ クローン完了！${NC}"
                    else
                        echo -e "  ${YELLOW}⚠️ クローンできなかったよ。リポジトリをGitHubで先に作ってね${NC}"
                    fi
                fi
            fi
        else
            echo -e "  ${RED}❌ ${result}${NC}"
        fi
    else
        echo -e "  キャンセルしたよ"
    fi

    echo ""
    echo "  Enter で戻る"
    read -r
}

# === 3. プロジェクト情報の編集 ===
_edit_project() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ✏️ プロジェクト情報の編集${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local proj_ids=()
    local i=1
    while IFS= read -r pid; do
        proj_ids+=("$pid")
        local pname
        pname=$(grep -A5 "\"$pid\"" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
        echo -e "  ${GREEN}${i}${NC}. ${pname} (${pid})"
        i=$((i + 1))
    done < <(_config_cmd list_ids)

    echo ""
    echo -n "  編集するプロジェクト番号 → "
    read -r edit_choice

    if ! [[ "$edit_choice" =~ ^[0-9]+$ ]] || [ "$edit_choice" -lt 1 ] || [ "$edit_choice" -gt ${#proj_ids[@]} ]; then
        echo -e "${RED}  無効な番号だよ${NC}"; sleep 1; return
    fi

    local target_pid="${proj_ids[$((edit_choice - 1))]}"

    echo ""
    echo -e "  ${BOLD}編集項目を選んでね:${NC}"
    echo -e "  ${GREEN}1${NC}. 名前 (name)"
    echo -e "  ${GREEN}2${NC}. 説明 (description)"
    echo -e "  ${GREEN}3${NC}. バージョン (current_version)"
    echo -e "  ${GREEN}4${NC}. ステータス (status: active/inactive)"
    echo ""
    echo -n "  → "
    read -r field_choice

    local field=""
    case "$field_choice" in
        1) field="name" ;;
        2) field="description" ;;
        3) field="current_version" ;;
        4) field="status" ;;
        *) echo -e "${RED}  無効${NC}"; sleep 1; return ;;
    esac

    echo -n "  新しい値: "
    read -r new_value
    [ -z "$new_value" ] && { echo -e "  キャンセル"; sleep 1; return; }

    local result
    result=$(_config_cmd edit "$target_pid" "$field" "$new_value" 2>&1)
    if echo "$result" | grep -q "^OK:"; then
        echo -e "  ${GREEN}✅ ${result#OK: }${NC}"
    else
        echo -e "  ${RED}❌ ${result}${NC}"
    fi

    echo ""
    echo "  Enter で戻る"
    read -r
}

# === 4. プロジェクト削除 ===
_remove_project() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🗑️ プロジェクト削除${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠️ config.jsonから登録を削除します${NC}"
    echo -e "  ${YELLOW}   リポジトリ自体は消えません${NC}"
    echo ""

    local proj_ids=()
    local i=1
    while IFS= read -r pid; do
        proj_ids+=("$pid")
        local pname
        pname=$(grep -A5 "\"$pid\"" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
        echo -e "  ${GREEN}${i}${NC}. ${pname} (${pid})"
        i=$((i + 1))
    done < <(_config_cmd list_ids)

    echo ""
    echo -n "  削除するプロジェクト番号 → "
    read -r del_choice

    if ! [[ "$del_choice" =~ ^[0-9]+$ ]] || [ "$del_choice" -lt 1 ] || [ "$del_choice" -gt ${#proj_ids[@]} ]; then
        echo -e "${RED}  無効な番号だよ${NC}"; sleep 1; return
    fi

    local target_pid="${proj_ids[$((del_choice - 1))]}"
    local target_name
    target_name=$(grep -A5 "\"$target_pid\"" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)

    echo ""
    echo -n -e "  ${RED}⚠️ ${target_name}（${target_pid}）を本当に削除する？ (y/N) ${NC}"
    read -r confirm

    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        local result
        result=$(_config_cmd remove "$target_pid" 2>&1)
        if echo "$result" | grep -q "^OK:"; then
            echo -e "  ${GREEN}✅ ${result#OK: }${NC}"
        else
            echo -e "  ${RED}❌ ${result}${NC}"
        fi
    else
        echo -e "  キャンセルしたよ"
    fi

    echo ""
    echo "  Enter で戻る"
    read -r
}

# === 5. デフォルトプロジェクト変更 ===
_change_default() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ⭐ デフォルトプロジェクト変更${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local current_default
    current_default=$(_config_cmd get_default)
    echo -e "  現在のデフォルト: ${YELLOW}${current_default}${NC}"
    echo ""

    local proj_ids=()
    local i=1
    while IFS= read -r pid; do
        proj_ids+=("$pid")
        local pname
        pname=$(grep -A5 "\"$pid\"" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
        local mark=""
        [ "$pid" = "$current_default" ] && mark=" ⭐"
        echo -e "  ${GREEN}${i}${NC}. ${pname} (${pid})${mark}"
        i=$((i + 1))
    done < <(_config_cmd list_ids)

    echo ""
    echo -n "  新しいデフォルト番号 → "
    read -r def_choice

    if ! [[ "$def_choice" =~ ^[0-9]+$ ]] || [ "$def_choice" -lt 1 ] || [ "$def_choice" -gt ${#proj_ids[@]} ]; then
        echo -e "${RED}  無効な番号だよ${NC}"; sleep 1; return
    fi

    local target_pid="${proj_ids[$((def_choice - 1))]}"
    local result
    result=$(_config_cmd set_default "$target_pid" 2>&1)
    if echo "$result" | grep -q "^OK:"; then
        echo -e "  ${GREEN}✅ ${result#OK: }${NC}"
    else
        echo -e "  ${RED}❌ ${result}${NC}"
    fi

    echo ""
    echo "  Enter で戻る"
    read -r
}