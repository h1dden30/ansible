#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${CONFIG_REPO_URL:-https://github.com/h1dden30/ansible.git}"
BRANCH="${CONFIG_REPO_BRANCH:-main}"

echo "==> Installing Ansible + git"
apt-get update -y
apt-get install -y --no-install-recommends ansible-core git curl

read -rsp "Decryption Key: " VAULT_PASSWORD < /dev/tty
echo
printf '%s' "$VAULT_PASSWORD" > /root/.vault_key
chmod 600 /root/.vault_key
unset VAULT_PASSWORD

echo "==> Running ansible-pull job & setting systemd timer."
ansible-pull \
  -U "$REPO_URL" \
  -C "$BRANCH" \
  --vault-password-file /root/.vault_key \
  -i localhost, \
  local.yml

echo "==> Done!"