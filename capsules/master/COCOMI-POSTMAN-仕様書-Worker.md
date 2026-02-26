<!-- dest: capsules/master -->
# ☁️ Cloudflare Worker (cocomi-worker) — 仕様書
# 最終更新: 2026-02-27 v2.4
# 作成: アキヤ & クロちゃん（Claude Opus 4.6）

---

## 📋 概要

cocomi-workerは **Cloudflare Workers** 上で動作するJavaScriptプログラム。
LINEのWebhookを受信して、テキスト指示やファイルをGitHubに配達する「郵便局員」。

**デプロイ先:** Cloudflare Dashboard → Workers & Pages → cocomi-worker
**更新方法:** Dashboard の Edit code でworker.jsの中身を貼り替え → Deploy
**現在のバージョン:** v2.4

---

## 🔄 処理フロー

```
LINE (Webhook POST)
  ↓
署名検証 (HMAC-SHA256)
  ↓ 合格
メッセージ種別判定
  ├── type: file → ファイル処理へ
  └── type: text → コマンド判定 → 通常指示処理へ
```

---

## 📱 LINEコマンド一覧（v2.4時点）

LINEで以下のテキストを送ると、コマンドとして処理される。
コマンドに該当しないテキストは「テキスト指示」として処理される。

| コマンド | 別名 | 動作 | 返信形式 |
|---|---|---|---|
| **状態** | ポストマン, postman, ステータス | システム情報表示 | テキスト |
| **ヘルプ** | help, ?, ？ | コマンド一覧表示 | テキスト |
| **ヘルプ 指示** | ヘルプ指示 | 指示の送り方ガイド | テキスト |
| **カプセル** | capsule | カプセル保管庫（日付順Flex） | Flex Message |
| **カプセル N** | capsule N | カプセルN番目ページ | Flex Message |
| **アイデア一覧** | ideas, アイデア | アイデア保管庫 | テキスト |
| **フォルダ一覧** | folders | 全フォルダ構造 | テキスト |
| **フォルダ ○○** | — | 指定フォルダ中身（日付別行Flex） | Flex Message |
| **読む ○○** | read ○○ | ファイル内容表示（5000字制限） | テキスト |

### コマンドの使い方の例

```
「状態」          → Workerバージョン確認
「ヘルプ」        → コマンド一覧
「ヘルプ 指示」   → 指示書の書き方ガイド
「カプセル」      → 全カプセルを日付順で表示（Flexボタン式）
「カプセル 2」    → カプセル2ページ目を表示
「アイデア一覧」  → capsules/ideas/の4カテゴリの中身
「フォルダ一覧」  → 全体のフォルダ構造を一覧表示
「フォルダ capsules/daily」  → capsules/daily/のファイル一覧（Flex）
「フォルダ missions」        → missions/のサブフォルダ一覧
「読む capsules/daily/2026-02-26_DIFF総合.md」 → ファイルの内容を表示
```

**注意:** 「フォルダ ○○」は「フォルダ」＋半角スペース＋フォルダ名。
スペースなしや「フォルダ」なしだとテキスト指示扱いになる。

---

## 📋 テキスト指示の仕様

コマンドに該当しないテキストは「テキスト指示」として処理される。

### 書式
```
プロジェクト名: 指示内容
```
（半角コロン or 全角コロンどちらでもOK）

### プロジェクト名の省略
プロジェクト名を省略した場合、デフォルトの **genba-pro** に配達される。

### 対応プロジェクト名
genba-pro, culo-chan, maintenance-map, cocomi-postman, cocomi-family

### 生成されるファイル
```
missions/{プロジェクト名}/M-LINE-{MMDD}-{HHmm}-{指示の要約}.md
```

### ファイル名のサニタイズ
指示内容から安全なファイル名を生成する：
- 拡張子っぽい文字列（.md, .html等）を除去
- 記号（「」()[]{}.,!?#&@等）を除去
- 空白を除去
- 30文字で切り詰め

---

## 📁 ファイル配達の仕様

LINEでファイル（.md）を送信すると、3段階ルーティングで保管先を決定する。

### ルーティング優先順位

```
① キーワードマッチ（ファイル名で自動判定）
  ↓ 該当なし
② destタグ（ファイル中身の先頭5行に <!-- dest: パス --> がある）
  ↓ 該当なし
③ デフォルト（inbox/ に保管）
```

### ① キーワードルーティングルール

| ファイル名に含むキーワード | 保管先 |
|---|---|
| MASTER | capsules/master |
| DIFF_DEV, 開発カプセル | capsules/daily |
| DIFF_総合, 思い出カプセル | capsules/daily |
| 引き継ぎ, セッションまとめ, セッション完全まとめ | capsules/daily |
| 企画書 | capsules/plans |
| 指示書, Step, step | missions/inbox |

### ② destタグルーティング

ファイルの先頭5行以内に以下の記述があると、指定パスに配置される。
```html
<!-- dest: missions/cocomi-postman -->
```

**GitHubの仕組み上、フォルダが存在しなくても自動で作成される。**
だからクロちゃんが新しいフォルダパスを指定すれば、自動で新フォルダができる。

### ③ デフォルト
どのルールにも該当しない場合、**inbox/** に保管される。

### LINE返信で確認できる情報
- 📂 保管先パス
- 📄 ファイル名
- 📏 サイズ（文字数）
- ルーティング方法（🏷️自動判定 / 🎯dest指定 / 📥デフォルト）

---

## 🔌 使用しているAPI

### LINE Messaging API
| エンドポイント | 用途 |
|---|---|
| Webhook (POST) | LINE→Workerへのメッセージ受信 |
| Reply API (text) | Worker→LINEへのテキスト返信 |
| Reply API (flex) | Worker→LINEへのFlex Message返信（v2.2〜） |
| Content API | ファイルのバイナリデータ取得 |

### GitHub API
| エンドポイント | 用途 |
|---|---|
| Contents API (PUT) | ファイルのpush（新規＆上書き） |
| Contents API (GET) | ファイルのSHA取得＆フォルダ一覧＆ファイル内容取得（v2.1〜） |
| Trees API (GET) | リポジトリ全体のツリー構造取得 |

### Trees API について
フォルダ一覧コマンドでは **Git Trees API** を使用。
`/git/trees/main?recursive=1` で全ファイル・フォルダを **1回のAPI呼び出し** で取得。
これにより、再帰的なAPI呼び出しによるWorkerタイムアウトを防止している。

---

## ⚙️ 環境変数（Cloudflare Dashboard で設定）

| 変数名 | 内容 | 設定場所 |
|---|---|---|
| LINE_CHANNEL_SECRET | LINE署名検証用 | Settings → Variables |
| LINE_CHANNEL_ACCESS_TOKEN | LINE API用トークン | Settings → Variables |
| GITHUB_TOKEN | GitHub PAT | Settings → Variables |

---

## 🔒 セキュリティ

- **署名検証:** LINE Webhookは HMAC-SHA256 で署名検証。不正リクエストは401で拒否。
- **GitHub Token:** Cloudflare環境変数に保管。コードには含まない。
- **LINE Token:** 同上。

---

## 🛠️ 更新・デプロイ手順

1. クロちゃん（claude.ai）で新しいworker.jsを作成
2. ファイルをダウンロード
3. Cloudflare Dashboard → Workers & Pages → cocomi-worker → Edit code
4. 全選択 → 削除 → 新しいコードを貼り付け
5. 「Save and Deploy」をクリック
6. LINEで「状態」と送って、バージョンが更新されたか確認

---

## 📲 Flex Message対応（v2.2〜v2.4）

### 概要
v2.2からカプセル・フォルダ系コマンドの返信が **LINE Flex Message** に変更。
タップ可能なボタン式UIでファイル一覧を表示し、ファイル名タップで内容を表示する。

### Flex Messageの表示仕様

#### カプセルコマンド（v2.2〜v2.4）
- カプセルコマンド → Flex Messageボタン式で返信
- ファイル名タップで「読む パス/ファイル名」が自動送信
- ヘッダー内訳表示: 📅22 📚13 📋2 形式（v2.4で短縮化）

#### フォルダ ○○ コマンド（v2.2〜v2.4）
- フォルダ ○○ コマンド → Flex Messageボタン式で返信
- ファイル名タップで「読む パス/ファイル名」が自動送信

#### ページネーション（v2.3追加）
- カプセルコマンドが「カプセル N」形式でページ指定可能
- 1ページ10件表示
- 「もっと見る」ボタン（緑色、style: primary）で次ページ

#### 日付抽出ソート＆日付別行表示（v2.4追加）
- ファイル名のどこにあってもYYYY-MM-DDを正規表現で抽出
- ソート順: 日付あり→日付降順、日付なし→末尾（ファイル名降順）
- daily/master/plansセクション別表示をやめ、全ファイル日付順で混合表示
- 日付別行表示: 緑色の日付見出し（📅 MM-DD）+ ファイル名ボタン
- 同じ日付は1回だけ見出し表示
- ファイル名は日付・拡張子を除去して短縮表示

---

## 🔧 新関数一覧（v2.1〜v2.4で追加）

| 関数名 | バージョン | 役割 |
|---|---|---|
| readFileFromGitHub() | v2.1 | GitHub Contents APIでファイル内容取得＆Base64デコード |
| replyFlexToLine() | v2.2 | Flex Message形式でLINE返信 |
| buildFileListFlex() | v2.2 | ファイル一覧をボタン付きFlex Messageに変換 |
| buildFolderContentsFlex() | v2.2 | フォルダ内容をFlex Messageに変換 |
| extractDateFromName() | v2.4 | ファイル名からYYYY-MM-DD日付を正規表現抽出 |
| shortenFileNameOnly() | v2.4 | 日付・拡張子除去のファイル名のみ返す |
| shortenDisplayName() | v2.4 | 📝 MM-DD名前 形式の表示名（後方互換用） |

---

## 📊 バージョン履歴

| Ver | 日付 | 内容 | 行数 |
|---|---|---|---|
| v1.0 | 2026-02-20 | テキスト指示→GitHub push基本機能 | — |
| v1.1 | 2026-02-22 | ファイル受信＆カプセル自動保管 | — |
| v1.2 | 2026-02-22 | sanitizeForFilename強化 | — |
| v1.3 | 2026-02-23 | destタグルーティング＆アイデア一覧 | — |
| v1.4 | 2026-02-23 | フォルダ一覧＆中身確認コマンド（Trees API） | 791 |
| v2.0 | 2026-02-24 | 安全バリデーション | 791 |
| v2.1 | 2026-02-26 | リッチメニュー対応コマンド（ヘルプ/読む/状態エイリアス） | 925 |
| v2.2 | 2026-02-26 | Flex Messageタップ式ファイル閲覧 | 1096 |
| v2.3 | 2026-02-26 | ページネーション＆ファイル名降順ソート | 1151 |
| v2.4 | 2026-02-26 | 日付抽出ソート＆日付別行表示＆ファイル名短縮 | 1258 |

---

## 📌 既知の制限事項

- **ファイル形式:** 現在.mdファイルのテキストのみ対応。画像やバイナリは非対応。
- **Workerのタイムアウト:** 無料プランはCPU時間に制限あり。API呼び出しは最小限に。
- **LINE返信:** 1つのreplyTokenで1回しか返信できない。
- **コマンド判定:** 完全一致のみ。「フォルダ」コマンドは正規表現で「フォルダ ○○」形式を判定。
- **読むコマンド:** ファイル内容は5000字で切り詰め。
