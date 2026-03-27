<!-- mission: COCOMITalk -->
# ステップパターン指示書テスト — 条件分岐動作確認

このミッションはステップパターン指示書（v1.0）の動作確認テストです。
Step 1が成功したらStep 2（フォールバック）をスキップしてStep 3に飛ぶことを検証します。

### Step 1/3: CLAUDE.mdにテストコメントを追加
<!-- on-fail: next -->
<!-- on-success: step-3 -->

COCOMITalkリポのルートにある既存ファイルの確認を行います。

やること:
1. リポジトリのルートで `ls` して現在のファイル一覧を確認
2. `test-mcp-push.md` ファイルが存在することを確認
3. 確認できたら、そのファイルの末尾に以下の1行を追加:

```
<!-- step-pattern-test: 2026-03-27 success -->
```

Write ツールを使って追記してください。

### Step 2/3: フォールバック — 別の方法で確認（Step 1失敗時のみ実行）
<!-- on-fail: stop -->
<!-- on-success: step-3 -->

Step 1が失敗した場合のフォールバックです。
`test-mcp-push.md` が見つからない場合、新規作成してください。

やること:
1. Write ツールで `test-mcp-push.md` を新規作成
2. 内容: `# Step Pattern Test\n\nCreated by step-pattern fallback.`

### Step 3/3: 最終確認
<!-- on-fail: stop -->

Step 1 または Step 2 の成果物を確認します。

やること:
1. `test-mcp-push.md` の内容を Read で確認
2. ファイルが存在し、内容が正しいことを確認
3. 確認できたら何もしない（成功として終了）
