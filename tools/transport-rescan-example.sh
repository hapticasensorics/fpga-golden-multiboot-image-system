#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

DRY_RUN=1
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-180}"

usage() {
  cat <<'USAGE'
Usage:
  transport-rescan-example.sh [--dry-run|--execute] [--wait-timeout SECONDS]

Generic transport re-entry wrapper. Set GOLDENGATE_RESCAN_CMD to the
board-specific command that removes/rescans the transport and reloads any host
driver needed after full-chip FPGA warmboot.

For PCIe systems, this should normally be hot remove/rescan, not host reboot.

Real execution requires:
  GOLDENGATE_RESCAN_CONFIRM=CONTROLLED_RESCAN
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --wait-timeout) WAIT_TIMEOUT_SECONDS="${2:-}"; shift 2 ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_int WAIT_TIMEOUT_SECONDS "${WAIT_TIMEOUT_SECONDS}"
gg_require_execute_confirm GOLDENGATE_RESCAN_CONFIRM CONTROLLED_RESCAN "${DRY_RUN}"
gg_require_command_env GOLDENGATE_RESCAN_CMD

gg_header "goldengate.transport_rescan.v1"
printf 'dry_run=%s\n' "${DRY_RUN}"
printf 'wait_timeout_seconds=%s\n' "${WAIT_TIMEOUT_SECONDS}"
gg_run_step "${DRY_RUN}" "controlled-transport-rescan" "${GOLDENGATE_RESCAN_CMD}"
printf 'goldengate_transport_rescan_pass=1\n'

