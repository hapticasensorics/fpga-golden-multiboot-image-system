#!/usr/bin/env bash

lf_spi_protect_tool() {
  lf_resolve_executable LITEFURY_SPI_PROTECT_TOOL \
    /opt/goldengate/bin/haptica-spi-protect \
    /opt/haptica/litefury/bin/haptica-spi-protect \
    haptica-spi-protect
}

lf_spi_protect_range_args() {
  local base="$1"
  local limit="$2"
  local base_dec
  local limit_dec
  local length_dec

  base_dec="$(lf_parse_num "${base}")"
  limit_dec="$(lf_parse_num "${limit}")"
  (( limit_dec > base_dec )) || lf_die "protected limit must exceed base"
  length_dec=$((limit_dec - base_dec))

  printf '%s\n' \
    "--device" "${lf_spi_device}" \
    "--spi-base" "${lf_spi_base}" \
    "--target" "${lf_spi_target}" \
    "--start" "$(lf_fmt_hex "${base_dec}")" \
    "--length" "$(lf_fmt_hex "${length_dec}")" \
    "--sector-size" "${LITEFURY_SPI_SECTOR_SIZE:-0x10000}"
}

lf_spi_protect_run() {
  local dry_run="$1"
  shift
  lf_run_locked "${dry_run}" "${LITEFURY_SPI_PROTECT_TIMEOUT_SECONDS:-30}" \
    "${lf_spi_lock_wait_seconds}" "${lf_spi_lock}" "${lf_spi_use_sudo}" "$@"
}
