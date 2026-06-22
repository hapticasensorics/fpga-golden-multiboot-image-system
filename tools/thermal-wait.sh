#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

MAX_TEMP_C="${MAX_TEMP_C:-85}"
POLL_SECONDS="${POLL_SECONDS:-10}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-600}"
ONCE=0

usage() {
  cat <<'USAGE'
Usage:
  thermal-wait.sh [--max-temp-c C] [--timeout SECONDS]
      [--poll-seconds SECONDS] [--once]

Read-only thermal gate. Set GOLDENGATE_HEALTH_CMD to a command that prints
either JSON containing "temperature_c" or a line like:

  temperature_c=83.2

This helper performs no flash, warmboot, transport reset, or BAR write.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-temp-c) MAX_TEMP_C="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT_SECONDS="${2:-}"; shift 2 ;;
    --poll-seconds) POLL_SECONDS="${2:-}"; shift 2 ;;
    --once) ONCE=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_number MAX_TEMP_C "${MAX_TEMP_C}"
gg_require_int POLL_SECONDS "${POLL_SECONDS}"
gg_require_int TIMEOUT_SECONDS "${TIMEOUT_SECONDS}"
gg_require_command_env GOLDENGATE_HEALTH_CMD

gg_header "goldengate.thermal_wait.v1"
printf 'max_temp_c=%s\n' "${MAX_TEMP_C}"
printf 'timeout_seconds=%s\n' "${TIMEOUT_SECONDS}"
printf 'poll_seconds=%s\n' "${POLL_SECONDS}"
printf 'read_only=1\n'

deadline=$((SECONDS + TIMEOUT_SECONDS))
sample_index=0

while :; do
  sample_index=$((sample_index + 1))
  health_text="$(bash -lc "${GOLDENGATE_HEALTH_CMD}")"
  temperature_c="$(gg_extract_temperature_c "${health_text}")" ||
    gg_die "health command did not print temperature_c"

  printf 'sample_index=%s\n' "${sample_index}"
  printf 'temperature_c=%s\n' "${temperature_c}"

  if gg_temp_le "${temperature_c}" "${MAX_TEMP_C}"; then
    printf 'thermal_safe=1\n'
    printf 'goldengate_thermal_wait_pass=1\n'
    exit 0
  fi

  printf 'thermal_safe=0\n'
  if [[ "${ONCE}" == "1" ]]; then
    gg_die "temperature ${temperature_c} C exceeds limit ${MAX_TEMP_C} C"
  fi
  (( SECONDS < deadline )) ||
    gg_die "timed out waiting for temperature <= ${MAX_TEMP_C} C"
  sleep "${POLL_SECONDS}"
done

