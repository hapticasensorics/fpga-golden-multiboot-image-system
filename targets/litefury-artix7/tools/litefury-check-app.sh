#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
app_base_dec="$(lf_parse_num "${LITEFURY_APP_BASE:-${lf_app_base}}")"
app_magic="$(lf_read32 "${device}" "${app_base_dec}" || true)"
legacy_app_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x500))" || true)"

printf 'litefury_check_app_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'device=%s\n' "${device}"
printf 'app_base=%s\n' "$(lf_fmt_hex "${app_base_dec}")"
printf 'app_magic=0x%s\n' "${app_magic:-00000000}"
printf 'legacy_app_magic_at_0x500=0x%s\n' "${legacy_app_magic:-00000000}"

if lf_word_is_one_of "${app_magic:-}" "47415050"; then
  heartbeat="$(lf_read32 "${device}" "$((app_base_dec + 0x018))")"
  printf 'app_contract=goldengate\n'
  printf 'app_heartbeat=0x%s\n' "${heartbeat}"
elif lf_word_is_one_of "${legacy_app_magic:-}" "48415050"; then
  heartbeat="$(lf_read32 "${device}" "$((app_base_dec + 0x520))")"
  hret_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x580))" || true)"
  hwdt_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x600))" || true)"
  printf 'app_contract=legacy_mrfpga_compatible\n'
  printf 'app_heartbeat=0x%s\n' "${heartbeat}"
  printf 'return_page_magic=0x%s\n' "${hret_magic:-00000000}"
  printf 'watchdog_page_magic=0x%s\n' "${hwdt_magic:-00000000}"
else
  printf 'app_present=0\n'
  lf_die "expected GoldenGate GAPP at app base or legacy HAPP at app+0x500"
fi

printf 'app_present=1\n'
printf 'litefury_check_app_pass=1\n'

