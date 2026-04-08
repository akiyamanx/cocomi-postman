# P-EXEC-20260408-0900 デュアルソース方式 動作確認テスト

## 🎯 目的
Postman進化版の「デュアルソース方式」（plans方式）の初回動作確認。
plans/に詳細指示書を置き、missions/に短いトリガーを置く2ファイル構成が正しく動くかを検証する。

## 📋 タスク内容
**超シンプルな動作確認のみ**。実害のないファイル1つ作成して終わり。

### Step 1: テストファイル作成
- 作成先: cocomi-postman リポの `tmp/dual-source-test.txt`
- 使用ツール: Write（Bash不要）
- 内容: 以下のテキスト（実行日時は実際の日時に置換）

```
Hello from plans方式! 🎉
実行日時: 2026-04-08
これはPostman進化版デュアルソース方式の初回動作確認です。
クロちゃん（WEB版）が plans/ と missions/ の2ファイルを push し、
Postmanが missions/ を検出して Claude Code が実行しました。
```

### Step 2: 結果記録（必須）
作業完了時、必ず以下の通り `save_code_log` MCPツールを呼ぶこと：

```
mission_name: "M-EXEC-20260408-0900-dual-source-hello"
project: "cocomi-postman"
status: "success"  ← 成功時。失敗したら "error"
output: 実際にやった内容を200文字以内で（例: tmp/dual-source-test.txtを作成。Writeツール使用、エラーなし）
analysis: デュアルソース方式の所感を100文字以内で（例: スムーズに動作。引っかかった点なし）
```

## ✅ 成功条件
1. `tmp/dual-source-test.txt` がリポに作成されている
2. `save_code_log` でログが D1 に記録されている
3. クロちゃん（WEB版）が後で `get_code_logs` で結果を確認できる

## 📝 補足
- このテストは「ファイルを作るだけ」の最小タスク。Bash実行不要、Writeツールだけで完結
- 既存のコードや設定には一切触らない
- 完了したらPostman側がレポートを `reports/cocomi-postman/` に書く
- save_code_logの呼び忘れだけは絶対NG。これがデュアルソース方式の検証ポイント

---
作成: WEBクロちゃん 2026-04-08
バージョン: P-EXEC v1.0（デュアルソース初回テスト・A案改善版）
