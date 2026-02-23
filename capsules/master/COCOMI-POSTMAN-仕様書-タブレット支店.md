<!-- dest: capsules/master -->
# 📋 タブレット支店（postman.sh & core/）— 仕様書
# 最終更新: 2026-02-23 v1.0
# 作成: アキヤ & クロちゃん（Claude Opus 4.6）

---

## 📋 概要

タブレット支店は、Galaxyタブレット上の **Termux** で動作するシェルスクリプト群。
GitHubに配達された指示書を検知し、Claude Codeで自動実行する「本店」。

---

## 🔧 コンポーネント構成

```
postman.sh (本店メイン v2.0)
  ├── core/executor.sh    (実行エンジン v2.0)
  ├── core/step-runner.sh (ステップ実行 v2.0.2)
  ├── core/retry.sh       (リトライ v1.5)
  └── core/notifier.sh    (LINE通知 v1.4)
```

---

## 📮 postman.sh — 本店メイン v2.0

**役割:** 指示書の検知 → 実行エンジンへの振り分け → ループ監視

### 動作モード

| モード | 起動方法 | 動作 |
|---|---|---|
| **手動モード** | `./postman.sh` | 1回だけ指示書を確認・実行 |
| **自動モード (auto_mode)** | `./postman.sh auto` | check_interval分ごとにループ監視 |

### 自動モードの処理フロー
```
① git pull でGitHubから最新を取得
  ↓
② missions/{プロジェクト名}/ に新しい指示書があるか確認
  ↓
③ 指示書発見 → executor.sh に渡して実行
  ↓
④ check_interval分（config.jsonで設定）待機
  ↓
① に戻る（ループ）
```

### config.json の参照フィールド
```json
{
  "default_project": "genba-pro",       // デフォルトプロジェクト
  "projects": {
    "プロジェクトID": {
      "name": "表示名",
      "repo": "owner/repo",             // GitHubリポ
      "local_path": "$HOME/リポフォルダ" // ローカルパス
    }
  },
  "line": {
    "enabled": true,
    "channel_access_token": "トークン",
    "user_id": "ユーザーID",
    "notify_on": {
      "mission_complete": true,
      "mission_error": true
    }
  },
  "check_interval_minutes": 5
}
```

---

## ⚙️ core/executor.sh — 実行エンジン v2.0

**役割:** 指示書を読み、Claude Codeを起動して実行させる

### 処理フロー
```
① 指示書のMarkdownを読み込み
  ↓
② 指示書にStep記法（### Step N/M）があるか判定
  ├── ステップあり → step-runner.sh に委譲
  └── ステップなし → 単発実行
  ↓
③ 対象プロジェクトのローカルフォルダに移動
  ↓
④ Claude Code を起動（指示内容を渡す）
  ↓
⑤ 実行結果に基づいて git add, commit, push
  ↓
⑥ notifier.sh で LINE通知
  ↓
⑦ 完了レポートを reports/ に保存
```

### Claude Code の起動
```bash
export TMPDIR=~/tmp && mkdir -p ~/tmp
claude --dangerously-skip-permissions -p "指示内容"
```
※ Termuxの/tmp権限エラー対策で毎回TMPDIRを設定

---

## 🔄 core/step-runner.sh — ステップ実行エンジン v2.0.2

**役割:** マルチステップ指示書を1ステップずつ順番に実行する

### ステップ指示書の書式
```markdown
# ミッション名
## 概要

### Step 1/3: ○○の実装
（Step 1の詳細指示）

### Step 2/3: △△の修正
（Step 2の詳細指示）

### Step 3/3: □□のテスト
（Step 3の詳細指示）
```

### 処理フロー
```
① 指示書から全ステップを抽出
  ↓
② Step 1 の内容を Claude Code に渡して実行
  ↓
③ git push → CI（GitHub Actions）が走る
  ↓
④ CI結果を確認
  ├── ✅ 合格 → LINE通知「Step 1/3完了！自動でStep 2/3に進みます」
  │           → 次のステップへ
  └── ❌ 失敗 → retry.sh でリトライ or エラー通知
  ↓
⑤ 全ステップ完了 → 完了レポート生成 → LINE通知
```

### 重要な仕様
- **CI合格が次ステップの条件:** CIが通らないと次に進まない
- **自動継続:** CI合格後は自動で次ステップに進む（アキヤの操作不要）
- **進捗通知:** 各ステップ完了時にLINEで進捗通知
- **レポート:** 全完了時に reports/{プロジェクト}/ にレポート保存

---

## 🔁 core/retry.sh — リトライエンジン v1.5

**役割:** Claude Codeの実行やCI失敗時の自動リトライ

### リトライ条件
- Claude Codeの実行がエラーで終了
- CIテストが失敗
- git pushが失敗

### リトライ回数
設定可能。デフォルトは3回まで。

---

## 📢 core/notifier.sh — LINE通知 v1.4

**役割:** 実行結果をLINEに通知する

### 通知タイミング
| イベント | 通知内容 |
|---|---|
| ミッション完了 | プロジェクト名、ミッション名、結果（成功/失敗） |
| ステップ進捗 | Step N/M完了、CI結果、次ステップへ |
| 全ステップ完了 | 🎊 全Nステップ完了！ |
| エラー発生 | エラー内容、リトライ回数 |

### LINE通知の仕組み
config.json の `line.channel_access_token` と `line.user_id` を使用。
LINE Push API でアキヤに直接通知。

### 通知メッセージに含まれる情報
- GitHub Actionsへのリンク
- アプリURL（GitHub Pages公開の場合）
- cocomi-ci.yml のLINE通知テンプレートに基づく

---

## 🚀 CI/CD — cocomi-ci.yml

### 概要
全7リポジトリで共通のCIワークフロー。
git pushをトリガーにGitHub Actionsが自動実行。

### テスト項目
| テスト | 内容 |
|---|---|
| ShellCheck | シェルスクリプトの文法チェック |
| 500行ルール | 各ファイルが500行以内か |
| 先頭コメント | ファイル先頭に日本語コメントがあるか |
| バージョン番号 | 変更箇所にバージョン番号があるか |
| セキュリティ | APIキーやトークンの漏洩チェック |

### CI結果のLINE通知
CIが完了すると自動でLINEに通知。
メッセージにはGitHub Actionsへのリンクと結果サマリーが含まれる。

### 新リポへのCI追加
```bash
./cocomi-repo-setup.sh ~/新リポフォルダ
```
cocomi-ci.ymlの配置とGitHub Secrets（LINE_CHANNEL_ACCESS_TOKEN, LINE_USER_ID）を自動設定。

---

## 🛠️ Termux環境の注意点

### /tmp権限エラー対策
Claude Code起動前に毎回実行：
```bash
export TMPDIR=~/tmp && mkdir -p ~/tmp
```

### Claude Codeがgit pushできない場合
`/exit` でClaude Codeを終了 → 手動で `git push`

### 自動モードの起動
```bash
cd ~/cocomi-postman
./postman.sh auto
```
バックグラウンドで動かす場合：
```bash
nohup ./postman.sh auto &
```
