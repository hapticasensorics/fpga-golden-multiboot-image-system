#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

DRY_RUN=1
MAX_TEMP_C="${MAX_TEMP_C:-85}"

usage() {
  cat <<'USAGE'
Usage:
  gate-app-cycle.sh [--dry-run|--execute] [--max-temp-c C]

Proves the standard development loop:
  golden -> app slot -> app heartbeat -> app return -> golden

Required command env:
  GOLDENGATE_HEALTH_CMD
  GOLDENGATE_CHECK_GOLDEN_CMD
  GOLDENGATE_WARMBOOT_APP_CMD
  GOLDENGATE_RESCAN_CMD
  GOLDENGATE_CHECK_APP_CMD
  GOLDENGATE_RETURN_GOLDEN_CMD

Real execution requires:
  GOLDENGATE_APP_CYCLE_CONFIRM=RUN_APP_CYCLE
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --max-temp-c) MAX_TEMP_C="${2:-}"; shift 2 ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_number MAX_TEMP_C "${MAX_TEMP_C}"
gg_require_execute_confirm GOLDENGATE_APP_CYCLE_CONFIRM RUN_APP_CYCLE "${DRY_RUN}"
for name in GOLDENGATE_HEALTH_CMD GOLDENGATE_CHECK_GOLDEN_CMD GOLDENGATE_WARMBOOT_APP_CMD GOLDENGATE_RESCAN_CMD GOLDENGATE_CHECK_APP_CMD GOLDENGATE_RETURN_GOLDEN_CMD; do
  gg_require_command_env "${name}"
done

gg_header "goldengate.gate_app_cycle.v1"
printf 'dry_run=%s\n' "${DRY_RUN}"
health_text="$(bash -lc "${GOLDENGATE_HEALTH_CMD}")"
temperature_c="$(gg_extract_temperature_c "${health_text}")" ||
  gg_die "health command did not print temperature_c"
printf 'temperature_c=%s\n' "${temperature_c}"
gg_temp_le "${temperature_c}" "${MAX_TEMP_C}" ||
  gg_die "temperature ${temperature_c} C exceeds limit ${MAX_TEMP_C} C"

gg_run_step "${DRY_RUN}" "check-golden-before-app" "${GOLDENGATE_CHECK_GOLDEN_CMD}"
gg_run_step "${DRY_RUN}" "warmboot-app-slot" "${GOLDENGATE_WARMBOOT_APP_CMD}"
gg_run_step "${DRY_RUN}" "transport-rescan-after-app-entry" "${GOLDENGATE_RESCAN_CMD}"
gg_run_step "${DRY_RUN}" "check-app-heartbeat" "${GOLDENGATE_CHECK_APP_CMD}"
gg_run_step "${DRY_RUN}" "return-to-golden" "${GOLDENGATE_RETURN_GOLDEN_CMD}"
gg_run_step "${DRY_RUN}" "transport-rescan-after-return" "${GOLDENGATE_RESCAN_CMD}"
gg_run_step "${DRY_RUN}" "check-golden-after-return" "${GOLDENGATE_CHECK_GOLDEN_CMD}"
printf 'goldengate_gate_app_cycle_pass=1\n'

