---
title: "COCOMITalk design-tokens.css 新規作成（UI/UX洗練化Phase1）"
date: "2026-04-08"
author: "WEBクロちゃん🔮"
mission_id: "M-EXEC-20260408-1700-design-tokens-css"
target_repo: "COCOMITalk"
priority: "GREEN"
tags: [COCOMITalk, UI, UX, デザイントークン, Phase1, 実運用テスト, 他リポ操作]
---

# P-EXEC-20260408-1700 COCOMITalk design-tokens.css 新規作成

## 🎯 目的
COCOMITalkのUI/UX洗練化Phase1の第一歩として、デザイントークン定義ファイル `design-tokens.css` を新規作成し、index.htmlとsw.jsで読み込ませる。

**この実行は同時に「Postman進化版デュアルソース方式 × 他リポ操作パターン」の初回実運用テストを兼ねる。**

## 📋 重要な前提

### 作業対象リポ
- **このPLANSファイルがあるリポ**: `cocomi-postman`
- **実際にファイルを作成・修正するリポ**: `COCOMITalk`（別リポ）

つまりClaude Codeは、作業前に **COCOMITalkリポをcloneまたは既存のcloneディレクトリへ移動** する必要がある。

### 安全方針
- **既存ファイルは一切壊さない**
- 既存`styles.css`の`:root`は**触らない**（二重定義になるが後勝ちで同値、無害）
- 既存色・既存変数名は**そのまま維持**（リネームは別タスク）
- 影響範囲は3ファイルのみ（design-tokens.css新規＋index.html＋sw.js）

## 📋 タスク内容

### Step 0: 準備（COCOMITalkリポへ）

```bash
# Termuxホームから作業
cd ~

# COCOMITalkがあれば最新化、なければclone
if [ -d "COCOMITalk" ]; then
  cd COCOMITalk && git pull origin main
else
  git clone https://github.com/akiyamanx/COCOMITalk.git
  cd COCOMITalk
fi

# 現在地確認
pwd
git status
```

### Step 1: design-tokens.css を新規作成

作成先: `COCOMITalkリポ直下/design-tokens.css`
使用ツール: Write
内容: 以下を**そのまま**書き込む（70行）。

```css
/* design-tokens.css v1.0
 * COCOMITalk デザイントークン定義ファイル
 * 役割: UI/UX洗練化Phase1の第一歩。色・余白・角丸・影・フォント等の
 *       デザインの基本ルールを一元管理する。
 * 設計方針: 既存styles.cssの:root値を維持しつつ、構想カプセル仕様の
 *           不足分（余白3段階・統一影）を追加する。styles.cssの:rootは
 *           本ファイル読込後に上書きするため、当面は二重定義となる
 *           （既存挙動保護のため、削除は次フェーズで実施）。
 * 関連: ideas/2026-04-08_cocomitalk-uiux-and-dressup-system.md
 */

:root {
  /* ========== 三姉妹カラー（既存維持） ========== */
  /* ここちゃん（koko）: ピンク系 */
  --koko-primary: #FF6B9D;
  --koko-light: #FFE0EB;
  --koko-dark: #D44A7A;
  --koko-bg: #FFF5F8;

  /* お姉ちゃん（gpt）: 紫系 */
  --gpt-primary: #6B5CE7;
  --gpt-light: #E8E5FF;
  --gpt-dark: #4A3FC7;
  --gpt-bg: #F7F5FF;

  /* クロちゃん（claude）: オレンジ系 */
  --claude-primary: #E6783E;
  --claude-light: #FFEEE5;
  --claude-dark: #C45A22;
  --claude-bg: #FFF8F3;

  /* ========== 背景・テキスト（既存維持） ========== */
  --bg-main: #FEFCFA;
  --bg-chat: #FAF7F4;
  --text-primary: #2D2520;
  --text-secondary: #8B7E74;
  --text-light: #B5AAA0;
  --border: #EDE8E3;

  /* ========== 影（既存＋新規） ========== */
  --shadow-sm: 0 1px 3px rgba(45, 37, 32, 0.08);
  /* v1.0新規: 構想カプセル仕様の統一ソフトシャドウ */
  --shadow-soft: 0 2px 8px rgba(45, 37, 32, 0.10);

  /* ========== アクティブ姉妹（既存維持） ========== */
  --active-primary: var(--koko-primary);
  --active-light: var(--koko-light);
  --active-dark: var(--koko-dark);
  --active-bg: var(--koko-bg);

  /* ========== フォント（既存維持） ========== */
  --font-main: 'Zen Maru Gothic', 'M PLUS Rounded 1c', 'Hiragino Maru Gothic Pro', sans-serif;

  /* ========== レイアウト（既存維持） ========== */
  --header-height: 52px;
  --tab-height: 48px;
  --max-width: 640px;

  /* ========== 角丸（既存維持） ========== */
  --radius-sm: 8px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --radius-full: 9999px;

  /* ========== 余白（v1.0新規・構想カプセル仕様） ========== */
  /* Phase2以降で他CSSファイルの直書きpx値をこれに置換していく */
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
}
```

### Step 2: index.html を編集

使用ツール: Edit（str_replace相当）

**変更1: 先頭コメント更新（2行目）**

old:
```html
<!-- v1.7 相談トピック連携 - consultation-ui.js + consultation-styles.css 追加 -->
```

new:
```html
<!-- v1.8 デザイントークン化Phase1 - design-tokens.css 追加 -->
```

**変更2: design-tokens.css読み込み追加（26行目の前）**

old:
```html
  <link href="https://fonts.googleapis.com/css2?family=Zen+Maru+Gothic:wght@400;500;700&family=M+PLUS+Rounded+1c:wght@400;500;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
```

new:
```html
  <link href="https://fonts.googleapis.com/css2?family=Zen+Maru+Gothic:wght@400;500;700&family=M+PLUS+Rounded+1c:wght@400;500;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="design-tokens.css">
  <link rel="stylesheet" href="styles.css">
```

**重要**: design-tokens.css は styles.css より**前**に読み込む。これにより将来styles.cssから:rootを削除した時に安全な順序になる。

### Step 3: sw.js を編集

使用ツール: Edit（str_replace相当）

**変更1: CACHE_NAME 更新（4行目）**

old:
```javascript
const CACHE_NAME = 'cocomitalk-v3.58';
```

new:
```javascript
const CACHE_NAME = 'cocomitalk-v3.59';
```

**変更2: キャッシュリストに追加（7行目）**

old:
```javascript
  './', './index.html', './styles.css', './meeting-styles.css',
```

new:
```javascript
  './', './index.html', './design-tokens.css', './styles.css', './meeting-styles.css',
```

### Step 4: 動作確認

```bash
# COCOMITalkリポ内で
ls -la design-tokens.css
wc -l design-tokens.css
grep "design-tokens" index.html
grep "design-tokens" sw.js
grep "v3.59" sw.js
```

**期待結果:**
- `design-tokens.css` が存在する（70行）
- `index.html` にdesign-tokens.cssへのlinkがある
- `sw.js` にdesign-tokens.cssのキャッシュ登録がある
- `sw.js` の CACHE_NAME が v3.59 になっている

### Step 5: COCOMITalkリポにcommit & push

```bash
cd ~/COCOMITalk
git add design-tokens.css index.html sw.js
git commit -m "feat: design-tokens.css追加 (UI/UX洗練化Phase1)"
git push origin main
```

### Step 6: 結果記録（必須）

**作業完了時、必ず以下の通り `save_code_log` MCPツールを呼ぶこと：**

```
mission_name: "M-EXEC-20260408-1700-design-tokens-css"
project: "COCOMITalk"   ← cocomi-postmanではなくCOCOMITalkを指定（実際の作業対象リポ）
status: "success"  ← 成功時。失敗したら "error"
output: 実際にやった内容を200文字以内で
        （例: COCOMITalkに design-tokens.css 70行を新規作成。index.html v1.8 と sw.js v3.59 にも追記。push成功）
analysis: 他リポ操作パターンの所感を150文字以内で
          （例: 他リポへのclone+pull+commit+push の流れで問題なし。デュアルソース方式で他リポも操作可能と確認）
```

## ✅ 成功条件

1. ✅ `COCOMITalk/design-tokens.css` が新規作成されている（70行、:root内変数定義）
2. ✅ `COCOMITalk/index.html` の26行目付近に `design-tokens.css` のlink要素がある
3. ✅ `COCOMITalk/index.html` の2行目コメントが v1.8 に更新されている
4. ✅ `COCOMITalk/sw.js` の CACHE_NAME が `cocomitalk-v3.59` になっている
5. ✅ `COCOMITalk/sw.js` のキャッシュリストに `'./design-tokens.css'` が追加されている
6. ✅ COCOMITalkリポへの commit & push が成功している
7. ✅ `save_code_log` で D1 にログ保存されている（project="COCOMITalk"）

## ⚠️ 注意事項

### やってはいけないこと
- ❌ `styles.css` の `:root` を削除・変更しない（二重定義のままでOK）
- ❌ 他のCSSファイル（meeting-styles.css等）は一切触らない
- ❌ 既存変数名のリネームはしない
- ❌ 色の値を変更しない

### 既知の懸念
- **二重定義について**: design-tokens.cssとstyles.cssの両方に`:root`が存在することになる。CSS的には後に読まれた方（styles.css）が勝つが、値が同じなので挙動に影響なし。次フェーズでstyles.cssの`:root`を削除する予定。
- **他リポ操作パターン**: 今回がこのパターンの初回実行。Postmanのprootバインドマウントが他リポにも対応しているか確認が必要。

### CI通過条件
- ShellCheck: bashコマンド使用箇所はシンプルに保つ
- 500行ルール: design-tokens.css 70行、index.html/sw.jsは追記のみで増加微小
- 先頭コメント: design-tokens.css に v1.0 のヘッダコメント有り
- バージョン番号: index.html v1.8、sw.js CACHE v3.59 に更新済み
- セキュリティ: 新規ファイルは静的CSSのみ、JSロジック追加なし

## 📝 補足

- このタスクはCOCOMITalkリポのUI/UX洗練化「お着替えシステム構想」の第一歩
- 視覚的な変化はゼロ（既存色を維持しているため）
- 「素人感」の正体である「直書き約300箇所」を解決する基盤づくり
- 関連カプセル: `cocomi-capsules/ideas/2026-04-08_cocomitalk-uiux-and-dressup-system.md`

---
作成: WEBクロちゃん 2026-04-08 17:00頃
バージョン: P-EXEC v1.0（実運用テスト #1・他リポ操作パターン初回）
