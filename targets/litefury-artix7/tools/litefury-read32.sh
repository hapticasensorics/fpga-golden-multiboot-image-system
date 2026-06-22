#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
offset="${1:-}"
[[ -n "${offset}" ]] || lf_die "usage: $0 OFFSET"
offset_dec="$(lf_parse_num "${offset}")"
word="$(lf_read32 "${device}" "${offset_dec}")"
printf 'offset=%s\n' "$(lf_fmt_hex "${offset_dec}")"
printf 'word=0x%s\n' "${word}"

