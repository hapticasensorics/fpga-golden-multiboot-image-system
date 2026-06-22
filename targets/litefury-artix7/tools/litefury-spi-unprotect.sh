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
[[ $# -eq 2 ]] || { echo "usage: $0 [--dry-run] BASE_HEX LIMIT_HEX" >&2; exit 2; }

if [[ "${DRY_RUN}" == "1" ]]; then
  tool="${LITEFURY_SPI_PROTECT_TOOL:-<haptica-spi-protect>}"
else
  tool="$(lf_spi_protect_tool)"
fi
range_args=()
while IFS= read -r arg; do
  range_args+=("${arg}")
done < <(lf_spi_protect_range_args "$1" "$2")

printf 'litefury_spi_unprotect_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'protect_tool=%s\n' "${tool}"
printf 'warning=global_all_sector_ppb_erase\n'
printf 'dry_run=%s\n' "${DRY_RUN}"

if [[ "${DRY_RUN}" == "1" ]]; then
  lf_spi_protect_run "${DRY_RUN}" env HAPTICA_LITEFURY_SPI_PROTECT_CONFIRM=ERASE_ALL_PPB_FOR_GOLDEN_REFRESH "${tool}" --erase-all-ppb "${range_args[@]}"
else
  HAPTICA_LITEFURY_SPI_PROTECT_CONFIRM=ERASE_ALL_PPB_FOR_GOLDEN_REFRESH \
    lf_spi_protect_run "${DRY_RUN}" env HAPTICA_LITEFURY_SPI_PROTECT_CONFIRM=ERASE_ALL_PPB_FOR_GOLDEN_REFRESH "${tool}" --erase-all-ppb "${range_args[@]}"
fi
