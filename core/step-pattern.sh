#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2004
# このファイルは: COCOMI Postman ステップパターン実行エンジン
# アキヤ発案: 「これでダメだったらこっちのパターン試して」を実現する条件分岐型指示書
# on-fail: next/stop/step-N — 失敗時の遷移先
# on-success: next/step-N — 成功時の遷移先（フォールバックステップのスキップに使う）
# type: execute/search/meeting — ステップの種類（Claude Code実行/Brave Search/三姉妹会議）
# v1.0 新規作成 2026-03-27 - step-runner.sh v3.0から分離
# v1.0.1 修正 2026-04-07 - ShellCheck SC2004対応（配列添字の${}スタイル警告抑制）
# 呼び出し元: executor.sh（has_step_pattern()がtrueの場合）
# 依存: step-runner.sh（parse_steps, wait_for_ci等）, escalation.sh（search/meeting）, retry.sh
