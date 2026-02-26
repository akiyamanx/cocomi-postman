```yaml
---
title: "🔧 開発カプセル_DIFF_DEV_postman-safety_2026-02-25_01"
capsule_id: "CAP-DIFF-DEV-POSTMAN-SAFETY-20260225-01"
project_name: "COCOMI Postman Safety Upgrade: 誤認識暴走チェーン防止 + Worker v2.0 + executor v2.1"
capsule_type: "diff_dev"
related_master: "🔧 開発カプセル_MASTER_DEV_postman"
related_general: "💊 思い出カプセル_DIFF_総合_2026-02-25_01"
phase: "安全バリデーション二重防御 + auto_modeメニュー復帰"
date: "2026-02-25"
designer: "クロちゃん (Claude Opus 4.6)"
executor: "アキヤ（タブレットTermux＋スマホCloudflare Dashboard）"
tester: "LINE実メッセージ送信3パターン（状態/プロジェクト名なし/正常系）"
---
```

# 1. 🎯 Mission Result（ミッション結果サマリー）

| 項目 | 内容 |
|------|------|
| ミッション1 | 誤認識暴走チェーン防止 — Worker側バリデーション（入口を塞ぐ） |
| 結果1 | ✅成功 Worker v2.0デプロイ＆テスト通過 |
| ミッション2 | 誤認識暴走チェーン防止 — タブレット側バリデーション（最後の砦） |
| 結果2 | ✅成功 executor v2.1 git push＆CI全通過 |
| ミッション3 | auto_modeメニュー復帰キー（sleep→read -t変更） |
| 結果3 | ✅成功 mキーでメニュー復帰確認済み |
| ミッション4 | CULOchan v0.97 サジェストドロップダウン選択時品名上書きバグ修正 |
| 結果4 | ✅成功 onchange→onblur+250ms遅延で解決、commit 7c9c1b6 |

# 2. 🔴 解決した致命的問題：誤認識暴走チェーン

## 問題の全体像

```
LINEでtypo（例: 「テストだよ」）
  ↓ Worker v1.6: プロジェクト名なし → デフォルトgenba-proに配達 ❌
  ↓ missions/genba-pro/M-LINE-XXXX-テストだよ.md が生成される
  ↓ GitHub push
  ↓ タブレット auto_mode: git pull → M-*.md検知 → 「新着！」
  ↓ Claude Code実行 → 「テストだよ」を指示として解釈 → 意味不明な変更
  ↓ git push → CI → さらにpush...
  ↓ 被害が連鎖的に拡大 💥💥💥
```

## 二重防御の設計

| 防御層 | ファイル | バリデーション | 不合格時の処理 |
|--------|---------|---------------|---------------|
| 🛡️ 第1の壁（入口） | worker.js v2.0 | テキスト指示に `プロジェクト名:` 必須 | inbox/unvalidated/ に退避＆書き方ガイド返信 |
| 🛡️ 第2の壁（最後の砦） | executor.sh v2.1 | 指示書に `<!-- mission: project-id -->` 必須 | 実行拒否＆LINE通知＆inbox/rejected/ に退避 |

# 3. 📁 Files Changed（変更ファイル詳細）

## Cloudflare Workers側

| ファイル | 行数 | バージョン | 変更内容 |
|---------|------|-----------|---------|
| worker.js | 790行 | v1.6 → **v2.0** | parseInstruction()バリデーション強化、createMissionContent()にmissionタグ自動注入、handleFileMessage()にmissionタグ警告追加、無効テキスト→inbox/unvalidated/退避 |

## タブレット側（cocomi-postman）

| ファイル | 行数 | バージョン | 変更内容 |
|---------|------|-----------|---------|
| core/executor.sh | 371行 | v2.0 → **v2.1** | validate_mission()新規追加、handle_invalid_mission()新規追加、run_single_mission()にバリデーション統合、auto_mode sleep→read -t変更 |

## CULOchanKAIKEIpro側（前半セッション）

| ファイル | 行数 | バージョン | 変更内容 |
|---------|------|-----------|---------|
| globals.js | - | v0.96 → **v0.97** | _suggestJustSelected フラグ追加 |
| estimate.js | - | v0.96 → **v0.97** | onchange→onblur + 250ms setTimeout遅延 |
| invoice.js | - | v0.96 → **v0.97** | 同上 |

# 4. 🔧 Worker v2.0 変更詳細

## parseInstruction() — バリデーション強化

```javascript
// v1.6（修正前）— プロジェクト名なし → デフォルトに飛ばす（危険！）
function parseInstruction(text) {
  const match = text.match(/^([^:：]+)[：:](.+)$/s);
  if (match) {
    const projectCandidate = match[1].trim().toLowerCase();
    if (VALID_PROJECTS.includes(projectCandidate)) {
      return { project: projectCandidate, instruction: match[2].trim() };
    }
  }
  return { project: DEFAULT_PROJECT, instruction: text.trim() };
  //                ^^^^^^^^^^^^^^^ ここが危険だった
}

// v2.0（修正後）— プロジェクト名なし → null（無効扱い）
function parseInstruction(text) {
  // ...同上...
  return { project: null, instruction: text.trim(), valid: false };
  //       ^^^^ null返し → メインハンドラでinbox退避
}
```

## createMissionContent() — missionタグ自動注入

```javascript
// v2.0追加: 先頭行に <!-- mission: project-id --> を自動注入
function createMissionContent(missionId, project, instruction) {
  return `<!-- mission: ${project} -->
# ${missionId}: ${instruction.substring(0, 50)}
## プロジェクト: ${project}
...`;
}
```

## 無効テキスト受信時のフロー

```
「テストだよ」→ parseInstruction() → valid: false
  → inbox/unvalidated/M-LINE-XXXX-テストだよ.md に退避
  → LINE返信: 「📥 テキストをinboxに保管しました。指示として実行するには
    プロジェクト名を付けて送ってね：genba-pro: やりたいこと」
  → missions/ には一切入らない ✅
```

# 5. 🔧 executor.sh v2.1 変更詳細

## validate_mission() — 新規関数

```bash
validate_mission() {
    local mission_file="$1"
    # 先頭10行から <!-- mission: xxx --> を抽出
    local mission_tag
    mission_tag=$(head -10 "$mission_file" | sed -n \
      's/.*<!--[[:space:]]*mission:[[:space:]]*\([^[:space:]]*\)[[:space:]]*-->.*/\1/p' \
      | head -1)
    if [ -z "$mission_tag" ]; then
        echo "INVALID"; return 1
    fi
    # config.jsonに登録されたプロジェクトか確認
    if ! get_project_ids | grep -q "^${mission_tag}$"; then
        echo "UNKNOWN:${mission_tag}"; return 1
    fi
    echo "$mission_tag"; return 0
}
```

## handle_invalid_mission() — 拒否＆通知＆退避

- LINE通知で「⚠️ 無効な指示書を検出しました」送信
- ファイルを `inbox/rejected/` にコピー（証拠保全）
- 実行は完全にスキップ

## auto_mode メニュー復帰キー

```bash
# 修正前: Ctrl+C以外に止める方法がなかった
sleep "$INTERVAL"

# 修正後: 待機中にキー入力を受け付ける
echo -e "  💤 次のチェックまで待機中...（m:メニュー / q:終了）"
read -t "$INTERVAL" -n 1 input
case "$input" in
    m|M) termux-wake-unlock; return ;;  # メニューに戻る
    q|Q) termux-wake-unlock; exit 0 ;;  # 終了
esac
```

# 6. 🐛 CULOchan v0.97 バグ修正詳細

## サジェストドロップダウン選択時の品名上書きバグ

| 項目 | 内容 |
|------|------|
| 症状 | 「エルボ 13mm」を候補から選択 → 品名欄が「エルボ」だけになる（サイズ消失） |
| 根本原因 | onchangeがonclickより先に発火 → 候補選択前のinput値で上書き |
| 修正方法 | onchange→onblur + 250ms setTimeout遅延 + _suggestJustSelected フラグ |
| テスト | 1回目から正常動作 ✅ |
| コミット | 7c9c1b6 |

# 7. 🧪 テスト結果（LINE実メッセージ3パターン）

| # | テスト内容 | LINE送信テキスト | 期待結果 | 実結果 |
|---|----------|----------------|---------|--------|
| 1 | 状態確認 | `状態` | Worker v2.0表示 | ✅ v2.0＆安全バリデーション説明表示 |
| 2 | 安全弁テスト | `テストだよ` | inbox退避＆ガイド返信 | ✅ inbox/unvalidated/に退避＆書き方ガイド |
| 3 | 正常系テスト | `cocomi-postman: テスト指示です何もしないでOK` | missions/配達＆missionタグ付与 | ✅ missionタグ✅自動付与済み＆CI全通過 |
| 4 | メニュー復帰 | タブレットauto_mode中に`m`キー | メニューに戻る | ✅ 正常にメニュー復帰 |

# 8. 🧠 Design Decisions（設計判断の記録）

### 設計判断①：二重防御（Defense in Depth）

- **課題:** typoや誤送信が連鎖的に被害を拡大する「暴走チェーン」
- **選択肢:**
  - A: Worker側だけでバリデーション（シンプルだが単一障害点）
  - B: タブレット側だけでバリデーション（Worker突破されたら無防備）
  - C: 両方でバリデーション（二重防御）
- **決定:** C（二重防御）
- **理由:** セキュリティの原則「Defense in Depth」。Worker更新中やバグ時でもタブレット側が最後の砦になる

### 設計判断②：missionタグの形式

- **形式:** `<!-- mission: project-id -->`（HTMLコメント）
- **理由:** Markdownの表示に影響しない、既存のdestタグと同じパターンで統一感がある、grep/sedで簡単に抽出可能

### 設計判断③：無効テキストの扱い

- **選択肢:**
  - A: 完全に無視（何も保存しない）
  - B: inbox/unvalidated/に退避（証拠保全）
- **決定:** B（inbox退避）
- **理由:** アキヤが後から「あの時何送ったっけ？」と確認できる。完全消去よりユーザーフレンドリー

### 設計判断④：タブレット側からデプロイ

- **順序:** executor v2.1（タブレット）→ worker v2.0（Cloudflare）
- **理由:** 最後の砦を先に構築。Worker更新中に万が一何か飛んできてもタブレットが弾く

### 設計判断⑤：cpが効かない問題 → cat > で解決

- **問題:** `cp /sdcard/Download/executor_v2_1.sh core/executor.sh` が見た目成功するがファイル内容が変わらない
- **原因:** Termuxの/sdcardアクセス権限の特殊性（SAF経由のコピー制限）
- **解決:** `cat /sdcard/Download/executor_v2_1.sh > core/executor.sh`

# 9. 📈 タイムライン

| 時刻 | 成果 |
|------|------|
| 21:00 | セッション開始（CULOchan v0.97バグ修正から継続） |
| 21:14 | CULOchan v0.97 サジェストバグ修正完了＆git push |
| 21:30 | Postman安全改修の議論開始 — 3つの問題を整理 |
| 21:40 | 設計方針確定（二重防御＋メニュー復帰キー） |
| 21:48 | GitHubからPostman関連ファイル全部ダウンロード開始 |
| 22:05 | worker.js v1.6（現行）のコード確認完了 |
| 22:15 | executor v2.1 ＆ worker v2.0 コード完成 |
| 22:23 | タブレットにexecutor v2.1デプロイ（cp→cat問題あり→cat >で解決） |
| 22:33 | executor v2.1 git push＆CI全通過 |
| 22:34 | Cloudflare Dashboardにworker v2.0デプロイ |
| 22:34 | テスト①「状態」→ ✅ v2.0表示 |
| 22:35 | テスト②「テストだよ」→ ⚠️ GitHub 502（一時障害） |
| 22:37 | テスト②リトライ → ✅ inbox退避＆ガイド返信 |
| 22:35 | テスト③「cocomi-postman: テスト指示です」→ ✅ missionタグ付与＆CI通過 |
| 22:41 | テスト④ auto_mode mキーメニュー復帰 → ✅ 正常復帰 |

# 10. 📋 現在のシステムバージョン一覧

| コンポーネント | バージョン | 最終更新 |
|--------------|-----------|---------|
| Worker (worker.js) | **v2.0** | 2026-02-25 |
| Postman本店 (postman.sh) | v2.0 | 2026-02-22 |
| 実行エンジン (executor.sh) | **v2.1** | 2026-02-25 |
| ステップ実行 (step-runner.sh) | v2.1 | 2026-02-24 |
| リトライ (retry.sh) | v1.5 | 2026-02-20 |
| LINE通知 (notifier.sh) | v1.4 | 2026-02-19 |
| CI (cocomi-ci.yml) | v1.1 | 2026-02-25 |
| CULOchanKAIKEIpro | **v0.97** | 2026-02-25 |

---

*2026-02-25 アキヤ & クロちゃん 🐾*
