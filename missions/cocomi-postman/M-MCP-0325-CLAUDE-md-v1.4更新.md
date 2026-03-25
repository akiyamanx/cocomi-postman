<!-- mission: cocomi-postman -->
# 📝 CLAUDE.md v1.4 更新 — MCP経由パイプライン情報追記

## 目的
CLAUDE.md v1.3 → v1.4 に更新する。
Phase2で開通したMCP経由パイプラインと、Claude Codeの3層セキュリティ情報を追記して、
今後の自動タスク実行時にClaude Codeが参照できるようにする。

## タスク

### Task 1: CLAUDE.md を読み込んで現状確認（Read）
まず `CLAUDE.md` の全文を読み込み、現在のバージョンが v1.3 であることを確認。

### Task 2: バージョン番号更新（Edit）
CLAUDE.md の先頭付近にある以下の行を更新:
```
最終更新: 2026-03-25 v1.3
```
↓
```
最終更新: 2026-03-25 v1.4
```

### Task 3: 「🔧 開発ルール」セクションの末尾に以下を追記（Edit）

「参考: https://github.com/anthropics/claude-code/issues/18342」の行の後に、以下を追記:

```

## 🔐 Claude Code 3層セキュリティ（v1.4追加）

Claude Codeには3つのセキュリティレイヤーがある:

Layer 1（/tmp権限）: Node.jsが/tmpにアクセスする問題 → proot -b で解決済み
Layer 2（Tool permissions）: Bashツール使用可否 → settings.jsonで全開放済み
Layer 3（Built-in sandbox）: Bashでのファイルシステム変更はハードコードでブロック → 突破不可、仕様

重要: Layer 3により mkdir/rm/cp 等のBashコマンドはブロックされるが、Write/Editツールは自由に使える。
コード修正タスクはWrite/Editで完結させること。ファイル作成もWriteで行う。

## 📬 MCP経由パイプライン（v1.4追加）

指示書の受け取りから実行までの流れ:
1. クロちゃん（claude.ai）がMCP github_push_fileで missions/ に指示書をpush
2. タブレットのpostman.sh自動モードがgit pullで指示書を検出
3. retry.sh がproot方式でClaude Codeを起動
4. Claude Codeが指示書を読んでWrite/Editで実行
5. 完了後postman.shがgit push → クロちゃんがMCPでレポート確認

指示書のルール:
- 先頭に <!-- mission: プロジェクトID --> が必須
- ファイル名: M-{テーマ名}.md
- Write/Editで完結するタスクを書く（Bash書き込み系は避ける）
```

### Task 4: ファイル構成のretry.shバージョンが v1.9 になっていることを確認（Read）
既に v1.9 になっているはずだが念のため確認。

## 成功条件
- CLAUDE.md のバージョンが v1.4 になっている
- 「3層セキュリティ」セクションが追加されている
- 「MCP経由パイプライン」セクションが追加されている
- 既存の内容が壊れていない
- ファイル全体が500行以内に収まっている

## 注意
- Write/Editツールのみ使用すること（Bash書き込み系は不要）
- git pushはPostmanが自動で行うので不要
- 追記は「🔧 開発ルール」セクション内の末尾（ファイル命名ルールセクションの前）に入れること
