<!-- mission: cocomi-postman -->
# Brave Search フォールバックテスト — on-fail:nextの動作確認

このミッションはステップパターン指示書v1.0の**on-fail: next**（失敗→フォールバック遷移）の動作を確認するテストです。
Step 1はわざと失敗するクエリ（空クエリ）を使い、Step 2の正常な検索にフォールバックする。

### Step 1/2: わざと失敗する検索（空クエリ）
<!-- on-fail: next -->
<!-- on-success: step-3 -->
<!-- type: search -->
<!-- query:  -->

意図的に空クエリを送信。search.jsのバリデーションで400エラーが返るはず。
失敗したらon-fail: nextでStep 2にフォールバックする動作を検証。

### Step 2/2: フォールバック検索（正常クエリ）
<!-- on-fail: stop -->
<!-- type: search -->
<!-- query: Termux Android development tools 2026 -->

Step 1の失敗を受けてフォールバック実行される検索。
こちらは正常なクエリなので成功するはず。
