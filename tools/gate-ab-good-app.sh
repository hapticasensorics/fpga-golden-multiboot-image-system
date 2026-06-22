#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

DRY_RUN=1
SLOT="${SLOT:-both}"

usage() {
  cat <<'USAGE'
Usage:
  gate-ab-good-app.sh [--dry-run|--execute] [--slot A|B|both]

Installs or selects the same known-good app in slot A and slot B, then proves
each selected slot can boot and return to golden.

Required command env:
  GOLDENGATE_PREPARE_SLOT_A_CMD
  GOLDENGATE_PREPARE_SLOT_B_CMD
  GOLDENGATE_APP_CYCLE_SLOT_A_CMD
  GOLDENGATE_APP_CYCLE_SLOT_B_CMD

Real execution requires:
  GOLDENGATE_AB_CONFIRM=INSTALL_AND_TEST_GOOD_APP_SLOTS
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --slot) SLOT="${2:-}"; shift 2 ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

case "${SLOT}" in A|a|B|b|both) ;; *) gg_die "--slot must be A, B, or both" ;; esac
gg_require_execute_confirm GOLDENGATE_AB_CONFIRM INSTALL_AND_TEST_GOOD_APP_SLOTS "${DRY_RUN}"

gg_header "goldengate.gate_ab_good_app.v1"
printf 'dry_run=%s\n' "${DRY_RUN}"
printf 'slot=%s\n' "${SLOT}"

if [[ "${SLOT}" == "A" || "${SLOT}" == "a" || "${SLOT}" == "both" ]]; then
  gg_require_command_env GOLDENGATE_PREPARE_SLOT_A_CMD
  gg_require_command_env GOLDENGATE_APP_CYCLE_SLOT_A_CMD
  gg_run_step "${DRY_RUN}" "prepare-slot-a" "${GOLDENGATE_PREPARE_SLOT_A_CMD}"
  gg_run_step "${DRY_RUN}" "cycle-slot-a" "${GOLDENGATE_APP_CYCLE_SLOT_A_CMD}"
fi
if [[ "${SLOT}" == "B" || "${SLOT}" == "b" || "${SLOT}" == "both" ]]; then
  gg_require_command_env GOLDENGATE_PREPARE_SLOT_B_CMD
  gg_require_command_env GOLDENGATE_APP_CYCLE_SLOT_B_CMD
  gg_run_step "${DRY_RUN}" "prepare-slot-b" "${GOLDENGATE_PREPARE_SLOT_B_CMD}"
  gg_run_step "${DRY_RUN}" "cycle-slot-b" "${GOLDENGATE_APP_CYCLE_SLOT_B_CMD}"
fi

printf 'goldengate_gate_ab_good_app_pass=1\n'

