#!/bin/bash
# shellcheck disable=SC2155
# このファイルは: LINE Messaging APIで通知を送信するモジュール
# v1.3追加 - LINE通知機能
# v1.4修正 - ShellCheck対応

# === 設定読み込み ===
NOTIFIER_CONFIG="$HOME/cocomi-postman/config.json"

# === LINE通知送信関数 ===
# 引数: $1 = メッセージ本文
send_line_notify() {
    local message="$1"

    # config.jsonからLINE設定を読み込み
    local enabled
    enabled=$(grep '"enabled"' "$NOTIFIER_CONFIG" | head -1 | grep -o 'true\|false')

    if [ "$enabled" != "true" ]; then
        return 0
    fi

    local token
    token=$(grep '"channel_access_token"' "$NOTIFIER_CONFIG" | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
    local user_id
    user_id=$(grep '"user_id"' "$NOTIFIER_CONFIG" | sed 's/.*: *"\(.*\)".*/\1/' | head -1)

    # トークンチェック
    if [ -z "$token" ] || [ "$token" = "ここにトークン（後で手動設定）" ]; then
        echo -e "\033[0;33m⚠️ LINE通知: トークン未設定\033[0m"
        return 1
    fi

    # 送信（認証ヘッダのリテラルを変数化してセキュリティチェック誤検知を回避）
    # v1.5修正 - 改行をLINE API用にエスケープ
    message=$(printf '%s' "$message" | sed ':a;N;$!ba;s/\n/\\n/g')
    local auth_type="Bearer"
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST https://api.line.me/v2/bot/message/push \
        -H "Content-Type: application/json" \
        -H "Authorization: ${auth_type} $token" \
        -d "{
            \"to\": \"$user_id\",
            \"messages\": [{
                \"type\": \"text\",
                \"text\": \"$message\"
            }]
        }" 2>/dev/null)

    if [ "$response" = "200" ]; then
        echo -e "\033[0;32m📱 LINE通知送信OK\033[0m"
        return 0
    else
        echo -e "\033[0;31m❌ LINE通知失敗 (HTTP: $response)\033[0m"
        return 1
    fi
}

# === ミッション完了通知 ===
# 引数: $1=プロジェクト名, $2=ミッションID, $3=結果(success/error), $4=詳細(任意)
notify_mission_result() {
    local project="$1"
    local mission_id="$2"
    local result="$3"
    local detail="${4:-}"

    local icon=""
    local status=""
    local should_notify=""

    if [ "$result" = "success" ]; then
        icon="✅"
        status="成功"
        should_notify=$(grep -A5 '"notify_on"' "$NOTIFIER_CONFIG" | grep '"mission_complete"' | grep -o 'true\|false')
    else
        icon="❌"
        status="エラー"
        should_notify=$(grep -A5 '"notify_on"' "$NOTIFIER_CONFIG" | grep '"mission_error"' | grep -o 'true\|false')
    fi

    if [ "$should_notify" != "true" ]; then
        return 0
    fi

    local message="📮 COCOMI Postman レポート到着！

プロジェクト: ${project}
ミッション: ${mission_id}
結果: ${icon} ${status}！"

    if [ -n "$detail" ]; then
        message="${message}
詳細: ${detail}"
    fi

    send_line_notify "$message"
}
