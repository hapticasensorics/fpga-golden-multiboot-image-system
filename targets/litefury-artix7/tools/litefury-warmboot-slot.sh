#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

slot="${1:-A}"
dry_run=0
if [[ "${slot}" == "--dry-run" ]]; then
  dry_run=1
  slot="${2:-A}"
fi

case "${slot}" in
  A|a) boot_addr="${LITEFURY_SLOT_A_PAYLOAD:-${lf_slot_a_payload}}" ;;
  B|b) boot_addr="${LITEFURY_SLOT_B_PAYLOAD:-${lf_slot_b_payload}}" ;;
  *) lf_die "usage: $0 [--dry-run] A|B" ;;
esac

if [[ "${dry_run}" != "1" && "${GOLDENGATE_LITEFURY_WARMBOOT_CONFIRM:-}" != "JUMP_TO_VERIFIED_SLOT" ]]; then
  lf_die "real warmboot requires GOLDENGATE_LITEFURY_WARMBOOT_CONFIRM=JUMP_TO_VERIFIED_SLOT"
fi

device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
base_dec="$(lf_parse_num "${LITEFURY_GOLDEN_BASE:-${lf_golden_base}}")"
boot_addr_dec="$(lf_parse_num "${boot_addr}")"
flags_dec="$(lf_parse_num "${LITEFURY_WARMBOOT_FLAGS:-${lf_warmboot_flags}}")"

printf 'litefury_warmboot_slot_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
slot_upper="$(printf '%s' "${slot}" | tr '[:lower:]' '[:upper:]')"
printf 'slot=%s\n' "${slot_upper}"
printf 'device=%s\n' "${device}"
printf 'golden_base=%s\n' "$(lf_fmt_hex "${base_dec}")"
printf 'boot_addr=%s\n' "$(lf_fmt_hex "${boot_addr_dec}")"
printf 'boot_flags=%s\n' "$(lf_fmt_hex "${flags_dec}")"
printf 'dry_run=%s\n' "${dry_run}"

if [[ "${dry_run}" == "1" ]]; then
  printf '+ write clear, boot_addr, boot_flags, trigger to golden warmboot page\n'
  exit 0
fi

magic="$(lf_read32 "${device}" "${base_dec}")"
lf_word_is_one_of "${magic}" "474d4230" "4c46474f" ||
  lf_die "golden magic missing before warmboot: 0x${magic}"

lf_write32 "${device}" "$((base_dec + 0x130))" 1
lf_write32 "${device}" "$((base_dec + 0x120))" "${boot_addr_dec}"
lf_write32 "${device}" "$((base_dec + 0x124))" "${flags_dec}"
lf_write32 "${device}" "$((base_dec + 0x134))" "$((0xb00710ad))"
printf 'litefury_warmboot_slot_triggered=1\n'
