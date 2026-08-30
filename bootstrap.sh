#!/usr/bin/env bash
# bootstrap.sh — run this ONCE on a freshly created VM, as root.
#
#   curl -fsSL https://raw.githubusercontent.com/<you>/config-mgmt/main/bootstrap.sh | bash
#
# or scp it over and run locally. Either way: after this, the box owns its
# own recurring pulls via the systemd timer the "bootstrap" Ansible role
# installs — you never run this script (or think about the timer) again
# on this host.
set -euo pipefail

REPO_URL="${CONFIG_REPO_URL:-https://github.com/h1dden30/ansible.git}"
BRANCH="${CONFIG_REPO_BRANCH:-main}"

echo "==> Installing Ansible + git"
apt-get update -y
apt-get install -y --no-install-recommends ansible-core git curl

echo "==> Vault password for this host's ansible-vault secrets"
echo "    (this is the SAME password you used to encrypt group_vars/all/vault.yml)"
read -rsp "Vault password: " VAULT_PASSWORD
echo
printf '%s' "$VAULT_PASSWORD" > /root/.vault_key
chmod 600 /root/.vault_key
unset VAULT_PASSWORD

echo "==> Running first ansible-pull (this installs the recurring timer too)"
ansible-pull \
  -U "$REPO_URL" \
  -C "$BRANCH" \
  --vault-password-file /root/.vault_key \
  -i localhost, \
  local.yml

echo "==> Done. Recurring pulls now handled by systemd — check with:"
echo "    systemctl status ansible-pull.timer"
