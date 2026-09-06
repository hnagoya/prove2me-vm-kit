#!/bin/bash
# Prove2Me作業用 StackScript(ブートストラップ版)
#
# このファイルの中身を Linode Cloud Manager の
# Compute > StackScripts > Create StackScript にそのまま貼り付けて使う。
#
# 実際のセットアップ処理は GitHub 上の setup.sh を毎回取得して実行するので、
# 中身を直すときは GitHub リポジトリ側の setup.sh を編集するだけでよい。
# (このStackScript自体を書き換える必要はない)
#
# <UDF name="destroy_token" label="自己破壊用 Linode APIトークン(空欄なら自己破壊しない)" default="" />
# <UDF name="destroy_hours" label="何時間後に自己破壊するか" default="6" />

set -e

# ↓ここを自分のGitHubユーザー名/リポジトリ名に置き換える
REPO_RAW_BASE="https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/prove2me-vm-kit/main"

curl -fsSL "${REPO_RAW_BASE}/setup.sh" -o /root/setup.sh
chmod +x /root/setup.sh

DESTROY_TOKEN="${DESTROY_TOKEN:-}" DESTROY_HOURS="${DESTROY_HOURS:-6}" /root/setup.sh
