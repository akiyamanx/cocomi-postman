<!-- dest: capsules/master -->
# ☁️ Cloudflare Worker (cocomi-worker) — 仕様書
# 最終更新: 2026-02-23 v1.4
# 作成: アキヤ & クロちゃん（Claude Opus 4.6）

---

## 📋 概要

cocomi-workerは **Cloudflare Workers** 上で動作するJavaScriptプログラム。
LINEのWebhookを受信して、テキスト指示やファイルをGitHubに配達する「郵便局員」。

**デプロイ先:** Cloudflare Dashboard → Workers & Pages → cocomi-worker
**更新方法:** Dashboard の Edit code でworker.jsの中身を貼り替え → Deploy
**現在のバージョン:** v1.4

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

## 📱 LINEコマンド一覧

LINEで以下のテキストを送ると、コマンドとして処理される。
コマンドに該当しないテキストは「テキスト指示」として処理される。

| コマンド | 別名 | 機能 |
|---|---|---|
| **状態** | — | Workerのバージョンと機能一覧を表示 |
| **カプセル** | capsule | カプセル保管庫（daily/master/plans）の中身を表示 |
| **アイデア一覧** | アイディア一覧, ideas | アイデア保管庫（app/business/cocomi/other）の中身を表示 |
| **フォルダ一覧** | フォルダ, folders | 全フォルダの構造と件数を表示（Trees API使用） |
| **フォルダ ○○** | — | 指定フォルダの中身（サブフォルダ＋ファイル一覧）を表示 |

### コマンドの使い方の例

```
「状態」          → Workerバージョン確認
「カプセル」      → capsules/daily, master, plansの中身
「アイデア一覧」  → capsules/ideas/の4カテゴリの中身
「フォルダ一覧」  → 全体のフォルダ構造を一覧表示
「フォルダ capsules/daily」  → capsules/daily/のファイル一覧
「フォルダ missions」        → missions/のサブフォルダ一覧
「フォルダ reports/cocomi-postman」 → レポートのファイル一覧
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
| Reply API | Worker→LINEへの返信 |
| Content API | ファイルのバイナリデータ取得 |

### GitHub API
| エンドポイント | 用途 |
|---|---|
| Contents API (PUT) | ファイルのpush（新規＆上書き） |
| Contents API (GET) | ファイルのSHA取得＆フォルダ一覧 |
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

## 📌 既知の制限事項

- **ファイル形式:** 現在.mdファイルのテキストのみ対応。画像やバイナリは非対応。
- **Workerのタイムアウト:** 無料プランはCPU時間に制限あり。API呼び出しは最小限に。
- **LINE返信:** 1つのreplyTokenで1回しか返信できない。
- **コマンド判定:** 完全一致のみ。「フォルダ」コマンドは正規表現で「フォルダ ○○」形式を判定。
