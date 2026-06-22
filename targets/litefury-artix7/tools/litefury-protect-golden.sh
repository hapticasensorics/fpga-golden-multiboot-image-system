#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

MODE="status"
DRY_RUN=1
LOCK_PPB=0

usage() {
  cat <<'USAGE'
Usage:
  litefury-protect-golden.sh [--status|--protect|--verify|--unprotect-for-refresh]
      [--dry-run|--execute] [--lock-ppb]

Wraps LiteFury SPI flash protection policy for the permanent golden region.

Backend command contract:
  LITEFURY_FLASH_PROTECT_STATUS_CMD BASE_HEX LIMIT_HEX
  LITEFURY_FLASH_PROTECT_CMD        BASE_HEX LIMIT_HEX LOCK_PPB_0_OR_1
  LITEFURY_FLASH_UNPROTECT_CMD      BASE_HEX LIMIT_HEX
  LITEFURY_FLASH_VERIFY_PROTECT_CMD BASE_HEX LIMIT_HEX

Real mutating execution requires:
  GOLDENGATE_LITEFURY_PROTECT_CONFIRM=CHANGE_GOLDEN_FLASH_PROTECTION

During active development, protect without --lock-ppb. Persistent sector
protection catches accidental erases while preserving software refresh. Use
--lock-ppb only as a final shipping hardening step.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) MODE="status"; shift ;;
    --protect) MODE="protect"; shift ;;
    --verify) MODE="verify"; shift ;;
    --unprotect-for-refresh) MODE="unprotect-for-refresh"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --lock-ppb) LOCK_PPB=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) lf_die "unknown argument: $1" ;;
  esac
done

base_dec="$(lf_parse_num "${LITEFURY_GOLDEN_FLASH_BASE:-0x0}")"
limit_dec="$(lf_parse_num "${LITEFURY_PROTECTED_GOLDEN_LIMIT:-0x400000}")"
base_hex="$(printf '0x%06x' "${base_dec}")"
limit_hex="$(printf '0x%06x' "${limit_dec}")"

printf 'litefury_protect_golden_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'mode=%s\n' "${MODE}"
printf 'golden_base=%s\n' "${base_hex}"
printf 'protected_limit=%s\n' "${limit_hex}"
printf 'lock_ppb=%s\n' "${LOCK_PPB}"
printf 'dry_run=%s\n' "${DRY_RUN}"

require_confirm_for_mutation() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    return 0
  fi
  [[ "${GOLDENGATE_LITEFURY_PROTECT_CONFIRM:-}" == "CHANGE_GOLDEN_FLASH_PROTECTION" ]] ||
    lf_die "real protection mutation requires GOLDENGATE_LITEFURY_PROTECT_CONFIRM=CHANGE_GOLDEN_FLASH_PROTECTION"
}

LITEFURY_FLASH_PROTECT_STATUS_CMD="${LITEFURY_FLASH_PROTECT_STATUS_CMD:-${script_dir}/litefury-spi-protect-status.sh}"
LITEFURY_FLASH_PROTECT_CMD="${LITEFURY_FLASH_PROTECT_CMD:-${script_dir}/litefury-spi-protect.sh}"
LITEFURY_FLASH_UNPROTECT_CMD="${LITEFURY_FLASH_UNPROTECT_CMD:-${script_dir}/litefury-spi-unprotect.sh}"
LITEFURY_FLASH_VERIFY_PROTECT_CMD="${LITEFURY_FLASH_VERIFY_PROTECT_CMD:-${script_dir}/litefury-spi-verify-protect.sh}"

run_backend() {
  local label="$1"
  local var_name="$2"
  shift 2
  local cmd="${!var_name:-}"
  if [[ "${DRY_RUN}" != "1" && -z "${cmd}" ]]; then
    lf_die "missing ${var_name}"
  fi
  printf '+ %s %s\n' "${cmd:-<${var_name}>}" "$*"
  if [[ "${DRY_RUN}" != "1" ]]; then
    "${cmd}" "$@"
  fi
  printf '%s_done=1\n' "${label}"
}

case "${MODE}" in
  status)
    run_backend protect_status LITEFURY_FLASH_PROTECT_STATUS_CMD "${base_hex}" "${limit_hex}"
    ;;
  verify)
    run_backend verify_protected LITEFURY_FLASH_VERIFY_PROTECT_CMD "${base_hex}" "${limit_hex}"
    ;;
  protect)
    require_confirm_for_mutation
    run_backend protect_golden LITEFURY_FLASH_PROTECT_CMD "${base_hex}" "${limit_hex}" "${LOCK_PPB}"
    ;;
  unprotect-for-refresh)
    require_confirm_for_mutation
    run_backend unprotect_for_refresh LITEFURY_FLASH_UNPROTECT_CMD "${base_hex}" "${limit_hex}"
    ;;
  *)
    lf_die "unknown mode: ${MODE}"
    ;;
esac

printf 'litefury_protect_golden_done=1\n'
