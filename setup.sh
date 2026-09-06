#!/bin/bash
# Prove2Me作業用 実セットアップ処理
# prove2me-stackscript.sh (Linode StackScript本体) から
# GitHub経由でダウンロードされて実行される。
#
# 単体でこのファイルを直接編集・テストする場合は以下のように実行できる:
#   DESTROY_TOKEN=xxx DESTROY_HOURS=6 bash setup.sh

set -e
exec > /var/log/prove2me-setup.log 2>&1
echo "=== Prove2Me setup started: $(date) ==="

export HOME=/root
cd /root

# --- 基本パッケージ ---
apt-get update
apt-get install -y curl git build-essential

# --- Node.js (LTS) ---
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# --- Claude Code ---
npm install -g @anthropic-ai/claude-code

# --- elan (Lean toolchain マネージャ) ---
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y
echo 'source $HOME/.elan/env' >> /root/.bashrc
source /root/.elan/env

# --- Prove2Meワークスペースを取得 ---
git clone https://github.com/prove2me/prove2me_workspace.git /root/prove2me_workspace
cd /root/prove2me_workspace

# --- Mathlibのバイナリキャッシュを取得(フルビルド回避) ---
/root/.elan/bin/lake exe cache get || echo "cache get failed, will build from source on first use"

echo "=== Prove2Me setup finished: $(date) ==="

# --- 自己破壊タイマー(DESTROY_TOKENが設定されている場合のみ) ---
if [ -n "${DESTROY_TOKEN:-}" ] && [ "${DESTROY_HOURS:-0}" -gt 0 ]; then
  echo "=== Scheduling self-destruct in ${DESTROY_HOURS}h ==="

  META_TOKEN=$(curl -s -X PUT -H "Metadata-Token-Expiry-Seconds: 3600" \
    http://169.254.169.254/v1/token)
  LINODE_ID=$(curl -s -H "Metadata-Token: $META_TOKEN" \
    http://169.254.169.254/v1/instance | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

  cat > /root/self-destruct.sh <<EOF
#!/bin/bash
curl -s -X DELETE \\
  -H "Authorization: Bearer ${DESTROY_TOKEN}" \\
  "https://api.linode.com/v4/linode/instances/${LINODE_ID}"
EOF
  chmod +x /root/self-destruct.sh

  systemd-run --on-active="${DESTROY_HOURS}h" --unit=prove2me-self-destruct \
    /root/self-destruct.sh
fi

echo "=== All done. Ready for: claude ==="
