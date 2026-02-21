# 📮 COCOMI Postman ミッション指示書
# M-STEP-002: step-runner.sh ShellCheck SC2086修正

**ミッションタイプ:** bug-fix
**対象プロジェクト:** cocomi-postman
**作成日:** 2026-02-22
**作成者:** アキヤ & クロちゃん（Claude Opus 4.6）

---

## 📋 ミッション概要

core/step-runner.sh の ShellCheck SC2086エラーを修正する。
算術展開 `$((..))` にダブルクォートが不足している箇所を全て修正する。

## 📁 対象ファイル

- `core/step-runner.sh` — ShellCheck SC2086修正

## 🔧 修正内容

core/step-runner.sh 内で `$((..))` が裸で使われている箇所を全て探して、
ダブルクォートで囲んでください。

例：
```bash
# 修正前
if [ "$i" -lt $((total_steps - 1)) ]; then

# 修正後
if [ "$i" -lt "$((total_steps - 1))" ]; then
```

同様のパターンが他にもあれば全て修正してください。

修正後、以下のコマンドでエラーが出ないことを確認：
```bash
shellcheck -e SC1091,SC2034 core/step-runner.sh
```

## ✅ 完了条件

1. `shellcheck -e SC1091,SC2034 core/step-runner.sh` がエラーなしで通ること
2. 既存の機能が壊れていないこと
3. git commit: "🐛 v2.0.1 fix: step-runner.sh ShellCheck SC2086修正"
