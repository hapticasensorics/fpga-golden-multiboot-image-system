#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

DRY_RUN=1
PET_SECONDS="${PET_SECONDS:-0}"
WATCHDOG_SETTLE_SECONDS="${WATCHDOG_SETTLE_SECONDS:-2}"

usage() {
  cat <<'USAGE'
Usage:
  gate-app-watchdog.sh [--dry-run|--execute] [--pet-seconds SECONDS]
      [--watchdog-settle SECONDS]

Proves runtime-wedge recovery:
  golden -> app -> watchdog arm -> optional pets -> stop petting -> golden

Required command env:
  GOLDENGATE_CHECK_GOLDEN_CMD
  GOLDENGATE_WARMBOOT_APP_CMD
  GOLDENGATE_RESCAN_CMD
  GOLDENGATE_CHECK_APP_CMD
  GOLDENGATE_ARM_WATCHDOG_CMD
  GOLDENGATE_PET_WATCHDOG_CMD      required only when --pet-seconds > 0
  GOLDENGATE_CHECK_WATCHDOG_RETURN_CMD

Real execution requires:
  GOLDENGATE_WATCHDOG_CONFIRM=RUN_APP_WATCHDOG_RECOVERY
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --pet-seconds) PET_SECONDS="${2:-}"; shift 2 ;;
    --watchdog-settle) WATCHDOG_SETTLE_SECONDS="${2:-}"; shift 2 ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_int PET_SECONDS "${PET_SECONDS}"
gg_require_int WATCHDOG_SETTLE_SECONDS "${WATCHDOG_SETTLE_SECONDS}"
gg_require_execute_confirm GOLDENGATE_WATCHDOG_CONFIRM RUN_APP_WATCHDOG_RECOVERY "${DRY_RUN}"
for name in GOLDENGATE_CHECK_GOLDEN_CMD GOLDENGATE_WARMBOOT_APP_CMD GOLDENGATE_RESCAN_CMD GOLDENGATE_CHECK_APP_CMD GOLDENGATE_ARM_WATCHDOG_CMD GOLDENGATE_CHECK_WATCHDOG_RETURN_CMD; do
  gg_require_command_env "${name}"
done
if (( PET_SECONDS > 0 )); then
  gg_require_command_env GOLDENGATE_PET_WATCHDOG_CMD
fi

gg_header "goldengate.gate_app_watchdog.v1"
printf 'dry_run=%s\n' "${DRY_RUN}"
printf 'pet_seconds=%s\n' "${PET_SECONDS}"
printf 'watchdog_settle_seconds=%s\n' "${WATCHDOG_SETTLE_SECONDS}"
gg_run_step "${DRY_RUN}" "check-golden-before-watchdog" "${GOLDENGATE_CHECK_GOLDEN_CMD}"
gg_run_step "${DRY_RUN}" "warmboot-app-slot" "${GOLDENGATE_WARMBOOT_APP_CMD}"
gg_run_step "${DRY_RUN}" "transport-rescan-after-app-entry" "${GOLDENGATE_RESCAN_CMD}"
gg_run_step "${DRY_RUN}" "check-app-before-watchdog" "${GOLDENGATE_CHECK_APP_CMD}"
gg_run_step "${DRY_RUN}" "arm-watchdog" "${GOLDENGATE_ARM_WATCHDOG_CMD}"
if (( PET_SECONDS > 0 )); then
  end=$((SECONDS + PET_SECONDS))
  while (( SECONDS < end )); do
    gg_run_step "${DRY_RUN}" "pet-watchdog" "${GOLDENGATE_PET_WATCHDOG_CMD}"
    sleep 1
  done
fi
if (( WATCHDOG_SETTLE_SECONDS > 0 )); then
  gg_run_step "${DRY_RUN}" "wait-for-watchdog-expiry" "sleep ${WATCHDOG_SETTLE_SECONDS}"
fi
gg_run_step "${DRY_RUN}" "transport-rescan-after-watchdog" "${GOLDENGATE_RESCAN_CMD}"
gg_run_step "${DRY_RUN}" "check-watchdog-return" "${GOLDENGATE_CHECK_WATCHDOG_RETURN_CMD}"
printf 'goldengate_gate_app_watchdog_pass=1\n'
