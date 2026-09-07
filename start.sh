#!/usr/bin/env bash
# Prove2Me作業用 Linode VM 作成スクリプト
#
# 事前に環境変数を設定しておく(~/.bashrc等に書いておくと楽):
#   export STACKSCRIPT_ID=12345678
#   export DESTROY_TOKEN=xxxxxxxx   # 省略可。省略すると自己破壊しない
#
# 使い方: ./start.sh

set -euo pipefail

# スクリプト自身のディレクトリにある .env を自動で読み込む(手動 source 不要)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/.env"
  set +a
fi

# 以下は .env で上書き可能。未設定時はここのデフォルト値を使う。
LABEL="${LABEL:-prove2me-work}"
REGION="${REGION:-jp-tyo-3}"               # 好きなリージョンに変更可(linode-cli regions list で一覧)
TYPE="${TYPE:-g6-dedicated-4}"             # トイプロブレム想定。重ければ g6-dedicated-8 に変更
IMAGE="${IMAGE:-linode/ubuntu26.04}"
DESTROY_HOURS="${DESTROY_HOURS:-6}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/prove2me_key}"
SSH_PUBKEY_PATH="${SSH_KEY_PATH}.pub"

if [ -z "${STACKSCRIPT_ID:-}" ]; then
  echo "エラー: STACKSCRIPT_ID が設定されていません。"
  echo "  cp .env.example .env  して値を埋めてから再実行してください($SCRIPT_DIR/.env は自動で読み込まれます)。"
  exit 1
fi

if [ ! -f "$SSH_PUBKEY_PATH" ]; then
  echo "エラー: SSH公開鍵が見つかりません: $SSH_PUBKEY_PATH"
  echo "  次のコマンドで鍵ペアを作成してください:"
  echo "    ssh-keygen -t ed25519 -f \"$SSH_KEY_PATH\" -C prove2me"
  exit 1
fi

# root_pass はAPI必須パラメータなので生成するが、認証はSSH鍵で行うため通常使わない。
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
  --authorized_keys "$(cat "$SSH_PUBKEY_PATH")" \
  --label "$LABEL" \
  --tags prove2me \
  --booted true

SSH_OPTS=(-i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no)

echo ""
echo "root パスワード: $ROOT_PASS"
echo "  (SSH鍵認証を設定済みなので通常このパスワードは使いません。コンソールログイン用の控えです)"
echo ""
echo "起動とセットアップには数分かかります。IPアドレス取得中..."
sleep 20

IP=$(linode-cli linodes list --label "$LABEL" --text --no-headers --format="ipv4" | head -1)
echo ""
echo "=== 準備完了目安 ==="
echo "SSH接続:  ssh ${SSH_OPTS[*]} root@${IP}"
echo "セットアップ進捗確認: ssh ${SSH_OPTS[*]} root@${IP} 'tail -f /var/log/prove2me-setup.log'"
echo ""
echo "セットアップが終わったら (ログ末尾に 'All done' と出たら):"
echo "  ssh ${SSH_OPTS[*]} root@${IP}"
echo "  claude"
echo "  > Fetch https://prove2.me/start.md and follow it to set yourself up for Prove2Me. Log in with my Prove2Me API key <ここにキー>"
