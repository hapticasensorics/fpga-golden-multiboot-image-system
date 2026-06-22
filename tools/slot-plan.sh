#!/usr/bin/env bash
set -euo pipefail

hex_to_dec() {
  local value="$1"
  if [[ "${value}" =~ ^0x[0-9a-fA-F]+$ ]]; then
    printf '%u' "$((value))"
  else
    printf '%u' "${value}"
  fi
}

fmt_hex() {
  printf '0x%08x' "$1"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

GOLDEN_LIMIT="$(hex_to_dec "${GOLDEN_LIMIT:-0x00400000}")"
UPDATE_REGION_END="$(hex_to_dec "${UPDATE_REGION_END:-0x01000000}")"
SLOT_A_BASE="$(hex_to_dec "${SLOT_A_BASE:-0x00680000}")"
SLOT_B_BASE="$(hex_to_dec "${SLOT_B_BASE:-0x00a80000}")"
SLOT_SIZE="$(hex_to_dec "${SLOT_SIZE:-0x00400000}")"
PAYLOAD_OFFSET="$(hex_to_dec "${PAYLOAD_OFFSET:-0x00000100}")"
ALIGN_MASK="$(hex_to_dec "${ALIGN_MASK:-0x000000ff}")"

SLOT_A_END=$((SLOT_A_BASE + SLOT_SIZE))
SLOT_B_END=$((SLOT_B_BASE + SLOT_SIZE))
SLOT_A_PAYLOAD=$((SLOT_A_BASE + PAYLOAD_OFFSET))
SLOT_B_PAYLOAD=$((SLOT_B_BASE + PAYLOAD_OFFSET))

[[ "${SLOT_A_BASE}" -ge "${GOLDEN_LIMIT}" ]] || fail "slot A overlaps protected golden region"
[[ "${SLOT_B_BASE}" -ge "${GOLDEN_LIMIT}" ]] || fail "slot B overlaps protected golden region"
[[ "${SLOT_A_END}" -le "${UPDATE_REGION_END}" ]] || fail "slot A exceeds update region"
[[ "${SLOT_B_END}" -le "${UPDATE_REGION_END}" ]] || fail "slot B exceeds update region"

if [[ "${SLOT_A_BASE}" -lt "${SLOT_B_END}" && "${SLOT_B_BASE}" -lt "${SLOT_A_END}" ]]; then
  fail "slot A and slot B overlap"
fi

[[ $((SLOT_A_PAYLOAD & ALIGN_MASK)) -eq 0 ]] || fail "slot A payload is not aligned"
[[ $((SLOT_B_PAYLOAD & ALIGN_MASK)) -eq 0 ]] || fail "slot B payload is not aligned"

cat <<EOF
GoldenGate FPGA slot plan

protected_golden_limit=$(fmt_hex "${GOLDEN_LIMIT}")
update_region_end=$(fmt_hex "${UPDATE_REGION_END}")
slot_a_base=$(fmt_hex "${SLOT_A_BASE}")
slot_a_end=$(fmt_hex "${SLOT_A_END}")
slot_a_payload=$(fmt_hex "${SLOT_A_PAYLOAD}")
slot_b_base=$(fmt_hex "${SLOT_B_BASE}")
slot_b_end=$(fmt_hex "${SLOT_B_END}")
slot_b_payload=$(fmt_hex "${SLOT_B_PAYLOAD}")
slot_size=$(fmt_hex "${SLOT_SIZE}")
payload_offset=$(fmt_hex "${PAYLOAD_OFFSET}")

Next steps:
  1. Program image into the selected slot container.
  2. Read back and compare SHA-256.
  3. Mark the slot verified in the manifest.
  4. Ask golden to warmboot the payload address.
EOF

