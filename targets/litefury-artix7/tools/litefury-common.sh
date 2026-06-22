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
  for candidate in "$@"; do
    [[ "${word,,}" == "${candidate,,}" ]] && return 0
  done
  return 1
}

lf_default_device="${LITEFURY_USER_DEVICE:-/dev/xdma0_user}"
lf_golden_base="${LITEFURY_GOLDEN_BASE:-0x7000}"
lf_app_base="${LITEFURY_APP_BASE:-0x6000}"
lf_slot_a_payload="${LITEFURY_SLOT_A_PAYLOAD:-0x680100}"
lf_slot_b_payload="${LITEFURY_SLOT_B_PAYLOAD:-0xa80100}"
lf_warmboot_flags="${LITEFURY_WARMBOOT_FLAGS:-0x3}"

