#!/usr/bin/env bash

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  source_path="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  source_path="${(%):-%x}"
else
  source_path="$0"
fi

target_dir="$(cd "$(dirname "${source_path}")/.." && pwd)"
repo_root="$(cd "${target_dir}/../.." && pwd)"
tools_dir="${target_dir}/tools"

export LITEFURY_USER_DEVICE="${LITEFURY_USER_DEVICE:-/dev/xdma0_user}"
export LITEFURY_GOLDEN_BASE="${LITEFURY_GOLDEN_BASE:-0x7000}"
export LITEFURY_APP_BASE="${LITEFURY_APP_BASE:-0x6000}"
export LITEFURY_SLOT_A_PAYLOAD="${LITEFURY_SLOT_A_PAYLOAD:-0x680100}"
export LITEFURY_SLOT_B_PAYLOAD="${LITEFURY_SLOT_B_PAYLOAD:-0xa80100}"

export GOLDENGATE_CHECK_GOLDEN_CMD="${GOLDENGATE_CHECK_GOLDEN_CMD:-${tools_dir}/litefury-check-golden.sh}"
export GOLDENGATE_WARMBOOT_APP_CMD="${GOLDENGATE_WARMBOOT_APP_CMD:-GOLDENGATE_LITEFURY_WARMBOOT_CONFIRM=JUMP_TO_VERIFIED_SLOT ${tools_dir}/litefury-warmboot-slot.sh A}"
export GOLDENGATE_RESCAN_CMD="${GOLDENGATE_RESCAN_CMD:-GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN ${tools_dir}/litefury-pcie-rescan.sh}"
export GOLDENGATE_CHECK_APP_CMD="${GOLDENGATE_CHECK_APP_CMD:-${tools_dir}/litefury-check-app.sh}"
export GOLDENGATE_RETURN_GOLDEN_CMD="${GOLDENGATE_RETURN_GOLDEN_CMD:-GOLDENGATE_LITEFURY_RETURN_CONFIRM=RETURN_TO_GOLDEN ${tools_dir}/litefury-return-golden.sh}"
export GOLDENGATE_ARM_WATCHDOG_CMD="${GOLDENGATE_ARM_WATCHDOG_CMD:-GOLDENGATE_LITEFURY_WATCHDOG_CONFIRM=ARM_WATCHDOG ${tools_dir}/litefury-watchdog.sh arm}"
export GOLDENGATE_PET_WATCHDOG_CMD="${GOLDENGATE_PET_WATCHDOG_CMD:-${tools_dir}/litefury-watchdog.sh pet}"
export GOLDENGATE_CHECK_WATCHDOG_RETURN_CMD="${GOLDENGATE_CHECK_WATCHDOG_RETURN_CMD:-${tools_dir}/litefury-check-golden.sh}"
export GOLDENGATE_HEALTH_CMD="${GOLDENGATE_HEALTH_CMD:-${tools_dir}/litefury-health.sh}"

export GOLDENGATE_PROTECT_STATUS_CMD="${GOLDENGATE_PROTECT_STATUS_CMD:-${tools_dir}/litefury-protect-golden.sh --status}"
export GOLDENGATE_PROTECT_GOLDEN_CMD="${GOLDENGATE_PROTECT_GOLDEN_CMD:-GOLDENGATE_LITEFURY_PROTECT_CONFIRM=CHANGE_GOLDEN_FLASH_PROTECTION ${tools_dir}/litefury-protect-golden.sh --protect}"
export GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD="${GOLDENGATE_VERIFY_GOLDEN_PROTECTED_CMD:-${tools_dir}/litefury-protect-golden.sh --verify}"
export GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD="${GOLDENGATE_UNPROTECT_FOR_REFRESH_CMD:-GOLDENGATE_LITEFURY_PROTECT_CONFIRM=CHANGE_GOLDEN_FLASH_PROTECTION ${tools_dir}/litefury-protect-golden.sh --unprotect-for-refresh}"
if [[ -z "${GOLDENGATE_PROGRAM_GOLDEN_CMD:-}" ]]; then
  export GOLDENGATE_PROGRAM_GOLDEN_CMD="GOLDENGATE_LITEFURY_FLASH_CONFIRM=PROGRAM_LITEFURY_FLASH GOLDENGATE_LITEFURY_GOLDEN_REFRESH_CONFIRM=REFRESH_PERMANENT_GOLDEN ${tools_dir}/litefury-flash-image.sh --slot golden --image \${LITEFURY_GOLDEN_IMAGE:?set_LITEFURY_GOLDEN_IMAGE} --no-verify"
fi
if [[ -z "${GOLDENGATE_VERIFY_GOLDEN_IMAGE_CMD:-}" ]]; then
  export GOLDENGATE_VERIFY_GOLDEN_IMAGE_CMD="${tools_dir}/litefury-flash-image.sh --slot golden --image \${LITEFURY_GOLDEN_IMAGE:?set_LITEFURY_GOLDEN_IMAGE} --verify-only"
fi

export GOLDENGATE_APP_CYCLE_SLOT_A_CMD="${GOLDENGATE_APP_CYCLE_SLOT_A_CMD:-GOLDENGATE_LITEFURY_CYCLE_CONFIRM=RUN_SLOT_CYCLE ${tools_dir}/litefury-cycle-slot.sh A}"
export GOLDENGATE_APP_CYCLE_SLOT_B_CMD="${GOLDENGATE_APP_CYCLE_SLOT_B_CMD:-GOLDENGATE_LITEFURY_CYCLE_CONFIRM=RUN_SLOT_CYCLE ${tools_dir}/litefury-cycle-slot.sh B}"

export GOLDENGATE_PREPARE_SLOT_A_CMD="${GOLDENGATE_PREPARE_SLOT_A_CMD:-${tools_dir}/litefury-slot-plan.sh}"
export GOLDENGATE_PREPARE_SLOT_B_CMD="${GOLDENGATE_PREPARE_SLOT_B_CMD:-${tools_dir}/litefury-slot-plan.sh}"
export GOLDENGATE_ROOT="${GOLDENGATE_ROOT:-${repo_root}}"
