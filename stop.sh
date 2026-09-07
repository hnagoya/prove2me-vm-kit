#!/usr/bin/env bash
# Prove2Me作業用 Linode VM 削除スクリプト
#
# 使い方: ./stop.sh

set -euo pipefail

# スクリプト自身のディレクトリにある .env を自動で読み込む(手動 source 不要)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/.env"
  set +a
fi

LABEL="${LABEL:-prove2me-work}"

ID=$(linode-cli linodes list --text --no-headers --format="id,label" \
  | awk -v l="$LABEL" '$2==l {print $1}')

if [ -z "$ID" ]; then
  echo "ラベル '$LABEL' のLinodeは見つかりませんでした。すでに削除済みかもしれません。"
  exit 0
fi

echo "Linode ID $ID ($LABEL) を削除します..."
linode-cli linodes delete "$ID"
echo "削除完了。課金はここで止まります。"
