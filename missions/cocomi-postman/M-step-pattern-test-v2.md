<!-- mission: cocomi-postman -->
# ステップパターン指示書テスト v2 — cocomi-postmanリポ内で完結

このミッションはステップパターン指示書v1.0の条件分岐動作を確認するテストです。
cocomi-postmanリポ内のファイルを確認するだけなのでCI不合格の心配なし。

### Step 1/3: escalation.shの存在確認
<!-- on-fail: next -->
<!-- on-success: step-3 -->

新しく追加されたcore/escalation.shファイルの存在と内容を確認します。

やること:
1. `core/escalation.sh` をReadで開く
2. 先頭のコメント（「このファイルは: COCOMI Postman エスカレーション機能」）が含まれていることを確認
3. 確認できたら成功として終了（何も変更しない）

※ このStepが成功したらStep 2はスキップされStep 3に飛びます。

### Step 2/3: フォールバック — escalation.shが見つからない場合
<!-- on-fail: stop -->
<!-- on-success: step-3 -->

Step 1が失敗した場合のフォールバックです。

やること:
1. `ls core/` でファイル一覧を確認
2. escalation.shが存在しない場合、その旨を標準出力に出力
3. 何もファイルを変更しない（確認のみ）

### Step 3/3: step-pattern.shの存在確認
<!-- on-fail: stop -->

最終ステップとして、もう1つの新ファイルも確認します。

やること:
1. `core/step-pattern.sh` をReadで開く
2. 先頭のコメント（「ステップパターン実行エンジン」）が含まれていることを確認
3. 確認できたら成功として終了（何も変更しない）
