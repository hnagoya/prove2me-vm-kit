#!/usr/bin/env bash
# prove2me-stackscript.sh の現在の中身を Linode 側の StackScript に反映するスクリプト
#
# 使い方: ./sync-stackscript.sh
#
# prove2me-stackscript.sh を編集したら、コミット・push したうえでこれを実行する。
# Linode 側の内容と一致している場合は update をスキップする。

set -euo pipefail

# スクリプト自身のディレクトリにある .env を自動で読み込む(手動 source 不要)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/.env"
  set +a
fi

if [ -z "${STACKSCRIPT_ID:-}" ]; then
  echo "エラー: STACKSCRIPT_ID が設定されていません。"
  echo "  cp .env.example .env  して値を埋めてから再実行してください($SCRIPT_DIR/.env は自動で読み込まれます)。"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "エラー: jq が見つかりません。差分チェックに必要です。"
  echo "  次のコマンドでインストールしてください: sudo apt-get install -y jq"
  exit 1
fi

STACKSCRIPT_FILE="$SCRIPT_DIR/prove2me-stackscript.sh"
if [ ! -f "$STACKSCRIPT_FILE" ]; then
  echo "エラー: $STACKSCRIPT_FILE が見つかりません。"
  exit 1
fi

# Linode 側の現在のスクリプト内容を取得する(--json は配列で返るので .[0].script)
REMOTE_SCRIPT="$(linode-cli stackscripts view "$STACKSCRIPT_ID" --json | jq -r '.[0].script')"
LOCAL_SCRIPT="$(cat "$STACKSCRIPT_FILE")"

if [ "$REMOTE_SCRIPT" = "$LOCAL_SCRIPT" ]; then
  echo "変更なし、更新をスキップしました(StackScript ID $STACKSCRIPT_ID)。"
  exit 0
fi

echo "=== StackScript ID $STACKSCRIPT_ID に prove2me-stackscript.sh を反映中 ==="

# --script にファイル名を直接渡す方式は反映されない不具合が報告されているため、
# cat で中身を展開して渡す。
linode-cli stackscripts update "$STACKSCRIPT_ID" --script "$LOCAL_SCRIPT"

echo "更新しました。"
