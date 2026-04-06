#!/bin/bash
# shellcheck disable=SC2001
# このファイルは: COCOMI Postman プロジェクト管理機能
# postman.shのメニュー8から呼ばれるプロジェクト管理モジュール
# v1.0 新規作成 2026-02-26 - 一覧表示/追加/削除/デフォルト変更/編集
# v1.0.1 修正 2026-04-07 - ShellCheck SC2001対応（sed置換スタイル警告抑制）
# config.jsonの読み書きはcore/config-helper.py（Python）で安全に処理