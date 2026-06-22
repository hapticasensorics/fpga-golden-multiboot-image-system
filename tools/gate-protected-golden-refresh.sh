#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

DRY_RUN=1
MAX_TEMP_C="${MAX_TEMP_C:-85}"
LOCK_AFTER_REFRESH=0

usage() {
  cat <<'USAGE'
Usage:
  gate-protected-golden-refresh.sh [--dry-run|--execute]
      [--max-temp-c C] [--lock-after-refresh]

Runs the deliberate permanent-golden refresh ceremony:
  thermal preflight
  -> unprotect golden for refresh
  -> program candidate golden at coldboot address
  -> verify readback/hash
  -> re-protect golden
  -> prove coldboot golden identity

Required command env:
  GOLDENGATE_HEALTH_CMD
  GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD
  GOLDENGATE_PROGRAM_GOLDEN_CMD
  GOLDENGATE_VERIFY_GOLDEN_IMAGE_CMD
  GOLDENGATE_PROTECT_GOLDEN_CMD
  GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD
  GOLDENGATE_CHECK_GOLDEN_CMD

Real execution requires:
  GOLDENGATE_REFRESH_CONFIRM=REFRESH_PERMANENT_GOLDEN

Do not use --lock-after-refresh while golden is still being iterated. Persistent
sector protection is the normal development posture; volatile/global lock latches
are final-hardening policy.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --max-temp-c) MAX_TEMP_C="${2:-}"; shift 2 ;;
    --lock-after-refresh) LOCK_AFTER_REFRESH=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_number MAX_TEMP_C "${MAX_TEMP_C}"
gg_require_execute_confirm GOLDENGATE_REFRESH_CONFIRM REFRESH_PERMANENT_GOLDEN "${DRY_RUN}"
for name in GOLDENGATE_HEALTH_CMD GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD GOLDENGATE_PROGRAM_GOLDEN_CMD GOLDENGATE_VERIFY_GOLDEN_IMAGE_CMD GOLDENGATE_PROTECT_GOLDEN_CMD GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD GOLDENGATE_CHECK_GOLDEN_CMD; do
  gg_require_command_env "${name}"
done

gg_header "goldengate.gate_protected_golden_refresh.v1"
printf 'dry_run=%s\n' "${DRY_RUN}"
printf 'lock_after_refresh=%s\n' "${LOCK_AFTER_REFRESH}"
health_text="$(bash -lc "${GOLDENGATE_HEALTH_CMD}")"
temperature_c="$(gg_extract_temperature_c "${health_text}")" ||
  gg_die "health command did not print temperature_c"
printf 'temperature_c=%s\n' "${temperature_c}"
gg_temp_le "${temperature_c}" "${MAX_TEMP_C}" ||
  gg_die "temperature ${temperature_c} C exceeds limit ${MAX_TEMP_C} C"

gg_run_step "${DRY_RUN}" "unprotect-golden-for-refresh" "${GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD}"
gg_run_step "${DRY_RUN}" "program-candidate-golden" "${GOLDENGATE_PROGRAM_GOLDEN_CMD}"
gg_run_step "${DRY_RUN}" "verify-candidate-golden-readback" "${GOLDENGATE_VERIFY_GOLDEN_IMAGE_CMD}"
gg_run_step "${DRY_RUN}" "protect-golden-region" "${GOLDENGATE_PROTECT_GOLDEN_CMD}"
gg_run_step "${DRY_RUN}" "verify-golden-protected" "${GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD}"
if [[ "${LOCK_AFTER_REFRESH}" == "1" ]]; then
  printf 'golden_protection_lock_requested=1\n'
fi
gg_run_step "${DRY_RUN}" "check-golden-after-refresh" "${GOLDENGATE_CHECK_GOLDEN_CMD}"
printf 'goldengate_gate_protected_golden_refresh_pass=1\n'
