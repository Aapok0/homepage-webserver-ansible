#!/usr/bin/env bash
# Decrypt committed SOPS files to plaintext paths Ansible expects.
# Plaintext paths are gitignored; run on a new machine before playbooks.
#
# Usage (from homepage-webserver-ansible root):
#   ./scripts/sops-decrypt.sh
#
# Requires: sops, age private key at ~/.config/sops/age/keys.txt

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required." >&2
  exit 1
fi

decrypt() {
  local enc="$1"
  local plain="$2"
  if [[ ! -f "$enc" ]]; then
    echo "skip $enc (not found)" >&2
    return 0
  fi
  mkdir -p "$(dirname "$plain")"
  sops -d "$enc" >"$plain"
  chmod 600 "$plain"
  echo "decrypted $enc -> $plain"
}

decrypt inventory/production.enc inventory/production
decrypt group_vars/servers/main.enc.yml group_vars/servers/main.yml
decrypt group_vars/nginx.enc.yml group_vars/nginx.yml
