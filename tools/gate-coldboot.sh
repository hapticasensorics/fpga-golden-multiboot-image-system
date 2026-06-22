#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

MAX_TEMP_C="${MAX_TEMP_C:-85}"
SKIP_THERMAL=0

usage() {
  cat <<'USAGE'
Usage:
  gate-coldboot.sh [--max-temp-c C] [--skip-thermal]

Proves the permanent golden image is alive after cold boot.

Required command env:
  GOLDENGATE_CHECK_GOLDEN_CMD  command that exits 0 only when golden identity,
                               ABI, boot status, and health pages are readable

Optional command env:
  GOLDENGATE_HEALTH_CMD        used unless --skip-thermal is supplied
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-temp-c) MAX_TEMP_C="${2:-}"; shift 2 ;;
    --skip-thermal) SKIP_THERMAL=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_number MAX_TEMP_C "${MAX_TEMP_C}"
gg_require_command_env GOLDENGATE_CHECK_GOLDEN_CMD

gg_header "goldengate.gate_coldboot.v1"
if [[ "${SKIP_THERMAL}" != "1" ]]; then
  gg_require_command_env GOLDENGATE_HEALTH_CMD
  health_text="$(bash -lc "${GOLDENGATE_HEALTH_CMD}")"
  temperature_c="$(gg_extract_temperature_c "${health_text}")" ||
    gg_die "health command did not print temperature_c"
  printf 'temperature_c=%s\n' "${temperature_c}"
  gg_temp_le "${temperature_c}" "${MAX_TEMP_C}" ||
    gg_die "temperature ${temperature_c} C exceeds limit ${MAX_TEMP_C} C"
fi

gg_run_step 0 "check-golden-identity" "${GOLDENGATE_CHECK_GOLDEN_CMD}"
printf 'goldengate_gate_coldboot_pass=1\n'

