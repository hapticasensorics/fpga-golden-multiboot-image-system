#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../.." && pwd)"

export GOLDEN_LIMIT="${GOLDEN_LIMIT:-0x00400000}"
export UPDATE_REGION_END="${UPDATE_REGION_END:-0x01000000}"
export SLOT_A_BASE="${SLOT_A_BASE:-0x00680000}"
export SLOT_B_BASE="${SLOT_B_BASE:-0x00a80000}"
export SLOT_SIZE="${SLOT_SIZE:-0x00400000}"
export PAYLOAD_OFFSET="${PAYLOAD_OFFSET:-0x00000100}"
export ALIGN_MASK="${ALIGN_MASK:-0x000000ff}"

"${repo_root}/tools/slot-plan.sh"

