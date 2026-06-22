#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

DRY_RUN="${LITEFURY_SPI_DRY_RUN:-0}"

usage() {
  cat <<'USAGE'
Usage:
  litefury-spi-program.sh [--dry-run] IMAGE_PATH ADDRESS_HEX SIZE_BYTES

GoldenGate backend adapter for programming LiteFury SPI flash through the RHS
`spi-loader` command.

Tool lookup:
  LITEFURY_SPI_LOADER
  /opt/goldengate/bin/spi-loader
  /opt/haptica/litefury/bin/spi-loader
  spi-loader from PATH

Environment:
  LITEFURY_SPI_DEVICE=/dev/xdma0_user
  LITEFURY_SPI_BASE=0x10000
  LITEFURY_SPI_TARGET=0
  LITEFURY_SPI_TIMEOUT_SECONDS=180
  LITEFURY_SPI_LOCK=/run/goldengate-litefury-spi.lock
USAGE
}

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

[[ $# -eq 3 ]] || { usage >&2; exit 2; }
IMAGE="$1"
ADDRESS="$2"
SIZE_BYTES="$3"

[[ -f "${IMAGE}" || "${DRY_RUN}" == "1" ]] || lf_die "image not found: ${IMAGE}"
lf_parse_num "${ADDRESS}" >/dev/null
lf_parse_num "${SIZE_BYTES}" >/dev/null

if [[ "${DRY_RUN}" == "1" ]]; then
  loader="${LITEFURY_SPI_LOADER:-<spi-loader>}"
else
  loader="$(lf_resolve_executable LITEFURY_SPI_LOADER \
    /opt/goldengate/bin/spi-loader \
    /opt/haptica/litefury/bin/spi-loader \
    spi-loader)"
fi

printf 'litefury_spi_program_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'image=%s\n' "${IMAGE}"
printf 'address=%s\n' "${ADDRESS}"
printf 'size_bytes=%s\n' "${SIZE_BYTES}"
printf 'spi_loader=%s\n' "${loader}"
printf 'spi_device=%s\n' "${lf_spi_device}"
printf 'spi_base=%s\n' "${lf_spi_base}"
printf 'spi_target=%s\n' "${lf_spi_target}"
printf 'dry_run=%s\n' "${DRY_RUN}"

lf_run_locked "${DRY_RUN}" "${lf_spi_timeout_seconds}" "${lf_spi_lock_wait_seconds}" \
  "${lf_spi_lock}" "${lf_spi_use_sudo}" \
  "${loader}" -d "${lf_spi_device}" -r "${lf_spi_base}" -a "${ADDRESS}" \
  -t "${lf_spi_target}" -f "${IMAGE}" -l "${SIZE_BYTES}" -v

printf 'litefury_spi_program_done=1\n'
