#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${target_dir}/../.." && pwd)"

PART="${LITEFURY_VIVADO_PART:-xc7a100tfgg484-2L}"
TOP="${LITEFURY_GOLDEN_TOP:-litefury_artix7_goldengate_top}"
OUT="${LITEFURY_GOLDEN_BUILD_DIR:-${repo_root}/build/litefury-goldengate}"
XDC="${LITEFURY_GOLDEN_XDC:-${target_dir}/constraints/litefury-goldengate-shell.xdc}"
DRY_RUN=1
RUN_SYNTH=0
RUN_IMPL=0

usage() {
  cat <<'USAGE'
Usage:
  build-golden.sh [--dry-run|--execute] [--run-synth] [--run-impl]
      [--part PART] [--top TOP] [--out DIR] [--xdc PATH]

Builds the LiteFury Artix-7 GoldenGate target with Vivado.

Defaults:
  part: xc7a100tfgg484-2L
  top:  litefury_artix7_goldengate_top

Dry-run prints the exact Vivado command without invoking Vivado.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    --run-synth) RUN_SYNTH=1; shift ;;
    --run-impl) RUN_SYNTH=1; RUN_IMPL=1; shift ;;
    --part) PART="${2:-}"; shift 2 ;;
    --top) TOP="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --xdc) XDC="${2:-}"; shift 2 ;;
    -h|--help|help) usage; exit 0 ;;
    *) printf 'error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

cmd=(vivado -mode batch -source "${script_dir}/build-golden.tcl" -tclargs
  -part "${PART}"
  -top "${TOP}"
  -out "${OUT}"
  -xdc "${XDC}")

if [[ "${RUN_IMPL}" == "1" ]]; then
  cmd+=(-run-impl)
elif [[ "${RUN_SYNTH}" == "1" ]]; then
  cmd+=(-run-synth)
fi

printf 'litefury_build_golden_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repo_root=%s\n' "${repo_root}"
printf 'part=%s\n' "${PART}"
printf 'top=%s\n' "${TOP}"
printf 'out=%s\n' "${OUT}"
printf 'xdc=%s\n' "${XDC}"
printf 'dry_run=%s\n' "${DRY_RUN}"
printf '+'
printf ' %q' "${cmd[@]}"
printf '\n'

if [[ "${DRY_RUN}" == "1" ]]; then
  exit 0
fi

command -v vivado >/dev/null 2>&1 || {
  printf 'error: vivado not found in PATH\n' >&2
  exit 1
}

"${cmd[@]}"
