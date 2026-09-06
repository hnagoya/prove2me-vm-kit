#!/bin/bash
# StackScript for Prove2Me work (bootstrap version)
#
# Paste the contents of this file as-is into Linode Cloud Manager's
# Compute > StackScripts > Create StackScript.
#
# The actual setup logic fetches and runs setup.sh from GitHub each time,
# so when you need to change the contents, just edit setup.sh in the
# GitHub repo. (No need to rewrite this StackScript itself.)
#
# <UDF name="destroy_token" label="Linode API token for self-destruct (leave blank to disable)" default="" />
# <UDF name="destroy_hours" label="Hours until self-destruct" default="6" />

set -e

# Replace this with your own GitHub username/repo below
REPO_RAW_BASE="https://raw.githubusercontent.com/hnagoya/prove2me-vm-kit/master"

curl -fsSL "${REPO_RAW_BASE}/setup.sh" -o /root/setup.sh
chmod +x /root/setup.sh

DESTROY_TOKEN="${DESTROY_TOKEN:-}" DESTROY_HOURS="${DESTROY_HOURS:-6}" /root/setup.sh
