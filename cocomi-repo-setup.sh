#!/bin/bash
# cocomi-repo-setup.sh v1.0
# 新しいリポジトリにCOCOMI CI + LINE通知を自動セットアップするスクリプト
# COCOMIファミリー共通のCI/CDパイプラインを一発導入

set -euo pipefail

# === 定数定義 ===
VERSION="1.0"
SCRIPT_NAME="cocomi-repo-setup"
CONFIG_JSON="$HOME/cocomi-postman/config.json"
CI_SOURCE="$HOME/maintenance-map-ap/.github/workflows/cocomi-ci.yml"
CI_DEST_DIR=".github/workflows"
CI_DEST_FILE="cocomi-ci.yml"

# === カラー定義 ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# === ユーティリティ関数 ===

# 情報メッセージ
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 成功メッセージ
success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# 警告メッセージ
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# エラーメッセージ＆終了
die() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# === 使い方表示 ===
usage() {
    echo "📮 COCOMI Repo Setup v${VERSION}"
    echo ""
    echo "使い方: $0 <リポジトリのローカルパス>"
    echo ""
    echo "例:"
    echo "  $0 ~/NewProject"
    echo "  $0 ~/GenbaProSetsubikunN"
    echo ""
    echo "処理内容:"
    echo "  1. 対象リポにcocomi-ci.ymlをコピー"
    echo "  2. git add → commit → push"
    echo "  3. GitHub Secretsを自動設定（LINE通知用）"
    exit 1
}

# === 前提条件チェック ===
check_prerequisites() {
    # 引数チェック
    if [ $# -eq 0 ]; then
        usage
    fi

    local target_path="$1"

    # ターゲットパスの展開（~対応）
    target_path="${target_path/#\~/$HOME}"

    # ディレクトリ存在チェック
    if [ ! -d "$target_path" ]; then
        die "ディレクトリが見つかりません: $target_path"
    fi

    # gitリポジトリかチェック
    if [ ! -d "$target_path/.git" ]; then
        die "gitリポジトリではありません: $target_path"
    fi

    # コピー元のcocomi-ci.ymlが存在するかチェック
    if [ ! -f "$CI_SOURCE" ]; then
        die "コピー元のCIファイルが見つかりません: $CI_SOURCE"
    fi

    # config.jsonが存在するかチェック
    if [ ! -f "$CONFIG_JSON" ]; then
        die "設定ファイルが見つかりません: $CONFIG_JSON"
    fi

    # ghコマンドの存在チェック
    if ! command -v gh &> /dev/null; then
        die "GitHub CLI (gh) がインストールされていません"
    fi

    # gh認証チェック
    if ! gh auth status &> /dev/null 2>&1; then
        die "GitHub CLIにログインしていません。gh auth login を実行してください"
    fi

    # jqコマンドの存在チェック
    if ! command -v jq &> /dev/null; then
        die "jq がインストールされていません。pkg install jq を実行してください"
    fi

    success "前提条件チェック完了"
}

# === config.jsonからLINE設定を読み取る ===
read_line_config() {
    info "config.jsonからLINE設定を読み取り中..."

    # channel_access_tokenを取得
    LINE_TOKEN=$(jq -r '.line.channel_access_token // empty' "$CONFIG_JSON")
    if [ -z "$LINE_TOKEN" ]; then
        die "config.jsonにline.channel_access_tokenが設定されていません"
    fi

    # user_idを取得
    LINE_USER_ID=$(jq -r '.line.user_id // empty' "$CONFIG_JSON")
    if [ -z "$LINE_USER_ID" ]; then
        die "config.jsonにline.user_idが設定されていません"
    fi

    success "LINE設定を読み取りました"
}

# === CIファイルをコピー ===
copy_ci_file() {
    local target_path="$1"

    info "cocomi-ci.ymlをコピー中..."

    # .github/workflowsディレクトリがなければ作成
    local workflows_dir="$target_path/$CI_DEST_DIR"
    if [ ! -d "$workflows_dir" ]; then
        mkdir -p "$workflows_dir"
        info ".github/workflows ディレクトリを作成しました"
    fi

    # 既存ファイルの確認
    local dest_file="$workflows_dir/$CI_DEST_FILE"
    if [ -f "$dest_file" ]; then
        warn "cocomi-ci.ymlは既に存在します。上書きします"
    fi

    # コピー実行
    cp "$CI_SOURCE" "$dest_file"
    success "cocomi-ci.yml をコピーしました → $dest_file"
}

# === git add → commit → push ===
git_push() {
    local target_path="$1"

    info "git操作を実行中..."

    # 対象リポジトリに移動
    cd "$target_path" || die "ディレクトリ移動に失敗: $target_path"

    # リモートの存在確認
    if ! git remote get-url origin &> /dev/null; then
        die "git remote 'origin' が設定されていません"
    fi

    # 現在のブランチを取得
    local current_branch
    current_branch=$(git branch --show-current)
    if [ -z "$current_branch" ]; then
        die "現在のブランチを取得できませんでした"
    fi
    info "ブランチ: $current_branch"

    # git add
    git add "$CI_DEST_DIR/$CI_DEST_FILE"
    success "git add 完了"

    # 変更があるかチェック
    if git diff --cached --quiet; then
        warn "CIファイルに変更がありません（既に同一内容）"
        info "git commitをスキップします"
        return 0
    fi

    # git commit
    git commit -m "🔧 COCOMI CI + LINE通知を導入（cocomi-repo-setupによる自動セットアップ）"
    success "git commit 完了"

    # git push
    git push origin "$current_branch"
    success "git push 完了 → origin/$current_branch"
}

# === GitHub Secretsを設定 ===
set_github_secrets() {
    local target_path="$1"

    info "GitHub Secretsを設定中..."

    # 対象リポジトリに移動
    cd "$target_path" || die "ディレクトリ移動に失敗: $target_path"

    # リモートURLからリポ名を取得
    local repo_url
    repo_url=$(git remote get-url origin)
    local repo_name
    # HTTPS: https://github.com/user/repo.git → user/repo
    # SSH:   git@github.com:user/repo.git → user/repo
    repo_name=$(echo "$repo_url" | sed -E 's|.*github\.com[:/]||; s|\.git$||')

    if [ -z "$repo_name" ]; then
        die "リポジトリ名を取得できませんでした"
    fi
    info "対象リポジトリ: $repo_name"

    # LINE_CHANNEL_ACCESS_TOKEN を設定
    echo "$LINE_TOKEN" | gh secret set LINE_CHANNEL_ACCESS_TOKEN --repo "$repo_name"
    if [ $? -eq 0 ]; then
        success "SECRET設定完了: LINE_CHANNEL_ACCESS_TOKEN"
    else
        die "LINE_CHANNEL_ACCESS_TOKEN の設定に失敗しました"
    fi

    # LINE_USER_ID を設定
    echo "$LINE_USER_ID" | gh secret set LINE_USER_ID --repo "$repo_name"
    if [ $? -eq 0 ]; then
        success "SECRET設定完了: LINE_USER_ID"
    else
        die "LINE_USER_ID の設定に失敗しました"
    fi
}

# === メイン処理 ===
main() {
    echo ""
    echo "📮 COCOMI Repo Setup v${VERSION}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 引数からパスを取得（~を展開）
    local target_path="${1:-}"
    target_path="${target_path/#\~/$HOME}"

    # ① 前提条件チェック
    check_prerequisites "$@"

    # ② config.jsonからLINE設定を読み取り
    read_line_config

    # ③ CIファイルをコピー
    copy_ci_file "$target_path"

    # ④ git add → commit → push
    git_push "$target_path"

    # ⑤ GitHub Secretsを設定
    set_github_secrets "$target_path"

    # ⑥ 完了メッセージ
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🎉 セットアップ完了！${NC}"
    echo ""
    echo "  ✅ cocomi-ci.yml をコピー＆プッシュ済み"
    echo "  ✅ LINE_CHANNEL_ACCESS_TOKEN を設定済み"
    echo "  ✅ LINE_USER_ID を設定済み"
    echo ""
    echo "  次にこのリポにpushすると、COCOMI CIが自動実行されます"
    echo "  CI結果はLINEに通知されます 📱"
    echo ""
}

# 実行
main "$@"
