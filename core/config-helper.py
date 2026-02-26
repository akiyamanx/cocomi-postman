#!/usr/bin/env python3
# このファイルは: COCOMI Postman config.json操作ヘルパー
# project-manager.shから呼ばれるJSONの安全な読み書きツール
# v1.0 新規作成 2026-02-26 - プロジェクト一覧/追加/削除/デフォルト変更
# bashのsedでJSON編集すると壊れるリスクがあるのでpythonで安全に処理する

import json
import sys
import os

# v1.0 config.jsonのパス
CONFIG_PATH = os.path.expanduser("~/cocomi-postman/config.json")

def load_config():
    """config.jsonを読み込む"""
    try:
        with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print("ERROR: config.jsonが見つかりません", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"ERROR: config.jsonの形式が不正です: {e}", file=sys.stderr)
        sys.exit(1)

def save_config(config):
    """config.jsonを保存する（バックアップ付き）"""
    # v1.0 書き込み前にバックアップ
    backup_path = CONFIG_PATH + ".bak"
    try:
        if os.path.exists(CONFIG_PATH):
            with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
                backup_data = f.read()
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(backup_data)
    except Exception:
        pass  # バックアップ失敗しても続行

    # v1.0 更新日付を記録
    from datetime import date
    config["_updated"] = str(date.today())

    try:
        with open(CONFIG_PATH, 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        # v1.0 書き込み失敗時はバックアップから復元
        print(f"ERROR: 保存に失敗しました: {e}", file=sys.stderr)
        if os.path.exists(backup_path):
            os.replace(backup_path, CONFIG_PATH)
            print("バックアップから復元しました", file=sys.stderr)
        sys.exit(1)

def cmd_list():
    """プロジェクト一覧を表示"""
    config = load_config()
    projects = config.get("projects", {})
    default = config.get("default_project", "")
    for pid, pinfo in projects.items():
        star = " ⭐" if pid == default else ""
        name = pinfo.get("name", pid)
        repo = pinfo.get("repo", "")
        path = pinfo.get("local_path", "")
        status = pinfo.get("status", "unknown")
        version = pinfo.get("current_version", "-")
        desc = pinfo.get("description", "")
        github = pinfo.get("github_url", "")
        # v1.0 タブ区切りで出力（bashで読みやすい）
        print(f"{pid}\t{name}\t{repo}\t{path}\t{status}\t{version}\t{desc}\t{github}{star}")

def cmd_list_ids():
    """プロジェクトID一覧だけ出力"""
    config = load_config()
    for pid in config.get("projects", {}):
        print(pid)

def cmd_add(pid, name, repo, local_path, github_url="", description=""):
    """新規プロジェクト追加"""
    config = load_config()
    projects = config.get("projects", {})

    if pid in projects:
        print(f"ERROR: プロジェクトID '{pid}' は既に存在します", file=sys.stderr)
        sys.exit(1)

    # v1.0 新規プロジェクトエントリ
    projects[pid] = {
        "name": name,
        "repo": repo,
        "local_path": local_path,
        "github_url": github_url,
        "subfolder": "",
        "status": "active",
        "current_version": "v0.1",
        "description": description
    }
    config["projects"] = projects
    save_config(config)
    print(f"OK: {name} ({pid}) を追加しました")

def cmd_remove(pid):
    """プロジェクト削除"""
    config = load_config()
    projects = config.get("projects", {})

    if pid not in projects:
        print(f"ERROR: プロジェクトID '{pid}' が見つかりません", file=sys.stderr)
        sys.exit(1)

    # v1.0 デフォルトプロジェクトは削除させない
    if config.get("default_project") == pid:
        print(f"ERROR: デフォルトプロジェクトは削除できません。先にデフォルトを変更してね", file=sys.stderr)
        sys.exit(1)

    name = projects[pid].get("name", pid)
    del projects[pid]
    config["projects"] = projects
    save_config(config)
    print(f"OK: {name} ({pid}) を削除しました")

def cmd_set_default(pid):
    """デフォルトプロジェクト変更"""
    config = load_config()
    if pid not in config.get("projects", {}):
        print(f"ERROR: プロジェクトID '{pid}' が見つかりません", file=sys.stderr)
        sys.exit(1)

    config["default_project"] = pid
    save_config(config)
    name = config["projects"][pid].get("name", pid)
    print(f"OK: デフォルトを {name} ({pid}) に変更しました")

def cmd_get_default():
    """現在のデフォルトプロジェクトIDを出力"""
    config = load_config()
    print(config.get("default_project", ""))

def cmd_edit(pid, field, value):
    """プロジェクトの特定フィールドを編集"""
    config = load_config()
    projects = config.get("projects", {})

    if pid not in projects:
        print(f"ERROR: プロジェクトID '{pid}' が見つかりません", file=sys.stderr)
        sys.exit(1)

    # v1.0 編集可能フィールド
    allowed = ["name", "repo", "local_path", "github_url", "description",
               "status", "current_version", "subfolder", "current_phase"]
    if field not in allowed:
        print(f"ERROR: '{field}' は編集できません。編集可能: {', '.join(allowed)}", file=sys.stderr)
        sys.exit(1)

    projects[pid][field] = value
    config["projects"] = projects
    save_config(config)
    print(f"OK: {pid} の {field} を '{value}' に更新しました")

# === メイン：コマンド振り分け ===
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("使い方: config-helper.py <command> [args...]")
        print("  list        - プロジェクト一覧")
        print("  list_ids    - プロジェクトID一覧")
        print("  add         - 追加 (pid name repo local_path [github_url] [description])")
        print("  remove      - 削除 (pid)")
        print("  set_default - デフォルト変更 (pid)")
        print("  get_default - デフォルト取得")
        print("  edit        - 編集 (pid field value)")
        sys.exit(0)

    cmd = sys.argv[1]

    if cmd == "list":
        cmd_list()
    elif cmd == "list_ids":
        cmd_list_ids()
    elif cmd == "add":
        if len(sys.argv) < 6:
            print("ERROR: add には pid name repo local_path が必要です", file=sys.stderr)
            sys.exit(1)
        github_url = sys.argv[6] if len(sys.argv) > 6 else ""
        description = sys.argv[7] if len(sys.argv) > 7 else ""
        cmd_add(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], github_url, description)
    elif cmd == "remove":
        if len(sys.argv) < 3:
            print("ERROR: remove には pid が必要です", file=sys.stderr)
            sys.exit(1)
        cmd_remove(sys.argv[2])
    elif cmd == "set_default":
        if len(sys.argv) < 3:
            print("ERROR: set_default には pid が必要です", file=sys.stderr)
            sys.exit(1)
        cmd_set_default(sys.argv[2])
    elif cmd == "get_default":
        cmd_get_default()
    elif cmd == "edit":
        if len(sys.argv) < 5:
            print("ERROR: edit には pid field value が必要です", file=sys.stderr)
            sys.exit(1)
        cmd_edit(sys.argv[2], sys.argv[3], " ".join(sys.argv[4:]))
    else:
        print(f"ERROR: 不明なコマンド '{cmd}'", file=sys.stderr)
        sys.exit(1)
