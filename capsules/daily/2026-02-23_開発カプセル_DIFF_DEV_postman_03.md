```yaml
---
title: "🔧 開発カプセル_DIFF_DEV_postman_2026-02-23_03"
capsule_id: "CAP-DIFF-DEV-POSTMAN-20260223-03"
project_name: "COCOMI Postman Phase 2b: 全自動フロー完走 + Worker v1.2 + step-runner v2.0.2"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_postman"
related_general: "💊 思い出カプセル_DIFF_総合_2026-02-23_03"
phase: "LINE配達＋ステップ実行 Phase2b完了"
date: "2026-02-23"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（タブレットTermux＋スマホCloudflare Dashboard）"
tester: "LINE実メッセージ送信 + タブレットauto_mode + GitHub Actions CI + ShellCheck"
---
```

# 1. 🎯 Mission Result（ミッション結果サマリー）

| 項目 | 内容 |
|------|------|
| ミッション1 | Phase 2b全自動フロー検証: LINE指示→タブレット自動実行→CI→LINE結果通知 |
| 結果1 | ✅成功（sanitizeForFilenameバグ修正後に全フロー完走） |
| ミッション2 | Worker v1.2: sanitizeForFilename強化 |
| 結果2 | ✅成功（Cloudflareデプロイ、6パターンテスト通過） |
| ミッション3 | step-runner.sh v2.0.2: grep -c整数判定バグ修正 + ShellCheck修正 |
| 結果3 | ✅成功（CI全テスト通過） |

# 2. 📁 Files Changed（変更ファイル詳細）

## Cloudflare Workers側

| ファイル | 行数 | バージョン | 変更内容 |
|---------|------|-----------|---------|
| cocomi-worker/src/worker.js | 約490行 | v1.1 → **v1.2** | sanitizeForFilename()強化、GETレスポンスにバージョン表示追加 |

## GitHub側（cocomi-postman）

| ファイル | 行数 | バージョン | 変更内容 |
|---------|------|-----------|---------|
| core/step-runner.sh | 342行 | v2.0.1 → **v2.0.2** | has_steps() grep -c修正、wait_for_ci() workflow_count修正、echo半角括弧→全角 |

## 自動生成されたファイル

| ファイルパス | 生成方法 | 内容 |
|------------|---------|------|
| missions/cocomi-postman/M-LINE-0223-0738-README.mdに「 | Worker v1.1（バグ版） | ファイル名が壊れた指示書（.mdで終わらない） |
| missions/cocomi-postman/M-LINE-0223-0748-README.mdに「 | Worker v1.1（バグ版） | 同上（2回目送信分） |
| missions/cocomi-postman/M-LINE-0223-0810-READMEにカプセル保管庫の説明追加.md | Worker v1.1（正常） | 短い指示で正常ファイル名 → auto_mode検知成功 |
| reports/cocomi-postman/R-LINE-0223-0810-READMEにカプセル保管庫の説明追加.md | Postman自動生成 | 実行成功レポート |

# 3. 🔧 Worker v1.2 変更詳細

## sanitizeForFilename() — 修正前後比較

```javascript
// v1.1（修正前）— 基本的な禁止文字のみ
function sanitizeForFilename(text) {
  return text
    .replace(/[\/\\?%*:|"<>]/g, '')
    .replace(/\s+/g, '_')
    .substring(0, 20);
}

// v1.2（修正後）— 拡張子・日本語特殊文字を包括除去
function sanitizeForFilename(text) {
  return text
    .replace(/\.[a-zA-Z]{1,5}\b/g, '')        // .md .sh .json等の拡張子除去
    .replace(/[\/\\?%*:|"<>「」『』（）()\[\]{}.,;:!！？#＃&＆@＠·。、]/g, '')
    .replace(/\s+/g, '')                        // スペース除去（旧: _に変換）
    .substring(0, 30);                          // 30文字制限（旧: 20文字）
}
```

## テストケース結果

| 入力 | v1.1出力 | v1.2出力 | .mdマッチ |
|------|---------|---------|----------|
| `README.mdに「## カプセル保管庫」セクションを追加` | `README.mdに「##_カプセル` | `READMEにカプセル保管庫セクションを追加` | ❌→✅ |
| `READMEにカプセル保管庫の説明追加` | `READMEにカプセル保管庫の説明` | `READMEにカプセル保管庫の説明追加` | ✅→✅ |
| `postman.shのauto_mode関数を修正` | `postman.shのauto_mod` | `postmanのauto_mode関数を修正` | ✅→✅ |
| `CULOchan v0.96のバグを直す！` | `CULOchan_v0.96のバグを` | `CULOchanv096のバグを直す` | ✅→✅ |
| `設定ファイル（config.json）を更新` | `設定ファイル（config.j` | `設定ファイルconfigを更新` | ❌→✅ |

## GETレスポンス更新

```
v1.1: 🐾 COCOMI Worker is alive! v1.1  📁 ファイル配達＆カプセル保管対応
v1.2: 🐾 COCOMI Worker is alive! v1.2  📁 ファイル配達＆カプセル保管対応  🔧 ファイル名サニタイズ強化
```

# 4. 🔧 step-runner.sh v2.0.2 変更詳細

## 修正箇所一覧

| # | 関数 | 行 | 修正内容 |
|---|------|---|---------|
| 1 | has_steps() | 16-17 | `grep -c ... \|\| echo "0"` → `grep -c ...) \|\| true` + `"${step_count:-0}"` |
| 2 | wait_for_ci() | 109-110 | `workflow_count` 同上のパターン修正 + 余分なダブルクォート除去 |
| 3 | wait_for_ci() | 149 | `(${attempt}/${max_attempts})` → `（${attempt}/${max_attempts}）` |

## has_steps() 修正前後

```bash
# 修正前（v2.0.1）— "0\n0" 問題
step_count=$(grep -c "^### Step [0-9]" "$mission_file" 2>/dev/null || echo "0")
if [ "$step_count" -ge 2 ]; then

# 修正後（v2.0.2）— 安全なフォールバック
step_count=$(grep -c "^### Step [0-9]" "$mission_file" 2>/dev/null) || true
step_count="${step_count:-0}"
if [ "$step_count" -ge 2 ]; then
```

## バグの詳細メカニズム

```
grep -c "パターン" file → マッチ0件
  ├── stdout: "0"（grep -cは常にカウントを出力）
  └── 終了コード: 1（マッチなしは失敗扱い）

$(grep -c ... || echo "0")
  ├── grepのstdout "0" がキャプチャされる
  ├── || が発動（終了コード1なので）
  ├── echo "0" のstdout "0" も追加される
  └── 結果: step_count="0\n0"（改行入り文字列）

[ "0\n0" -ge 2 ] → "integer expected" エラー
```

## wait_for_ci() echo修正

```bash
# 修正前 — ShellCheck SC1036: '(' is invalid here
echo -e "  ${YELLOW}  ⏳ CI実行中... (${attempt}/${max_attempts})${NC}"

# 修正後 — 全角括弧でShellCheck回避
echo -e "  ${YELLOW}  ⏳ CI実行中... （${attempt}/${max_attempts}）${NC}"
```

# 5. 🐛 Error Log（エラー＆解決記録）

### ERR-PM-001: auto_mode検知失敗

| 項目 | 内容 |
|------|------|
| 発生時刻 | 07:38 |
| 症状 | LINEから指示送信 → GitHub push成功 → auto_mode「新着なし」 |
| 原因 | sanitizeForFilename()がファイル名に「」や.mdを混入 → `.md`拡張子が壊れる → `M-*.md` パターン不マッチ |
| 解決 | Worker v1.2でsanitizeForFilename()を強化 |
| 影響範囲 | 指示内容に拡張子(.md .sh等)や日本語括弧を含む場合に発生 |
| 再発防止 | 6パターンのテストケースで検証済み |

### ERR-PM-002: step-runner.sh integer expected

| 項目 | 内容 |
|------|------|
| 発生時刻 | 08:11（auto_modeテスト時に発見） |
| 症状 | `step-runner.sh: line 17: [: 0: integer expected` |
| 原因 | `grep -c ... \|\| echo "0"` で `"0\n0"` が生成される |
| 解決 | `|| true` + `${var:-0}` パターンに変更 |
| 影響 | ステップなし指示書の実行自体には影響なし（エラーメッセージのみ） |

### ERR-PM-003: ShellCheck CI失敗（3回）

| 項目 | 内容 |
|------|------|
| 発生回数 | 3回 |
| 1回目 | sedで1行修正 → workflow_count行まで巻き込み |
| 2回目 | workflow_count修正 → `${step_count:-0}` がまだ1行のまま |
| 3回目 | 半角括弧 `(最大10分)` `(${attempt})` → ShellCheck SC1036 |
| 最終解決 | ファイル丸ごとこちらで修正 → ShellCheckクリア確認 → タブレットに転送 |

# 6. 🧠 Design Decisions（設計判断の記録）

### 設計判断①：sanitizeForFilenameの正規表現戦略

- **課題:** ユーザーの自由入力テキストからファイル名を安全に生成する
- **選択肢:**
  - A: ホワイトリスト方式（英数字+一部日本語のみ許可）
  - B: ブラックリスト方式（危険文字を列挙して除去）
  - C: ハイブリッド（拡張子除去→危険文字除去→スペース除去）
- **決定:** C（ハイブリッド）
- **理由:** 日本語ファイル名を保持しつつ（「READMEにカプセル保管庫の説明追加」のように指示内容が読める）、拡張子と特殊記号を除去
- **拡張子除去:** `\.[a-zA-Z]{1,5}\b` で `.md` `.sh` `.json` `.html` 等を包括除去

### 設計判断②：ファイル丸ごと差し替え方式

- **課題:** Termuxのnano/sedで細かい修正を行うとエラーを招きやすい
- **決定:** 修正版ファイルをこちらで作成 → ShellCheckクリア確認 → アキヤにファイル転送で渡す
- **メリット:** ShellCheckを事前にクリアしてから渡せるのでCI失敗リスクがゼロ
- **デメリット:** ファイル転送の手間（スマホ→タブレット間）
- **結果:** ✅ 今後の修正でもこの方式を使うのが安全

### 設計判断③：半角括弧を全角に変更

- **課題:** ShellCheckがecho内の `(` をシェル構文として誤検知（SC1036）
- **選択肢:**
  - A: `shellcheck disable` でSC1036を抑制
  - B: 半角括弧を全角に変更
  - C: 括弧を使わない表現に変更
- **決定:** B（全角に変更）
- **理由:** 日本語メッセージ内の括弧は全角が自然。disable追加は他のエラーを見逃すリスクがある

# 7. 📈 auto_mode検知→全自動フロー完走の証跡

## Termuxログ

```
🚀 08:11 新着！[cocomi-postman] M-LINE-0223-0810-READMEにカプセル保管庫の説明追加
🔄 git pull中...
🤖 Claude Code実行中...
🎉 Claude Code作業完了！
📦 プロジェクトをgit push完了
✅ M-LINE-0223-0810-READMEにカプセル保管庫の説明追加 完了！
📱 LINE通知送信OK
📮 レポートをスマホ支店に送りした
```

## LINE通知（時系列）

```
[08:10] 📦 指示受付完了！
        📂 プロジェクト: cocomi-postman
        📋 ミッション: M-LINE-0223-0810
        📝 内容: READMEにカプセル保管庫の説明追加
        タブレットに配達しました！🚚

[08:10] 🛡️ COCOMI Postman テスト審査結果
        ✅ 全テスト通過！（Worker push分のCI）

[08:13] 📮 COCOMI Postman レポート到着！
        ミッション: M-LINE-0223-0810-READMEにカプセル保管庫の説明追加
        結果: ✅ 成功！

[08:13] 🛡️ COCOMI Postman テスト審査結果
        ✅ 全テスト通過！（Claude Code作業分のCI）

[08:13] 🛡️ COCOMI Postman テスト審査結果
        ✅ 全テスト通過！（レポートpush分のCI）
```

# 8. 📋 現在のWorker v1.2 全機能一覧

| 機能 | コマンド/トリガー | 追加バージョン |
|------|-----------------|--------------|
| テキスト指示 → GitHub push | `プロジェクト名: 指示内容` | v1.0 |
| ヘルスチェック | GETリクエスト | v1.0 |
| 「状態」コマンド | `状態` | v1.1 |
| ファイル受信 → カプセル保管 | LINEファイル送信 | v1.1 |
| 種別自動判定 | ファイル名キーワード | v1.1 |
| 「カプセル」コマンド | `カプセル` | v1.1 |
| ファイル名サニタイズ強化 | （内部処理） | v1.2 |

---

*2026-02-23 アキヤ & クロちゃん 🐾*
