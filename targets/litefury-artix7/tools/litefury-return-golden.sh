#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

dry_run=0
[[ "${1:-}" == "--dry-run" ]] && dry_run=1

if [[ "${dry_run}" != "1" && "${GOLDENGATE_LITEFURY_RETURN_CONFIRM:-}" != "RETURN_TO_GOLDEN" ]]; then
  lf_die "real return requires GOLDENGATE_LITEFURY_RETURN_CONFIRM=RETURN_TO_GOLDEN"
fi

device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
app_base_dec="$(lf_parse_num "${LITEFURY_APP_BASE:-${lf_app_base}}")"

printf 'litefury_return_golden_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'app_base=%s\n' "$(lf_fmt_hex "${app_base_dec}")"
printf 'dry_run=%s\n' "${dry_run}"

if [[ "${dry_run}" == "1" ]]; then
  printf '+ detect GoldenGate GRET at app+0x100 or legacy HRET at app+0x580\n'
  printf '+ write return-to-golden trigger\n'
  exit 0
fi

generic_return_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x100))" || true)"
legacy_return_magic="$(lf_read32 "${device}" "$((app_base_dec + 0x580))" || true)"

printf 'generic_return_magic=0x%s\n' "${generic_return_magic:-00000000}"
printf 'legacy_return_magic=0x%s\n' "${legacy_return_magic:-00000000}"

if lf_word_is_one_of "${generic_return_magic:-}" "47524554"; then
  boot_addr_off=$((app_base_dec + 0x108))
  trigger_off=$((app_base_dec + 0x10c))
  clear_off=""
  printf 'return_contract=goldengate\n'
elif lf_word_is_one_of "${legacy_return_magic:-}" "48524554"; then
  boot_addr_off=$((app_base_dec + 0x590))
  flags_off=$((app_base_dec + 0x594))
  clear_off=$((app_base_dec + 0x5a0))
  trigger_off=$((app_base_dec + 0x5a4))
  printf 'return_contract=legacy_mrfpga_compatible\n'
else
  lf_die "return page missing"
fi

if [[ -n "${clear_off}" ]]; then
  lf_write32 "${device}" "${clear_off}" 1
  lf_write32 "${device}" "${boot_addr_off}" 0
  lf_write32 "${device}" "${flags_off}" "$((0x3))"
else
  lf_write32 "${device}" "${boot_addr_off}" 4
fi
lf_write32 "${device}" "${trigger_off}" "$((0xb00710ad))"
printf 'litefury_return_golden_triggered=1\n'
