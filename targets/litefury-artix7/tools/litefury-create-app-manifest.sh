#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

image="${1:-}"
slot="${2:-A}"
[[ -n "${image}" && -f "${image}" ]] || lf_die "usage: $0 IMAGE.bit A|B"

case "${slot}" in
  A|a)
    slot="A"
    slot_base="0x00680000"
    payload="0x00680100"
    ;;
  B|b)
    slot="B"
    slot_base="0x00a80000"
    payload="0x00a80100"
    ;;
  *)
    lf_die "slot must be A or B"
    ;;
esac

if command -v sha256sum >/dev/null 2>&1; then
  sha="$(sha256sum "${image}" | awk '{print $1}')"
else
  sha="$(shasum -a 256 "${image}" | awk '{print $1}')"
fi

size="$(wc -c < "${image}" | tr -d ' ')"
name="$(basename "${image}")"
timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat <<EOF
{
  "manifest_version": 1,
  "image_name": "${name}",
  "image_sha256": "${sha}",
  "slot": "${slot}",
  "slot_base": "${slot_base}",
  "payload_offset": "0x00000100",
  "payload_address": "${payload}",
  "image_size_bytes": ${size},
  "verified": false,
  "source_commit": "unknown",
  "build_time_utc": "${timestamp}",
  "notes": "Generated before flash readback. Set verified=true only after slot readback hash matches."
}
EOF

