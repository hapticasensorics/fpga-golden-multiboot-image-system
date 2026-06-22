#!/usr/bin/env bash

lf_die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

lf_parse_num() {
  local value="$1"
  if [[ "${value}" =~ ^0[xX][0-9a-fA-F]+$ ]]; then
    printf '%u' "$((value))"
  elif [[ "${value}" =~ ^[0-9]+$ ]]; then
    printf '%u' "${value}"
  else
    lf_die "invalid numeric value: ${value}"
  fi
}

lf_fmt_hex() {
  printf '0x%08x' "$1"
}

lf_require_device() {
  local device="$1"
  [[ -e "${device}" ]] || lf_die "device not found: ${device}"
}

lf_read32() {
  local device="$1"
  local offset_dec="$2"
  lf_require_device "${device}"
  dd if="${device}" bs=4 count=1 skip="${offset_dec}" iflag=skip_bytes 2>/dev/null |
    od -An -tx4 |
    tr -d ' \n'
}

lf_write32() {
  local device="$1"
  local offset_dec="$2"
  local value_dec="$3"
  lf_require_device "${device}"
  perl -e 'print pack("V", shift)' "$((value_dec))" |
    dd of="${device}" bs=4 count=1 seek="${offset_dec}" oflag=seek_bytes conv=notrunc 2>/dev/null
}

lf_word_is_one_of() {
  local word="$1"
  shift
  local candidate
  local word_lc
  local candidate_lc
  word_lc="$(printf '%s' "${word}" | tr '[:upper:]' '[:lower:]')"
  for candidate in "$@"; do
    candidate_lc="$(printf '%s' "${candidate}" | tr '[:upper:]' '[:lower:]')"
    [[ "${word_lc}" == "${candidate_lc}" ]] && return 0
  done
  return 1
}

lf_sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${path}" | awk '{print $1}'
  else
    lf_die "sha256sum or shasum is required"
  fi
}

lf_resolve_executable() {
  local env_name="$1"
  shift
  local value="${!env_name:-}"
  local candidate
  if [[ -n "${value}" ]]; then
    [[ -x "${value}" ]] || lf_die "${env_name} is not executable: ${value}"
    printf '%s\n' "${value}"
    return 0
  fi
  for candidate in "$@"; do
    if [[ "${candidate}" == */* ]]; then
      if [[ -x "${candidate}" ]]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
    elif command -v "${candidate}" >/dev/null 2>&1; then
      command -v "${candidate}"
      return 0
    fi
  done
  lf_die "could not find executable for ${env_name}; tried: $*"
}

lf_run_locked() {
  local dry_run="$1"
  local timeout_seconds="$2"
  local lock_wait_seconds="$3"
  local lock_path="$4"
  local use_sudo="$5"
  shift 5

  local cmd=(timeout --kill-after=2s "${timeout_seconds}s" flock -w "${lock_wait_seconds}" "${lock_path}" "$@")
  if [[ "${use_sudo}" == "1" ]]; then
    cmd=(sudo -n "${cmd[@]}")
  fi
  printf '+'
  printf ' %q' "${cmd[@]}"
  printf '\n'
  if [[ "${dry_run}" != "1" ]]; then
    "${cmd[@]}"
  fi
}

lf_default_device="${LITEFURY_USER_DEVICE:-/dev/xdma0_user}"
lf_golden_base="${LITEFURY_GOLDEN_BASE:-0x7000}"
lf_app_base="${LITEFURY_APP_BASE:-0x6000}"
lf_slot_a_payload="${LITEFURY_SLOT_A_PAYLOAD:-0x680100}"
lf_slot_b_payload="${LITEFURY_SLOT_B_PAYLOAD:-0xa80100}"
lf_warmboot_flags="${LITEFURY_WARMBOOT_FLAGS:-0x3}"
lf_spi_device="${LITEFURY_SPI_DEVICE:-${lf_default_device}}"
lf_spi_base="${LITEFURY_SPI_BASE:-0x10000}"
lf_spi_target="${LITEFURY_SPI_TARGET:-0}"
lf_spi_lock="${LITEFURY_SPI_LOCK:-/run/goldengate-litefury-spi.lock}"
lf_spi_lock_wait_seconds="${LITEFURY_SPI_LOCK_WAIT_SECONDS:-5}"
lf_spi_timeout_seconds="${LITEFURY_SPI_TIMEOUT_SECONDS:-180}"
lf_spi_use_sudo="${LITEFURY_SPI_USE_SUDO:-1}"
