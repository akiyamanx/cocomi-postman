<!-- mission: cocomi-postman -->
# 🧪 proot + settings.json全開放テスト — Bash(mkdir/rm/cp)完全動作確認

## 目的
settings.jsonを `"Bash"` 全開放に更新した状態で、
retry.sh v1.9（proot方式）+ Bash系コマンドが正常動作するか最終検証。

## 前回の結果
proot方式で /tmp エラーは解消。ただしmkdir/rm/cpがClaude Codeのサンドボックスにブロックされた。
今回はsettings.jsonで `"Bash"` を全許可に変更したので、ブロックが解消されるか確認する。

## タスク

### Task 1: ディレクトリ作成（Bash mkdir）
```bash
mkdir -p tmp/settings-test-dir
```

### Task 2: ファイル作成（Bash echo）
```bash
echo "settings.json Bash全開放テスト成功！ $(date)" > tmp/settings-test-dir/test.txt
```

### Task 3: ファイルコピー（Bash cp）
```bash
cp tmp/settings-test-dir/test.txt tmp/settings-test-dir/copied.txt
```

### Task 4: 確認（Bash ls）
```bash
ls -la tmp/settings-test-dir/
```

### Task 5: クリーンアップ（Bash rm — 前回失敗した操作！）
```bash
rm -rf tmp/settings-test-dir
```

### Task 6: 削除確認（Bash ls）
```bash
ls tmp/ 2>&1
```
tmp/settings-test-dir が存在しないことを確認。

## 成功条件
- Task 1〜6が全てBashツールで実行され、エラーなし
- 特にTask 1（mkdir -p）とTask 5（rm -rf）がブロックされないこと
- 最終的にtmp/settings-test-dir が削除されていること

## 注意
- git pushはPostmanが行うので不要
