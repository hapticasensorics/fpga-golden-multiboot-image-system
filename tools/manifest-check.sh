#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-}"
[[ -n "${manifest}" ]] || {
  printf 'usage: %s manifest.json\n' "$0" >&2
  exit 2
}
[[ -f "${manifest}" ]] || {
  printf 'error: manifest not found: %s\n' "${manifest}" >&2
  exit 1
}

require_key() {
  local key="$1"
  if ! grep -q "\"${key}\"[[:space:]]*:" "${manifest}"; then
    printf 'error: missing key: %s\n' "${key}" >&2
    exit 1
  fi
}

require_key manifest_version
require_key image_name
require_key image_sha256
require_key slot
require_key slot_base
require_key payload_offset
require_key payload_address
require_key image_size_bytes
require_key verified

if ! grep -Eq '"image_sha256"[[:space:]]*:[[:space:]]*"[0-9a-fA-F]{64}"' "${manifest}"; then
  printf 'error: image_sha256 must be 64 hex characters\n' >&2
  exit 1
fi

if ! grep -Eq '"verified"[[:space:]]*:[[:space:]]*true' "${manifest}"; then
  printf 'error: manifest is not verified=true\n' >&2
  exit 1
fi

printf 'manifest ok: %s\n' "${manifest}"

