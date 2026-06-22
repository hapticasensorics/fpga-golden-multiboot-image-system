#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

MODE="status"
DRY_RUN=1
LOCK_PROTECTION=0

usage() {
  cat <<'USAGE'
Usage:
  gate-golden-protect.sh [--status|--protect|--verify|--unprotect-for-refresh]
      [--dry-run|--execute] [--lock-protection]

Generic flash-protection gate for the permanent golden region.

Required command env by mode:
  GOLDENGATE_PROTECT_STATUS_CMD
  GOLDENGATE_PROTECT_GOLDEN_CMD
  GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD
  GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD

Real mutating execution requires:
  GOLDENGATE_PROTECT_CONFIRM=CHANGE_GOLDEN_FLASH_PROTECTION

Keep --lock-protection for final hardening. During active golden iteration,
prefer persistent sector protection without volatile/global lock latches.
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
    --lock-protection) LOCK_PROTECTION=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_header "goldengate.gate_golden_protect.v1"
printf 'mode=%s\n' "${MODE}"
printf 'dry_run=%s\n' "${DRY_RUN}"
printf 'lock_protection=%s\n' "${LOCK_PROTECTION}"

case "${MODE}" in
  status)
    gg_require_command_env GOLDENGATE_PROTECT_STATUS_CMD
    gg_run_step "${DRY_RUN}" "protect-status" "${GOLDENGATE_PROTECT_STATUS_CMD}"
    ;;
  verify)
    gg_require_command_env GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD
    gg_run_step "${DRY_RUN}" "verify-golden-protected" "${GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD}"
    ;;
  protect)
    gg_require_execute_confirm GOLDENGATE_PROTECT_CONFIRM CHANGE_GOLDEN_FLASH_PROTECTION "${DRY_RUN}"
    gg_require_command_env GOLDENGATE_PROTECT_GOLDEN_CMD
    gg_require_command_env GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD
    gg_run_step "${DRY_RUN}" "protect-golden-region" "${GOLDENGATE_PROTECT_GOLDEN_CMD}"
    gg_run_step "${DRY_RUN}" "verify-golden-protected" "${GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD}"
    ;;
  unprotect-for-refresh)
    gg_require_execute_confirm GOLDENGATE_PROTECT_CONFIRM CHANGE_GOLDEN_FLASH_PROTECTION "${DRY_RUN}"
    gg_require_command_env GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD
    gg_run_step "${DRY_RUN}" "unprotect-for-golden-refresh" "${GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD}"
    ;;
  *)
    gg_die "unknown mode: ${MODE}"
    ;;
esac

printf 'goldengate_gate_golden_protect_pass=1\n'

