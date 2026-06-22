#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

DEVICE="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
HEALTH_BASE="${LITEFURY_HEALTH_BASE:-0x63c0}"
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  litefury-health.sh [--dry-run] [--device PATH] [--base OFFSET]

Reads the LiteFury health page and prints key=value telemetry suitable for the
generic GoldenGate thermal gates.

Default binding:
  LITEFURY_HEALTH_BASE=0x63c0

Expected register layout:
  +0x00 magic: GHLT, HHLT, or compatible target health page
  +0x08 sample_count
  +0x0c temperature_mdeg_c
  +0x10 max_temperature_mdeg_c
  +0x14 min_temperature_mdeg_c
  +0x18 vccint_mv
  +0x1c vccaux_mv
  +0x20 alarm_flags
  +0x24 sticky_alarm_flags
  +0x28 transport_status
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --device) DEVICE="${2:-}"; shift 2 ;;
    --base) HEALTH_BASE="${2:-}"; shift 2 ;;
    -h|--help|help) usage; exit 0 ;;
    *) lf_die "unknown argument: $1" ;;
  esac
done

base_dec="$(lf_parse_num "${HEALTH_BASE}")"

printf 'litefury_health_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'device=%s\n' "${DEVICE}"
printf 'health_base=%s\n' "$(lf_fmt_hex "${base_dec}")"
printf 'dry_run=%s\n' "${DRY_RUN}"

if [[ "${DRY_RUN}" == "1" ]]; then
  printf 'magic=DRYRUN\n'
  printf 'temperature_c=42.000\n'
  printf 'sample_count=0\n'
  printf 'alarm_flags=0x00000000\n'
  exit 0
fi

read_word() {
  local rel_dec="$1"
  lf_read32 "${DEVICE}" "$((base_dec + rel_dec))"
}

magic="$(read_word 0)"
lf_word_is_one_of "${magic}" 47484c54 48484c54 4c46484c ||
  lf_die "health magic not recognized at $(lf_fmt_hex "${base_dec}"): 0x${magic}"

sample_count_hex="$(read_word 8)"
temperature_mdeg_hex="$(read_word 12)"
max_temperature_mdeg_hex="$(read_word 16)"
min_temperature_mdeg_hex="$(read_word 20)"
vccint_mv_hex="$(read_word 24)"
vccaux_mv_hex="$(read_word 28)"
alarm_flags="$(read_word 32)"
sticky_alarm_flags="$(read_word 36)"
transport_status="$(read_word 40)"

temperature_mdeg=$((16#${temperature_mdeg_hex}))
max_temperature_mdeg=$((16#${max_temperature_mdeg_hex}))
min_temperature_mdeg=$((16#${min_temperature_mdeg_hex}))

printf 'magic=0x%s\n' "${magic}"
printf 'sample_count=%u\n' "$((16#${sample_count_hex}))"
awk -v v="${temperature_mdeg}" 'BEGIN { printf "temperature_c=%.3f\n", v / 1000.0 }'
awk -v v="${max_temperature_mdeg}" 'BEGIN { printf "max_temperature_c=%.3f\n", v / 1000.0 }'
awk -v v="${min_temperature_mdeg}" 'BEGIN { printf "min_temperature_c=%.3f\n", v / 1000.0 }'
printf 'vccint_mv=%u\n' "$((16#${vccint_mv_hex}))"
printf 'vccaux_mv=%u\n' "$((16#${vccaux_mv_hex}))"
printf 'alarm_flags=0x%s\n' "${alarm_flags}"
printf 'sticky_alarm_flags=0x%s\n' "${sticky_alarm_flags}"
printf 'transport_status=0x%s\n' "${transport_status}"
