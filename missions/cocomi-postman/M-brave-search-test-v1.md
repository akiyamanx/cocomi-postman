<!-- mission: cocomi-postman -->
# Brave Search実機テスト — type:searchの動作確認

このミッションはステップパターン指示書v1.0の**type: search**（Brave Search API連携）の動作を確認するテストです。
cocomi-api-relayの/searchエンドポイント経由でBrave Searchが正しく動くか検証。

### Step 1/2: Brave Searchで検索テスト
<!-- on-fail: next -->
<!-- on-success: step-3 -->
<!-- type: search -->
<!-- query: Cloudflare Workers D1 database 2026 -->

cocomi-api-relayの/searchエンドポイント経由でBrave Search APIを叩きます。
成功すれば検索結果がJSON形式で返ってくるはず。

### Step 2/2: フォールバック検索（別クエリ）
<!-- on-fail: stop -->
<!-- type: search -->
<!-- query: PWA Progressive Web App tutorial -->

Step 1が失敗した場合のフォールバック。別のシンプルなクエリで再試行。
これも失敗した場合はBRAVE_SEARCH_KEYの設定やrelay側の問題を確認する必要あり。
