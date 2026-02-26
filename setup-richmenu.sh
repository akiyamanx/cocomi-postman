#!/bin/bash
# COCOMI Postman リッチメニュー登録スクリプト v1.0
# Termuxまたはbashから実行してLINEリッチメニューを設定する
# 使い方: ./setup-richmenu.sh

set -e

# === 設定 ===
# config.jsonから読み込むか、直接指定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# config.jsonがあればそこからトークンを読む
if [ -f "$SCRIPT_DIR/config.json" ] && command -v python3 &>/dev/null; then
    TOKEN=$(python3 -c "
import json
with open('$SCRIPT_DIR/config.json') as f:
    c = json.load(f)
print(c.get('line',{}).get('channel_access_token',''))
" 2>/dev/null)
fi

if [ -z "$TOKEN" ]; then
    echo "⚠️ LINE Channel Access Tokenが見つかりません"
    echo "config.jsonに設定するか、以下に直接入力してください:"
    read -rp "TOKEN: " TOKEN
fi

if [ -z "$TOKEN" ]; then
    echo "❌ トークンが空です。終了します。"
    exit 1
fi

MENU_IMAGE="$SCRIPT_DIR/cocomi-richmenu.png"
if [ ! -f "$MENU_IMAGE" ]; then
    echo "❌ リッチメニュー画像が見つかりません: $MENU_IMAGE"
    echo "cocomi-richmenu.png を同じフォルダに配置してください"
    exit 1
fi

echo "📮 COCOMI Postman リッチメニュー登録"
echo "======================================"
echo ""

# --- Step 1: リッチメニュー作成 ---
echo "📋 Step 1/4: リッチメニュー定義を登録中..."

# 6ボタン: 3列x2行 (2500x1686)
# 各セル: 833x843
RESPONSE=$(curl -s -X POST https://api.line.me/v2/bot/richmenu \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
    "size": {
        "width": 2500,
        "height": 1686
    },
    "selected": true,
    "name": "COCOMI Postman Menu v1.0",
    "chatBarText": "📮 COCOMIメニュー",
    "areas": [
        {
            "bounds": {"x": 0, "y": 0, "width": 833, "height": 843},
            "action": {"type": "message", "text": "状態"}
        },
        {
            "bounds": {"x": 833, "y": 0, "width": 834, "height": 843},
            "action": {"type": "message", "text": "カプセル"}
        },
        {
            "bounds": {"x": 1667, "y": 0, "width": 833, "height": 843},
            "action": {"type": "message", "text": "アイデア一覧"}
        },
        {
            "bounds": {"x": 0, "y": 843, "width": 833, "height": 843},
            "action": {"type": "message", "text": "フォルダ一覧"}
        },
        {
            "bounds": {"x": 833, "y": 843, "width": 834, "height": 843},
            "action": {"type": "message", "text": "ヘルプ 指示"}
        },
        {
            "bounds": {"x": 1667, "y": 843, "width": 833, "height": 843},
            "action": {"type": "message", "text": "ヘルプ"}
        }
    ]
}')

echo "  レスポンス: $RESPONSE"

# richMenuIdを抽出
RICH_MENU_ID=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('richMenuId', ''))
except:
    print('')
" 2>/dev/null)

if [ -z "$RICH_MENU_ID" ]; then
    echo "❌ リッチメニューIDの取得に失敗しました"
    echo "  レスポンス: $RESPONSE"
    exit 1
fi

echo "  ✅ リッチメニューID: $RICH_MENU_ID"
echo ""

# --- Step 2: 画像をアップロード ---
echo "🖼️ Step 2/4: リッチメニュー画像をアップロード中..."

UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "https://api-data.line.me/v2/bot/richmenu/$RICH_MENU_ID/content" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: image/png" \
    -T "$MENU_IMAGE")

HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -1)
BODY=$(echo "$UPLOAD_RESPONSE" | head -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ 画像アップロード成功"
else
    echo "  ❌ 画像アップロード失敗 (HTTP $HTTP_CODE)"
    echo "  レスポンス: $BODY"
    exit 1
fi
echo ""

# --- Step 3: デフォルトリッチメニューに設定 ---
echo "🔧 Step 3/4: デフォルトリッチメニューに設定中..."

DEFAULT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "https://api.line.me/v2/bot/user/all/richmenu/$RICH_MENU_ID" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$DEFAULT_RESPONSE" | tail -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ デフォルトリッチメニューに設定完了"
else
    echo "  ❌ 設定失敗 (HTTP $HTTP_CODE)"
    echo "  レスポンス: $(echo "$DEFAULT_RESPONSE" | head -1)"
    exit 1
fi
echo ""

# --- Step 4: 確認 ---
echo "✅ Step 4/4: 完了！"
echo ""
echo "======================================"
echo "📮 リッチメニュー登録完了！"
echo "   メニューID: $RICH_MENU_ID"
echo ""
echo "📱 LINEのCOCOMIトーク画面を開いて確認してください"
echo "   画面下部に6ボタンのメニューが表示されるはずです"
echo ""
echo "⚠️ 注意: メニューIDは削除時に必要なのでメモしておいてください"
echo "   削除コマンド:"
echo "   curl -X DELETE https://api.line.me/v2/bot/user/all/richmenu \\"
echo "     -H 'Authorization: Bearer \$TOKEN'"
echo "======================================"

# メニューIDをファイルに保存
echo "$RICH_MENU_ID" > "$SCRIPT_DIR/.richmenu-id"
echo ""
echo "💾 メニューIDを .richmenu-id に保存しました"
