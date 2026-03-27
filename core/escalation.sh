#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162
# このファイルは: COCOMI Postman エスカレーション機能
# ステップパターン指示書のtype: search / type: meeting を処理する
# Brave Search APIで情報検索、三姉妹会議APIで方針相談ができる
# v1.0 新規作成 2026-03-27 - ステップパターン指示書の一部として実装
# 呼び出し元: step-pattern.sh の run_step_pattern_mission()

# === 定数 ===
# cocomi-api-relayのベースURL（Cloudflare Worker）
RELAY_BASE_URL="https://cocomi-api-relay.k-akiyaman.workers.dev"
COCOMI_AUTH_TOKEN="cocomi-family-2026-secret"

# === Brave Search API経由の情報検索 ===
# cocomi-api-relayの/searchエンドポイントを叩いてBrave Searchで検索
# 引数: $1 = 検索クエリ, $2 = 結果を保存するファイルパス
# 戻り値: 0 = 成功, 1 = 失敗
run_search_step() {
    local query="$1"
    local result_file="$2"

    echo -e "  ${CYAN}🔍 Brave Search検索: \"${query}\"${NC}"

    # curlでcocomi-api-relayの検索エンドポイントを叩く
    local response
    response=$(curl -s -m 30 -X POST "${RELAY_BASE_URL}/search" \
        -H "Content-Type: application/json" \
        -H "X-COCOMI-AUTH: ${COCOMI_AUTH_TOKEN}" \
        -H "Origin: https://akiyamanx.github.io" \
        -d "{\"query\": \"${query}\"}" 2>&1)

    local curl_exit=$?

    if [ "$curl_exit" -ne 0 ]; then
        echo -e "  ${RED}❌ 検索失敗（curl exit: ${curl_exit}）${NC}"
        echo "検索失敗: curl exit code ${curl_exit}" > "$result_file"
        return 1
    fi

    # 結果をファイルに保存
    echo "$response" > "$result_file"

    # レスポンスが空やエラーかチェック
    if [ -z "$response" ] || echo "$response" | grep -q '"error"'; then
        echo -e "  ${RED}❌ 検索エラー: $(echo "$response" | head -1)${NC}"
        return 1
    fi

    echo -e "  ${GREEN}✅ 検索結果取得成功${NC}"
    return 0
}

# === 三姉妹会議APIの呼び出し ===
# cocomi-api-relayの/meetingエンドポイントを叩いて三姉妹会議を開催
# 引数: $1 = 議題（問題の説明）, $2 = 結果を保存するファイルパス
#        $3 = 会議グレード（lite/standard/full、省略時standard）
# 戻り値: 0 = 成功, 1 = 失敗
run_meeting_step() {
    local topic="$1"
    local result_file="$2"
    local grade="${3:-standard}"

    echo -e "  ${CYAN}🤝 三姉妹会議開催（${grade}）: \"$(echo "$topic" | head -c 60)...\"${NC}"

    # 会議リクエスト — cocomi-api-relayの会議エンドポイントを叩く
    # ※ 現時点ではcurlでの会議呼び出しは未検証（構想カプセルv0.4のPhase2）
    # まずは問題をテキストファイルに保存して、Claude Codeに渡す方式で代替
    local response
    response=$(curl -s -m 120 -X POST "${RELAY_BASE_URL}/meeting" \
        -H "Content-Type: application/json" \
        -H "X-COCOMI-AUTH: ${COCOMI_AUTH_TOKEN}" \
        -H "Origin: https://akiyamanx.github.io" \
        -d "{
            \"topic\": $(echo "$topic" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"${topic}\""),
            \"grade\": \"${grade}\",
            \"rounds\": 3
        }" 2>&1)

    local curl_exit=$?

    if [ "$curl_exit" -ne 0 ]; then
        echo -e "  ${YELLOW}⚠️ 会議API直接呼び出し失敗（curl exit: ${curl_exit}）${NC}"
        echo -e "  ${YELLOW}→ フォールバック: 問題をファイルに保存してClaude Codeに判断を委ねます${NC}"

        # フォールバック: 問題をファイルに書き出す（Claude Codeが次のステップで読める）
        cat > "$result_file" << FALLBACK_EOF
# 三姉妹会議フォールバック — API直接呼び出し失敗

## 議題
${topic}

## 会議グレード
${grade}

## 状況
cocomi-api-relayの会議エンドポイントにcurlでアクセスできませんでした。
以下の対応を検討してください:
1. エラーの詳細を確認し、アプローチを再検討する
2. 問題を整理してアキヤに報告する

## curl出力
${response}
FALLBACK_EOF
        return 1
    fi

    # 結果をファイルに保存
    echo "$response" > "$result_file"

    if [ -z "$response" ] || echo "$response" | grep -q '"error"'; then
        echo -e "  ${RED}❌ 会議エラー: $(echo "$response" | head -1)${NC}"
        return 1
    fi

    echo -e "  ${GREEN}✅ 三姉妹会議完了${NC}"
    return 0
}

# === ステップのメタデータ（HTMLコメント）をパースする ===
# 指示書ステップ内の <!-- key: value --> 形式のメタデータを抽出
# 引数: $1 = ステップファイルパス, $2 = キー名
# 出力: 値（見つからなければ空文字）
parse_step_meta() {
    local step_file="$1"
    local key="$2"

    # <!-- key: value --> を抽出（大文字小文字無視）
    local value
    value=$(grep -i "<!--[[:space:]]*${key}:[[:space:]]*" "$step_file" \
        | sed -n "s/.*<!--[[:space:]]*${key}:[[:space:]]*\(.*\)[[:space:]]*-->.*/\1/ip" \
        | head -1 \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    echo "$value"
}

# === 検索結果をClaude Code用の指示書に注入する ===
# 検索結果や会議結果を、次のステップの指示書に追加情報として注入
# 引数: $1 = ステップファイルパス, $2 = 追加情報ファイルパス, $3 = 情報の種類（search/meeting）
inject_context_to_step() {
    local step_file="$1"
    local context_file="$2"
    local context_type="$3"

    if [ ! -f "$context_file" ]; then
        return
    fi

    local context_content
    context_content=$(cat "$context_file")

    local label="前のステップの検索結果"
    if [ "$context_type" = "meeting" ]; then
        label="三姉妹会議の結論"
    fi

    # ステップファイルの先頭に追加情報を注入
    local temp_file="${step_file}.tmp"
    {
        echo "## 📎 ${label}（前のステップから引き継ぎ）"
        echo ""
        echo '```'
        echo "$context_content"
        echo '```'
        echo ""
        echo "---"
        echo ""
        cat "$step_file"
    } > "$temp_file"
    mv "$temp_file" "$step_file"
}
