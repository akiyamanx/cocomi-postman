#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2162,SC2012
# このファイルは: COCOMI Postman 自動モード＆ミッション実行エンジン
# postman.shから呼ばれる実行系機能
# v1.1 修正 2026-02-18 - git pushをClaude Code外で実行する設計に変更
# v1.2 修正 2026-02-19 - auto_modeのプロジェクトループをconfig.json動的化
# v1.3 追加 2026-02-19 - LINE通知呼び出し追加
# v1.4 修正 2026-02-19 - ShellCheck対応
# v1.5 修正 2026-02-20 - Phase C: リトライ機構統合（retry.sh連携）
# v1.6 修正 2026-02-21 - git push競合対策（pull --rebase+リトライ追加）
# v2.0 追加 2026-02-22 - ステップ実行判定分岐（step-runner.sh連携）
# v2.1 追加 2026-02-25 - 安全バリデーション（missionタグ検証）＆auto_modeメニュー復帰キー
# v2.2 修正 2026-02-27 - git_push_projectに変更なし戻り値追加（CI待ちスキップ対応）
# v2.3 追加 2026-03-27 - ステップパターン指示書判定（has_step_pattern→step-pattern.sh連携）
# /tmp権限問題の回避: git操作は全てPostman（Termux直接）が行う
