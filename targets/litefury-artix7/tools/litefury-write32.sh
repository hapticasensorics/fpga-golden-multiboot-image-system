#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

device="${LITEFURY_USER_DEVICE:-${lf_default_device}}"
offset="${1:-}"
value="${2:-}"
[[ -n "${offset}" && -n "${value}" ]] || lf_die "usage: $0 OFFSET VALUE"
offset_dec="$(lf_parse_num "${offset}")"
value_dec="$(lf_parse_num "${value}")"
lf_write32 "${device}" "${offset_dec}" "${value_dec}"
printf 'wrote_offset=%s\n' "$(lf_fmt_hex "${offset_dec}")"
printf 'wrote_value=%s\n' "$(lf_fmt_hex "${value_dec}")"

