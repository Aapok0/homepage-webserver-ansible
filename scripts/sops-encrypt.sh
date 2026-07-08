#!/usr/bin/env bash
# Encrypt plaintext Ansible config to committed *.enc files.
# Terraform sync scripts write plaintext inventory/allowlist; re-run this after
# sync if you want the encrypted copies in git updated.
# Prefer editing encrypted files directly: sops group_vars/servers/main.enc.yml
#
# Usage (from homepage-webserver-ansible root):
#   ./scripts/sops-encrypt.sh
#
# Requires: sops, age private key at ~/.config/sops/age/keys.txt

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required." >&2
  exit 1
fi

encrypt_binary() {
  local plain="$1"
  local enc="$2"
  if [[ ! -f "$plain" ]]; then
    echo "skip $plain (not found)" >&2
    return 0
  fi
  mkdir -p "$(dirname "$enc")"
  sops -e --input-type binary --output-type binary \
    --filename-override "$enc" --output "$enc" "$plain"
  echo "encrypted $plain -> $enc"
}

encrypt_yaml() {
  local plain="$1"
  local enc="$2"
  if [[ ! -f "$plain" ]]; then
    echo "skip $plain (not found)" >&2
    return 0
  fi
  mkdir -p "$(dirname "$enc")"
  cp "$plain" "$enc"
  sops -e -i "$enc"
  echo "encrypted $plain -> $enc"
}

encrypt_binary inventory/production inventory/production.enc
encrypt_yaml group_vars/servers/main.yml group_vars/servers/main.enc.yml
encrypt_yaml group_vars/nginx.yml group_vars/nginx.enc.yml
