#!/usr/bin/env bash
# Prove2Me作業用 Linode VM 作成スクリプト
#
# 事前に環境変数を設定しておく(~/.bashrc等に書いておくと楽):
#   export STACKSCRIPT_ID=12345678
#   export DESTROY_TOKEN=xxxxxxxx   # 省略可。省略すると自己破壊しない
#
# 使い方: ./start.sh

set -euo pipefail

# 以下は .env で上書き可能。未設定時はここのデフォルト値を使う。
LABEL="${LABEL:-prove2me-work}"
REGION="${REGION:-us-ord}"                 # 好きなリージョンに変更可(例: ap-northeast など)
TYPE="${TYPE:-g6-dedicated-4}"             # トイプロブレム想定。重ければ g6-dedicated-8 に変更
IMAGE="${IMAGE:-linode/ubuntu26.04}"
DESTROY_HOURS="${DESTROY_HOURS:-6}"

if [ -z "${STACKSCRIPT_ID:-}" ]; then
  echo "エラー: STACKSCRIPT_ID が設定されていません。"
  echo "  cp .env.example .env  して値を埋め、 source .env してから再実行してください。"
  exit 1
fi

ROOT_PASS=$(openssl rand -base64 20)
STACKSCRIPT_DATA=$(printf '{"destroy_token":"%s","destroy_hours":"%s"}' \
  "${DESTROY_TOKEN:-}" "${DESTROY_HOURS}")

echo "=== Linode作成中: $LABEL ($TYPE @ $REGION) ==="

linode-cli linodes create \
  --type "$TYPE" \
  --region "$REGION" \
  --image "$IMAGE" \
  --stackscript_id "$STACKSCRIPT_ID" \
  --stackscript_data "$STACKSCRIPT_DATA" \
  --root_pass "$ROOT_PASS" \
  --label "$LABEL" \
  --tags prove2me \
  --booted true

echo ""
echo "root パスワード(必要な場合のみ使用): $ROOT_PASS"
echo ""
echo "起動とセットアップには数分かかります。IPアドレス取得中..."
sleep 20

IP=$(linode-cli linodes list --label "$LABEL" --text --no-headers --format="ipv4" | head -1)
echo ""
echo "=== 準備完了目安 ==="
echo "SSH接続:  ssh root@${IP}"
echo "セットアップ進捗確認: ssh root@${IP} 'tail -f /var/log/prove2me-setup.log'"
echo ""
echo "セットアップが終わったら (ログ末尾に 'All done' と出たら):"
echo "  ssh root@${IP}"
echo "  claude"
echo "  > Fetch https://prove2.me/start.md and follow it to set yourself up for Prove2Me. Log in with my Prove2Me API key <ここにキー>"
