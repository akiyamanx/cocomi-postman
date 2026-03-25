<!-- mission: cocomi-postman -->
# 🧪 proot /tmp解決テスト — Bash系＋Write/Edit混合タスク

## 目的
retry.sh v1.9のproot方式（`proot -b $PREFIX/tmp:/tmp claude`）が
Bash系ツール（rm, mkdir等）でも正常動作するか検証する。

## タスク

### Task 1: テストファイル作成（Write — /tmp不要）
`tmp/proot-test-write.txt` に以下の内容でファイルを作成:
```
proot /tmp test - Write tool success
Created at: (現在時刻)
```

### Task 2: ディレクトリ作成（Bash mkdir — /tmp必要！）
Bashツールで以下を実行:
```bash
mkdir -p tmp/proot-test-dir
```

### Task 3: ファイルコピー（Bash cp — /tmp必要！）
Bashツールで以下を実行:
```bash
cp tmp/proot-test-write.txt tmp/proot-test-dir/copied.txt
```

### Task 4: ファイル削除（Bash rm — /tmp必要！これが前回失敗した操作）
Bashツールで以下を実行:
```bash
rm -rf tmp/proot-test-dir
```

### Task 5: 結果確認（Bash ls）
Bashツールで以下を実行して結果を表示:
```bash
ls -la tmp/
```

## 成功条件
- Task 1〜5が全てエラーなく完了すること
- 特にTask 2〜4のBash系ツールが /tmp エラーなしで動作すること
- tmp/proot-test-write.txt が残り、proot-test-dir は削除されていること

## 注意
- このテストファイル自体（tmp/proot-test-write.txt）はテスト完了後もそのまま残してOK
- git pushはPostmanが行うので不要
