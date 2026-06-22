#!/usr/bin/env bash
set -euo pipefail

device="${DEVICE:-/dev/fpga_control0}"
base="${BASE_OFFSET:-0}"
boot_addr="${BOOT_ADDR:-}"
boot_flags="${BOOT_FLAGS:-1}"
confirm="${CONFIRM_WARMBOOT:-}"

[[ -n "${boot_addr}" ]] || {
  printf 'usage: BOOT_ADDR=0x00680100 CONFIRM_WARMBOOT=yes %s\n' "$0" >&2
  exit 2
}
[[ "${confirm}" == "yes" ]] || {
  printf 'refusing warmboot without CONFIRM_WARMBOOT=yes\n' >&2
  exit 2
}
[[ -e "${device}" ]] || {
  printf 'error: device not found: %s\n' "${device}" >&2
  exit 1
}

to_dec() {
  local value="$1"
  if [[ "${value}" =~ ^0x[0-9a-fA-F]+$ ]]; then
    printf '%u' "$((value))"
  else
    printf '%u' "${value}"
  fi
}

write32() {
  local offset="$1"
  local value="$2"
  local abs=$((base + offset))
  local dec_value
  dec_value="$(to_dec "${value}")"
  perl -e 'print pack("V", $ARGV[0])' "${dec_value}" |
    dd of="${device}" bs=1 seek="${abs}" conv=notrunc status=none
}

write32 0x130 0x00000001
write32 0x120 "${boot_addr}"
write32 0x124 "${boot_flags}"
write32 0x134 0xb00710ad

printf 'warmboot requested: boot_addr=%s boot_flags=%s device=%s\n' \
  "${boot_addr}" "${boot_flags}" "${device}"

