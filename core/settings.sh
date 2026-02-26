#!/bin/bash
# このファイルは: COCOMI Postman 設定管理機能
# postman.shのメニュー9から呼ばれる設定変更モジュール
# v1.0 新規作成 2026-02-26 - LINE通知/自動モード/安全設定/設定一覧表示
# config.jsonの読み書きはcore/config-helper.pyと同じくpython3で安全に処理

# v1.0 Pythonで設定値を読み書きするヘルパー
_setting_read() {
    # 引数: JSONパス（ドット区切り）例: "line.enabled", "auto_mode.max_retries"
    python3 -c "
import json, sys
with open('$POSTMAN_DIR/config.json', 'r') as f:
    c = json.load(f)
keys = '$1'.split('.')
v = c
for k in keys:
    v = v.get(k, '')
    if v == '': break
print(v)
" 2>/dev/null
}

_setting_write() {
    # 引数: JSONパス, 新しい値
    local path="$1"
    local value="$2"
    python3 -c "
import json, os
config_path = os.path.expanduser('~/cocomi-postman/config.json')
backup_path = config_path + '.bak'

with open(config_path, 'r') as f:
    c = json.load(f)

# バックアップ
with open(backup_path, 'w') as f:
    json.dump(c, f, ensure_ascii=False, indent=2)

keys = '$path'.split('.')
target = c
for k in keys[:-1]:
    if k not in target:
        target[k] = {}
    target = target[k]

# 値の型変換
val = '$value'
if val.lower() == 'true':
    val = True
elif val.lower() == 'false':
    val = False
elif val.isdigit():
    val = int(val)

target[keys[-1]] = val

from datetime import date
c['_updated'] = str(date.today())

with open(config_path, 'w') as f:
    json.dump(c, f, ensure_ascii=False, indent=2)
print('OK')
" 2>/dev/null
}

# === 設定メインメニュー ===
show_settings() {
    # v1.0 pythonの存在確認
    if ! command -v python3 &>/dev/null; then
        echo -e "  ${RED}❌ python3が必要です。pkg install python で入れてね${NC}"
        echo "  Enter で戻る"
        read -r
        return
    fi

    while true; do
        echo ""
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}  ⚙️ 設定${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC} → 📱 LINE通知設定"
        echo -e "  ${GREEN}2${NC} → 🌙 自動モード設定"
        echo -e "  ${GREEN}3${NC} → 🛡️ 安全設定"
        echo -e "  ${GREEN}4${NC} → 📋 現在の設定を全表示"
        echo -e "  ${RED}b${NC} → 戻る"
        echo ""
        echo -n "  → "
        read -r setting_choice

        case "$setting_choice" in
            1) _line_settings ;;
            2) _auto_mode_settings ;;
            3) _safety_settings ;;
            4) _show_all_settings ;;
            b|B) return ;;
            *) echo -e "${RED}  無効な番号だよ${NC}"; sleep 1 ;;
        esac
    done
}

# === 1. LINE通知設定 ===
_line_settings() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📱 LINE通知設定${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # v1.0 現在の設定を表示
    local enabled; enabled=$(_setting_read "line.enabled")
    local on_complete; on_complete=$(_setting_read "line.notify_on.mission_complete")
    local on_error; on_error=$(_setting_read "line.notify_on.mission_error")
    local on_summary; on_summary=$(_setting_read "line.notify_on.auto_mode_summary")

    local enabled_icon="🟢 ON"; [ "$enabled" = "False" ] && enabled_icon="🔴 OFF"
    local complete_icon="🟢"; [ "$on_complete" = "False" ] && complete_icon="🔴"
    local error_icon="🟢"; [ "$on_error" = "False" ] && error_icon="🔴"
    local summary_icon="🟢"; [ "$on_summary" = "False" ] && summary_icon="🔴"

    echo -e "  現在の設定:"
    echo -e "    LINE通知全体: ${enabled_icon}"
    echo -e "    ${complete_icon} ミッション成功時に通知"
    echo -e "    ${error_icon} ミッションエラー時に通知"
    echo -e "    ${summary_icon} auto_modeサマリー通知"
    echo ""
    echo -e "  ${GREEN}1${NC}. LINE通知全体の ON/OFF 切替"
    echo -e "  ${GREEN}2${NC}. ミッション成功通知の ON/OFF"
    echo -e "  ${GREEN}3${NC}. ミッションエラー通知の ON/OFF"
    echo -e "  ${GREEN}4${NC}. auto_modeサマリー通知の ON/OFF"
    echo -e "  ${RED}b${NC}. 戻る"
    echo ""
    echo -n "  → "
    read -r line_choice

    case "$line_choice" in
        1) _toggle_setting "line.enabled" "$enabled" "LINE通知全体" ;;
        2) _toggle_setting "line.notify_on.mission_complete" "$on_complete" "ミッション成功通知" ;;
        3) _toggle_setting "line.notify_on.mission_error" "$on_error" "ミッションエラー通知" ;;
        4) _toggle_setting "line.notify_on.auto_mode_summary" "$on_summary" "auto_modeサマリー通知" ;;
        b|B) return ;;
    esac
}

# === ON/OFF トグル共通処理 ===
_toggle_setting() {
    local path="$1"
    local current="$2"
    local label="$3"

    local new_value="true"
    [ "$current" = "True" ] && new_value="false"

    local result
    result=$(_setting_write "$path" "$new_value")
    if [ "$result" = "OK" ]; then
        local new_icon="🟢 ON"; [ "$new_value" = "false" ] && new_icon="🔴 OFF"
        echo -e "  ${GREEN}✅ ${label}を ${new_icon} に変更しました${NC}"
    else
        echo -e "  ${RED}❌ 変更に失敗しました${NC}"
    fi
    sleep 1
}

# === 2. 自動モード設定 ===
_auto_mode_settings() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🌙 自動モード設定${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local interval; interval=$(_setting_read "auto_mode.check_interval_seconds")
    local retries; retries=$(_setting_read "auto_mode.max_retries")
    local concurrent; concurrent=$(_setting_read "auto_mode.concurrent_missions")

    echo -e "  現在の設定:"
    echo -e "    ⏱️ チェック間隔: ${interval}秒"
    echo -e "    🔄 最大リトライ回数: ${retries}回"
    echo -e "    📋 同時実行ミッション数: ${concurrent}"
    echo ""
    echo -e "  ${GREEN}1${NC}. チェック間隔を変更"
    echo -e "  ${GREEN}2${NC}. 最大リトライ回数を変更"
    echo -e "  ${GREEN}3${NC}. 同時実行ミッション数を変更"
    echo -e "  ${RED}b${NC}. 戻る"
    echo ""
    echo -n "  → "
    read -r auto_choice

    case "$auto_choice" in
        1)
            echo -n "  新しいチェック間隔（秒）: "
            read -r new_val
            if [[ "$new_val" =~ ^[0-9]+$ ]] && [ "$new_val" -ge 10 ]; then
                _setting_write "auto_mode.check_interval_seconds" "$new_val"
                echo -e "  ${GREEN}✅ チェック間隔を ${new_val}秒 に変更しました${NC}"
            else
                echo -e "  ${RED}❌ 10以上の数字を入れてね${NC}"
            fi
            sleep 1
            ;;
        2)
            echo -n "  新しいリトライ回数: "
            read -r new_val
            if [[ "$new_val" =~ ^[0-9]+$ ]] && [ "$new_val" -ge 1 ] && [ "$new_val" -le 10 ]; then
                _setting_write "auto_mode.max_retries" "$new_val"
                echo -e "  ${GREEN}✅ リトライ回数を ${new_val}回 に変更しました${NC}"
            else
                echo -e "  ${RED}❌ 1〜10の数字を入れてね${NC}"
            fi
            sleep 1
            ;;
        3)
            echo -n "  新しい同時実行数: "
            read -r new_val
            if [[ "$new_val" =~ ^[0-9]+$ ]] && [ "$new_val" -ge 1 ] && [ "$new_val" -le 5 ]; then
                _setting_write "auto_mode.concurrent_missions" "$new_val"
                echo -e "  ${GREEN}✅ 同時実行数を ${new_val} に変更しました${NC}"
            else
                echo -e "  ${RED}❌ 1〜5の数字を入れてね${NC}"
            fi
            sleep 1
            ;;
        b|B) return ;;
    esac
}

# === 3. 安全設定 ===
_safety_settings() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🛡️ 安全設定${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local auto_fix; auto_fix=$(_setting_read "safety.auto_fix_enabled")
    local git_only; git_only=$(_setting_read "safety.fallback_to_git_only")

    local fix_icon="🟢 ON"; [ "$auto_fix" = "False" ] && fix_icon="🔴 OFF"
    local git_icon="🟢 ON"; [ "$git_only" = "False" ] && git_icon="🔴 OFF"

    echo -e "  現在の設定:"
    echo -e "    ${fix_icon} 自動修正（auto_fix）"
    echo -e "      → ONにするとエラー時にClaude Codeが自動修正を試みる"
    echo -e "    ${git_icon} git限定フォールバック"
    echo -e "      → ONにするとgit操作のみ許可（ファイル直接操作を禁止）"
    echo ""
    echo -e "  ${GREEN}1${NC}. 自動修正の ON/OFF"
    echo -e "  ${GREEN}2${NC}. git限定フォールバックの ON/OFF"
    echo -e "  ${RED}b${NC}. 戻る"
    echo ""
    echo -n "  → "
    read -r safety_choice

    case "$safety_choice" in
        1) _toggle_setting "safety.auto_fix_enabled" "$auto_fix" "自動修正" ;;
        2) _toggle_setting "safety.fallback_to_git_only" "$git_only" "git限定フォールバック" ;;
        b|B) return ;;
    esac
}

# === 4. 現在の設定を全表示 ===
_show_all_settings() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📋 現在の設定（config.json）${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # v1.0 pythonで整形表示（トークンはマスク）
    python3 -c "
import json, os, re
config_path = os.path.expanduser('~/cocomi-postman/config.json')
with open(config_path, 'r') as f:
    c = json.load(f)

# トークンをマスク
if 'line' in c and 'channel_access_token' in c['line']:
    token = c['line']['channel_access_token']
    if len(token) > 10:
        c['line']['channel_access_token'] = token[:6] + '...' + token[-4:]

if 'line' in c and 'user_id' in c['line']:
    uid = c['line']['user_id']
    if len(uid) > 10:
        c['line']['user_id'] = uid[:6] + '...' + uid[-4:]

print(json.dumps(c, ensure_ascii=False, indent=2))
" 2>/dev/null

    echo ""
    echo "  Enter で戻る"
    read -r
}
