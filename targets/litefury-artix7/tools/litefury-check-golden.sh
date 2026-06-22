#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
golden_base_dec="$(lf_parse_num "${LITEFURY_GOLDEN_BASE:-${lf_golden_base}}")"
magic="$(lf_read32 "${device}" "${golden_base_dec}")"

printf 'litefury_check_golden_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'device=%s\n' "${device}"
printf 'golden_base=%s\n' "$(lf_fmt_hex "${golden_base_dec}")"
printf 'golden_magic=0x%s\n' "${magic}"

if lf_word_is_one_of "${magic}" "474d4230" "4c46474f"; then
  printf 'golden_present=1\n'
else
  printf 'golden_present=0\n'
  lf_die "expected GoldenGate GMB0 or legacy LFGO magic"
fi

abi="$(lf_read32 "${device}" "$((golden_base_dec + 0x004))" || true)"
caps="$(lf_read32 "${device}" "$((golden_base_dec + 0x00c))" || true)"
boot_reason="$(lf_read32 "${device}" "$((golden_base_dec + 0x020))" || true)"
printf 'golden_abi_or_version=0x%s\n' "${abi:-00000000}"
printf 'golden_capabilities=0x%s\n' "${caps:-00000000}"
printf 'golden_boot_reason=0x%s\n' "${boot_reason:-00000000}"
printf 'litefury_check_golden_pass=1\n'

