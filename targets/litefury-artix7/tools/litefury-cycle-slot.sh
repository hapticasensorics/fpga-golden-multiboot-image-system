#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dry_run=0
slot="${1:-A}"
if [[ "${slot}" == "--dry-run" ]]; then
  dry_run=1
  slot="${2:-A}"
fi

case "${slot}" in
  A|a|B|b) ;;
  *) printf 'error: usage: %s [--dry-run] A|B\n' "$0" >&2; exit 2 ;;
esac

if [[ "${dry_run}" != "1" && "${GOLDENGATE_LITEFURY_CYCLE_CONFIRM:-}" != "RUN_SLOT_CYCLE" ]]; then
  printf 'error: real slot cycle requires GOLDENGATE_LITEFURY_CYCLE_CONFIRM=RUN_SLOT_CYCLE\n' >&2
  exit 1
fi

printf 'litefury_cycle_slot_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'slot=%s\n' "${slot}"
printf 'dry_run=%s\n' "${dry_run}"

if [[ "${dry_run}" == "1" ]]; then
  "${script_dir}/litefury-warmboot-slot.sh" --dry-run "${slot}"
  "${script_dir}/litefury-pcie-rescan.sh" --dry-run
  printf '+ check app identity\n'
  printf '+ return to golden\n'
  "${script_dir}/litefury-pcie-rescan.sh" --dry-run
  printf '+ check golden identity\n'
  exit 0
fi

GOLDENGATE_LITEFURY_WARMBOOT_CONFIRM=JUMP_TO_VERIFIED_SLOT \
  "${script_dir}/litefury-warmboot-slot.sh" "${slot}"
GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN \
  "${script_dir}/litefury-pcie-rescan.sh"
"${script_dir}/litefury-check-app.sh"
GOLDENGATE_LITEFURY_RETURN_CONFIRM=RETURN_TO_GOLDEN \
  "${script_dir}/litefury-return-golden.sh"
GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN \
  "${script_dir}/litefury-pcie-rescan.sh"
"${script_dir}/litefury-check-golden.sh"
printf 'litefury_cycle_slot_pass=1\n'

