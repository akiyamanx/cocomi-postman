#!/bin/bash
# このファイルは: COCOMI Postman ログ・履歴表示機能
# postman.shのメニュー7から呼ばれるログ閲覧・管理モジュール
# v1.0 新規作成 2026-02-26 - ログ統合表示＋フィルタ＋安全弁履歴＋クリーンアップ
# logs/execution/ + reports/ + errors/ + inbox/rejected/ を統合して時系列表示

# === ログ・履歴メインメニュー ===
show_logs() {
    while true; do
        echo ""
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}  📜 ログ・履歴${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # v1.0 今日のサマリー自動表示
        _show_today_summary

        echo ""
        echo -e "  ${GREEN}1${NC} → 📋 最新ログ（直近10件）"
        echo -e "  ${GREEN}2${NC} → 🔍 プロジェクト別で見る"
        echo -e "  ${GREEN}3${NC} → ❌ エラーだけ見る"
        echo -e "  ${GREEN}4${NC} → 🛡️ 安全弁の発動履歴"
        echo -e "  ${GREEN}5${NC} → 🗑️ 古いログを掃除"
        echo -e "  ${RED}b${NC} → 戻る"
        echo ""
        echo -n "  → "
        read -r log_choice

        case "$log_choice" in
            1) _show_recent_logs 10 ;;
            2) _show_logs_by_project ;;
            3) _show_error_logs ;;
            4) _show_safety_logs ;;
            5) _cleanup_old_logs ;;
            b|B) return ;;
            *) echo -e "${RED}  無効な番号だよ${NC}"; sleep 1 ;;
        esac
    done
}

# === 今日のファイル数を数えるヘルパー ===
# 引数: ディレクトリ, ファイルパターン
_count_today_files() {
    local dir="$1"
    local pattern="$2"
    local today
    today=$(date +%Y%m%d)
    local count=0
    for f in "$dir"/$pattern; do
        [ -f "$f" ] || continue
        if [ "$(date -r "$f" +%Y%m%d 2>/dev/null)" = "$today" ]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# === 今日のサマリー表示 ===
_show_today_summary() {
    local today_display
    today_display=$(date '+%m/%d')
    local success_count=0 error_count=0 rejected_count=0

    # reports/（成功）
    for d in "$POSTMAN_DIR"/reports/*/; do
        [ -d "$d" ] || continue
        local c; c=$(_count_today_files "$d" "R-*.md")
        success_count=$((success_count + c))
    done
    # errors/（エラー）
    for d in "$POSTMAN_DIR"/errors/*/; do
        [ -d "$d" ] || continue
        local c; c=$(_count_today_files "$d" "E-*.md")
        error_count=$((error_count + c))
    done
    # inbox/rejected/ + inbox/unvalidated/（安全弁）
    local c; c=$(_count_today_files "$POSTMAN_DIR/inbox/rejected" "*.md")
    rejected_count=$((rejected_count + c))
    c=$(_count_today_files "$POSTMAN_DIR/inbox/unvalidated" "*.md")
    rejected_count=$((rejected_count + c))

    echo -e "  ${BOLD}📊 今日(${today_display}): ✅${success_count}件 ❌${error_count}件 🛡️${rejected_count}件${NC}"
}

# === 全ソースから統合ログエントリを収集 ===
# 出力: "YYYYMMDD-HHMM|タイプ|プロジェクト|名前|パス"
_collect_all_entries() {
    local filter_project="${1:-}"
    local filter_type="${2:-}"

    # logs/execution/
    if [ -z "$filter_type" ] || [ "$filter_type" = "log" ]; then
        find "$POSTMAN_DIR/logs/execution" -name "*.log" 2>/dev/null | while read -r f; do
            local fname; fname=$(basename "$f" .log)
            local ts="${fname:0:13}"
            local mission; mission=$(echo "$fname" | sed 's/^[0-9]*-[0-9]*-//' | sed 's/-[0-9]*-[0-9]*$//')
            echo "${ts}|log|---|${mission}|${f}"
        done
    fi

    # reports/（成功）
    if [ -z "$filter_type" ] || [ "$filter_type" = "success" ]; then
        for proj_dir in "$POSTMAN_DIR"/reports/*/; do
            [ -d "$proj_dir" ] || continue
            local proj; proj=$(basename "$proj_dir")
            [ -n "$filter_project" ] && [ "$proj" != "$filter_project" ] && continue
            find "$proj_dir" -name "R-*.md" 2>/dev/null | while read -r f; do
                local ts; ts=$(date -r "$f" +%Y%m%d-%H%M 2>/dev/null)
                echo "${ts}|success|${proj}|$(basename "$f" .md)|${f}"
            done
        done
    fi

    # errors/（エラー）
    if [ -z "$filter_type" ] || [ "$filter_type" = "error" ]; then
        for proj_dir in "$POSTMAN_DIR"/errors/*/; do
            [ -d "$proj_dir" ] || continue
            local proj; proj=$(basename "$proj_dir")
            [ -n "$filter_project" ] && [ "$proj" != "$filter_project" ] && continue
            find "$proj_dir" -name "E-*.md" 2>/dev/null | while read -r f; do
                local ts; ts=$(date -r "$f" +%Y%m%d-%H%M 2>/dev/null)
                echo "${ts}|error|${proj}|$(basename "$f" .md)|${f}"
            done
        done
    fi

    # inbox/rejected/（タブレット側で拒否）
    if [ -z "$filter_type" ] || [ "$filter_type" = "rejected" ]; then
        if [ -d "$POSTMAN_DIR/inbox/rejected" ]; then
            find "$POSTMAN_DIR/inbox/rejected" -name "*.md" 2>/dev/null | while read -r f; do
                local ts; ts=$(date -r "$f" +%Y%m%d-%H%M 2>/dev/null)
                echo "${ts}|rejected|---|$(basename "$f" .md)|${f}"
            done
        fi
        if [ -d "$POSTMAN_DIR/inbox/unvalidated" ]; then
            find "$POSTMAN_DIR/inbox/unvalidated" -name "*.md" 2>/dev/null | while read -r f; do
                local ts; ts=$(date -r "$f" +%Y%m%d-%H%M 2>/dev/null)
                echo "${ts}|unvalidated|---|$(basename "$f" .md)|${f}"
            done
        fi
    fi
}

# === ログエントリ1行表示（アイコン付き） ===
_format_entry() {
    local entry="$1"
    local timestamp entry_type proj name
    timestamp=$(echo "$entry" | cut -d'|' -f1)
    entry_type=$(echo "$entry" | cut -d'|' -f2)
    proj=$(echo "$entry" | cut -d'|' -f3)
    name=$(echo "$entry" | cut -d'|' -f4)

    # 日付変換 YYYYMMDD-HHMM → MM/DD HH:MM
    local display_date=""
    if [ ${#timestamp} -ge 13 ]; then
        display_date="${timestamp:4:2}/${timestamp:6:2} ${timestamp:9:2}:${timestamp:11:2}"
    else
        display_date="$timestamp"
    fi

    # タイプ別アイコン
    local icon=""
    case "$entry_type" in
        success)     icon="${GREEN}✅${NC}" ;;
        error)       icon="${RED}❌${NC}" ;;
        rejected)    icon="${YELLOW}🛡️${NC}" ;;
        unvalidated) icon="${YELLOW}📥${NC}" ;;
        log)         icon="${CYAN}📝${NC}" ;;
    esac

    local proj_display=""
    [ "$proj" != "---" ] && proj_display="[${proj}] "

    echo -e "  ${display_date} ${icon} ${proj_display}${name}"
}

# === エントリ一覧表示＋詳細選択（共通処理） ===
_show_entries_with_detail() {
    local entries="$1"
    if [ -z "$entries" ]; then
        echo -e "  ${YELLOW}📭 該当するログはないよ${NC}"
        echo ""
        echo "  Enter で戻る"
        read -r
        return
    fi

    local index=1
    local filepaths=()
    while IFS= read -r entry; do
        echo -n "  ${GREEN}${index}${NC}. "
        _format_entry "$entry"
        filepaths+=("$(echo "$entry" | cut -d'|' -f5)")
        index=$((index + 1))
    done <<< "$entries"

    echo ""
    echo "  番号で詳細表示 / Enter で戻る"
    read -r detail_choice

    if [[ "$detail_choice" =~ ^[0-9]+$ ]] && [ "$detail_choice" -ge 1 ] && [ "$detail_choice" -le "${#filepaths[@]}" ]; then
        _show_file_detail "${filepaths[$((detail_choice - 1))]}"
    fi
}

# === 1. 最新ログ（直近N件）===
_show_recent_logs() {
    local count="${1:-10}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📋 最新ログ（直近${count}件）${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    local entries
    entries=$(_collect_all_entries | sort -t'|' -k1 -r | head -"$count")
    _show_entries_with_detail "$entries"
}

# === 2. プロジェクト別で見る ===
_show_logs_by_project() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🔍 プロジェクト別ログ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local proj_ids=()
    local i=1
    while IFS= read -r pid; do
        proj_ids+=("$pid")
        local pname
        pname=$(grep -A5 "\"$pid\"" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
        local s_count; s_count=$(find "$POSTMAN_DIR/reports/$pid" -name "R-*.md" 2>/dev/null | wc -l)
        local e_count; e_count=$(find "$POSTMAN_DIR/errors/$pid" -name "E-*.md" 2>/dev/null | wc -l)
        echo -e "  ${GREEN}${i}${NC}. ${pname}  (✅${s_count} ❌${e_count})"
        i=$((i + 1))
    done < <(get_project_ids)

    echo ""
    echo -n "  プロジェクト番号を選んでね → "
    read -r proj_choice

    if ! [[ "$proj_choice" =~ ^[0-9]+$ ]] || [ "$proj_choice" -lt 1 ] || [ "$proj_choice" -gt ${#proj_ids[@]} ]; then
        echo -e "${RED}  無効な番号だよ${NC}"; sleep 1; return
    fi

    local selected_proj="${proj_ids[$((proj_choice - 1))]}"
    local selected_name
    selected_name=$(grep -A5 "\"$selected_proj\"" "$CONFIG_FILE" | grep '"name"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)

    echo ""
    echo -e "  ${BOLD}📂 ${selected_name} のログ（直近15件）${NC}"
    echo ""
    local entries
    entries=$(_collect_all_entries "$selected_proj" | sort -t'|' -k1 -r | head -15)
    _show_entries_with_detail "$entries"
}

# === 3. エラーだけ見る ===
_show_error_logs() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ❌ エラーログ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    local entries
    entries=$(_collect_all_entries "" "error" | sort -t'|' -k1 -r | head -15)
    if [ -z "$entries" ]; then
        echo -e "  ${GREEN}🎉 エラーはないよ！素晴らしい！${NC}"
        echo ""
        echo "  Enter で戻る"
        read -r
    else
        _show_entries_with_detail "$entries"
    fi
}

# === 4. 安全弁の発動履歴 ===
_show_safety_logs() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🛡️ 安全弁の発動履歴${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Worker側（unvalidated）
    echo -e "  ${BOLD}📥 Worker側で退避（inbox/unvalidated/）${NC}"
    local uv_dir="$POSTMAN_DIR/inbox/unvalidated"
    if [ -d "$uv_dir" ] && ls "$uv_dir"/*.md &>/dev/null 2>&1; then
        local uv_count=0
        for f in "$uv_dir"/*.md; do
            [ -f "$f" ] || continue
            uv_count=$((uv_count + 1))
            echo -e "    ${YELLOW}📥${NC} $(date -r "$f" '+%m/%d %H:%M' 2>/dev/null) $(basename "$f")"
        done
        echo -e "    合計: ${uv_count}件"
    else
        echo -e "    ${GREEN}なし${NC}"
    fi

    echo ""

    # タブレット側（rejected）
    echo -e "  ${BOLD}🛡️ タブレット側で拒否（inbox/rejected/）${NC}"
    local rj_dir="$POSTMAN_DIR/inbox/rejected"
    if [ -d "$rj_dir" ] && ls "$rj_dir"/*.md &>/dev/null 2>&1; then
        local rj_count=0
        local filepaths=()
        local index=1
        for f in "$rj_dir"/*.md; do
            [ -f "$f" ] || continue
            rj_count=$((rj_count + 1))
            echo -e "    ${GREEN}${index}${NC}. ${YELLOW}🛡️${NC} $(date -r "$f" '+%m/%d %H:%M' 2>/dev/null) $(basename "$f")"
            filepaths+=("$f")
            index=$((index + 1))
        done
        echo -e "    合計: ${rj_count}件"
        echo ""
        echo "  番号で詳細表示 / Enter で戻る"
        read -r detail_choice
        if [[ "$detail_choice" =~ ^[0-9]+$ ]] && [ "$detail_choice" -ge 1 ] && [ "$detail_choice" -le "${#filepaths[@]}" ]; then
            _show_file_detail "${filepaths[$((detail_choice - 1))]}"
        fi
        return
    else
        echo -e "    ${GREEN}なし${NC}"
    fi

    echo ""
    echo "  Enter で戻る"
    read -r
}

# === 5. 古いログを掃除 ===
_cleanup_old_logs() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  🗑️ ログのクリーンアップ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local exec_count; exec_count=$(find "$POSTMAN_DIR/logs/execution" -name "*.log" 2>/dev/null | wc -l)
    local report_count; report_count=$(find "$POSTMAN_DIR/reports" -name "R-*.md" 2>/dev/null | wc -l)
    local error_count; error_count=$(find "$POSTMAN_DIR/errors" -name "E-*.md" 2>/dev/null | wc -l)
    local inbox_count; inbox_count=$(find "$POSTMAN_DIR/inbox" -name "*.md" 2>/dev/null | wc -l)

    echo -e "  📝 実行ログ: ${exec_count}件"
    echo -e "  ✅ 成功レポート: ${report_count}件"
    echo -e "  ❌ エラーレポート: ${error_count}件"
    echo -e "  📥 inbox: ${inbox_count}件"
    echo ""
    echo -e "  ${GREEN}1${NC}. 30日より前の実行ログを削除"
    echo -e "  ${GREEN}2${NC}. inbox/unvalidated/ を全削除"
    echo -e "  ${GREEN}3${NC}. inbox/rejected/ を全削除"
    echo -e "  ${RED}b${NC}. やめて戻る"
    echo ""
    echo -n "  → "
    read -r cleanup_choice

    case "$cleanup_choice" in
        1)
            echo -n -e "  ${YELLOW}⚠️ 30日より前の実行ログを削除する？ (y/N) ${NC}"
            read -r confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                local deleted
                deleted=$(find "$POSTMAN_DIR/logs/execution" -name "*.log" -mtime +30 -delete -print 2>/dev/null | wc -l)
                echo -e "  ${GREEN}🗑️ ${deleted}件の古いログを削除しました${NC}"
                cd "$POSTMAN_DIR" || return
                git add -A && git commit -m "🗑️ 古い実行ログを掃除（${deleted}件）" > /dev/null 2>&1
                git push origin main > /dev/null 2>&1
            else
                echo -e "  キャンセルしたよ"
            fi
            ;;
        2)
            local uv_count; uv_count=$(find "$POSTMAN_DIR/inbox/unvalidated" -name "*.md" 2>/dev/null | wc -l)
            echo -n -e "  ${YELLOW}⚠️ inbox/unvalidated/ の${uv_count}件を全削除する？ (y/N) ${NC}"
            read -r confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                rm -f "$POSTMAN_DIR/inbox/unvalidated"/*.md 2>/dev/null
                echo -e "  ${GREEN}🗑️ inbox/unvalidated/ を掃除しました${NC}"
                cd "$POSTMAN_DIR" || return
                git add -A && git commit -m "🗑️ inbox/unvalidated 掃除" > /dev/null 2>&1
                git push origin main > /dev/null 2>&1
            else
                echo -e "  キャンセルしたよ"
            fi
            ;;
        3)
            local rj_count; rj_count=$(find "$POSTMAN_DIR/inbox/rejected" -name "*.md" 2>/dev/null | wc -l)
            echo -n -e "  ${YELLOW}⚠️ inbox/rejected/ の${rj_count}件を全削除する？ (y/N) ${NC}"
            read -r confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                rm -f "$POSTMAN_DIR/inbox/rejected"/*.md 2>/dev/null
                echo -e "  ${GREEN}🗑️ inbox/rejected/ を掃除しました${NC}"
                cd "$POSTMAN_DIR" || return
                git add -A && git commit -m "🗑️ inbox/rejected 掃除" > /dev/null 2>&1
                git push origin main > /dev/null 2>&1
            else
                echo -e "  キャンセルしたよ"
            fi
            ;;
        b|B) return ;;
    esac
    echo ""
    echo "  Enter で戻る"
    read -r
}

# === ファイル詳細表示（共通） ===
_show_file_detail() {
    local filepath="$1"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  📄 $(basename "$filepath")${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    if [ -f "$filepath" ]; then
        cat "$filepath"
    else
        echo -e "  ${RED}ファイルが見つからないよ: $filepath${NC}"
    fi
    echo ""
    echo "  Enter で戻る"
    read -r
}
