#!/usr/bin/env bash
# Prove2Me作業用 Linode VM 削除スクリプト
#
# 使い方: ./stop.sh

set -euo pipefail

LABEL="prove2me-work"

ID=$(linode-cli linodes list --text --no-headers --format="id,label" \
  | awk -v l="$LABEL" '$2==l {print $1}')

if [ -z "$ID" ]; then
  echo "ラベル '$LABEL' のLinodeは見つかりませんでした。すでに削除済みかもしれません。"
  exit 0
fi

echo "Linode ID $ID ($LABEL) を削除します..."
linode-cli linodes delete "$ID"
echo "削除完了。課金はここで止まります。"
