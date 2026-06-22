#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"
source "${script_dir}/litefury-spi-protect-common.sh"

DRY_RUN="${LITEFURY_SPI_DRY_RUN:-0}"
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi
[[ $# -eq 3 ]] || { echo "usage: $0 [--dry-run] BASE_HEX LIMIT_HEX LOCK_PPB_0_OR_1" >&2; exit 2; }

if [[ "${DRY_RUN}" == "1" ]]; then
  tool="${LITEFURY_SPI_PROTECT_TOOL:-<haptica-spi-protect>}"
else
  tool="$(lf_spi_protect_tool)"
fi
range_args=()
while IFS= read -r arg; do
  range_args+=("${arg}")
done < <(lf_spi_protect_range_args "$1" "$2")
lock_ppb="$3"
[[ "${lock_ppb}" == "0" || "${lock_ppb}" == "1" ]] || lf_die "LOCK_PPB must be 0 or 1"

cmd=("${tool}" --protect-ppb "${range_args[@]}")
if [[ "${lock_ppb}" == "1" ]]; then
  cmd+=(--lock-ppb)
fi

printf 'litefury_spi_protect_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'protect_tool=%s\n' "${tool}"
printf 'lock_ppb=%s\n' "${lock_ppb}"
printf 'dry_run=%s\n' "${DRY_RUN}"

if [[ "${DRY_RUN}" == "1" ]]; then
  lf_spi_protect_run "${DRY_RUN}" env HAPTICA_LITEFURY_SPI_PROTECT_CONFIRM=LOCK_GOLDEN_FLASH_REGION "${cmd[@]}"
else
  HAPTICA_LITEFURY_SPI_PROTECT_CONFIRM=LOCK_GOLDEN_FLASH_REGION \
    lf_spi_protect_run "${DRY_RUN}" env HAPTICA_LITEFURY_SPI_PROTECT_CONFIRM=LOCK_GOLDEN_FLASH_REGION "${cmd[@]}"
fi
