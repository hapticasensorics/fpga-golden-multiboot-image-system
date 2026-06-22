#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

mode="${1:-arm}"
dry_run=0
if [[ "${mode}" == "--dry-run" ]]; then
  dry_run=1
  mode="${2:-arm}"
fi

timeout_cycles="${LITEFURY_WATCHDOG_TIMEOUT_CYCLES:-2500000}"
device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
app_base_dec="$(lf_parse_num "${LITEFURY_APP_BASE:-${lf_app_base}}")"

case "${mode}" in
  arm|pet) ;;
  *) lf_die "usage: $0 [--dry-run] arm|pet" ;;
esac

printf 'litefury_watchdog_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'mode=%s\n' "${mode}"
printf 'app_base=%s\n' "$(lf_fmt_hex "${app_base_dec}")"
printf 'timeout_cycles=%s\n' "${timeout_cycles}"
printf 'dry_run=%s\n' "${dry_run}"

if [[ "${dry_run}" == "1" ]]; then
  printf '+ detect GoldenGate GWDT at app+0x200 or legacy HWDT at app+0x600\n'
  printf '+ %s watchdog\n' "${mode}"
  exit 0
fi

generic_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x200))" || true)"
legacy_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x600))" || true)"

if lf_word_is_one_of "${generic_magic:-}" "47574454"; then
  contract="goldengate"
  unlock_off=$((app_base_dec + 0x210))
  timeout_off=$((app_base_dec + 0x208))
  pet_off=$((app_base_dec + 0x20c))
  enable_off=$((app_base_dec + 0x214))
  unlock_magic=$((0x1ee7c0de))
  pet_magic=1
elif lf_word_is_one_of "${legacy_magic:-}" "48574454"; then
  contract="legacy_mrfpga_compatible"
  unlock_off=$((app_base_dec + 0x61c))
  timeout_off=$((app_base_dec + 0x614))
  pet_off=$((app_base_dec + 0x618))
  enable_off=$((app_base_dec + 0x60c))
  unlock_magic=$((0x77646701))
  pet_magic=$((0x70657431))
else
  lf_die "watchdog page missing"
fi

printf 'watchdog_contract=%s\n' "${contract}"

case "${mode}" in
  arm)
    [[ "${GOLDENGATE_LITEFURY_WATCHDOG_CONFIRM:-}" == "ARM_WATCHDOG" ]] ||
      lf_die "arming requires GOLDENGATE_LITEFURY_WATCHDOG_CONFIRM=ARM_WATCHDOG"
    lf_write32 "${device}" "${unlock_off}" "${unlock_magic}"
    lf_write32 "${device}" "${timeout_off}" "$(lf_parse_num "${timeout_cycles}")"
    lf_write32 "${device}" "${enable_off}" 1
    printf 'litefury_watchdog_armed=1\n'
    ;;
  pet)
    lf_write32 "${device}" "${pet_off}" "${pet_magic}"
    printf 'litefury_watchdog_pet=1\n'
    ;;
esac

