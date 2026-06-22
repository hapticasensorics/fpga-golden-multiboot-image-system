#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/goldengate-common.sh"

DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage:
  gate-bad-slot-fallback.sh [--dry-run|--execute]

Proves failure handling with a deliberately bad slot image.

Required command env:
  GOLDENGATE_PREPARE_BAD_SLOT_CMD
  GOLDENGATE_CHECK_GOLDEN_CMD
  GOLDENGATE_BOOT_BAD_SLOT_CMD
  GOLDENGATE_RESCAN_CMD
  GOLDENGATE_CHECK_FALLBACK_CMD

Real execution requires:
  GOLDENGATE_BAD_SLOT_CONFIRM=INSTALL_AND_TEST_BAD_SLOT_FALLBACK
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) gg_die "unknown argument: $1" ;;
  esac
done

gg_require_execute_confirm GOLDENGATE_BAD_SLOT_CONFIRM INSTALL_AND_TEST_BAD_SLOT_FALLBACK "${DRY_RUN}"
for name in GOLDENGATE_PREPARE_BAD_SLOT_CMD GOLDENGATE_CHECK_GOLDEN_CMD GOLDENGATE_BOOT_BAD_SLOT_CMD GOLDENGATE_RESCAN_CMD GOLDENGATE_CHECK_FALLBACK_CMD; do
  gg_require_command_env "${name}"
done

gg_header "goldengate.gate_bad_slot_fallback.v1"
printf 'dry_run=%s\n' "${DRY_RUN}"
gg_run_step "${DRY_RUN}" "prepare-bad-slot" "${GOLDENGATE_PREPARE_BAD_SLOT_CMD}"
gg_run_step "${DRY_RUN}" "check-golden-before-bad-slot" "${GOLDENGATE_CHECK_GOLDEN_CMD}"
gg_run_step "${DRY_RUN}" "boot-bad-slot" "${GOLDENGATE_BOOT_BAD_SLOT_CMD}"
gg_run_step "${DRY_RUN}" "transport-rescan-after-fallback" "${GOLDENGATE_RESCAN_CMD}"
gg_run_step "${DRY_RUN}" "check-fallback-reason" "${GOLDENGATE_CHECK_FALLBACK_CMD}"
printf 'goldengate_gate_bad_slot_fallback_pass=1\n'

