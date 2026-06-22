#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/litefury-common.sh"

SLOT=""
IMAGE=""
ADDRESS=""
VERIFY=1
VERIFY_ONLY=0
DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage:
  litefury-flash-image.sh --image PATH (--slot A|B|golden | --address HEX)
      [--verify-only|--no-verify] [--dry-run|--execute]

Programs or verifies a LiteFury SPI flash image through a target-provided backend command.
This script owns the safety ceremony: address selection, golden-region refusal,
image hashing, backend invocation, and optional readback verification.

Backend command contract:
  LITEFURY_FLASH_PROGRAM_CMD IMAGE_PATH ADDRESS_HEX SIZE_BYTES
  LITEFURY_FLASH_VERIFY_CMD  IMAGE_PATH ADDRESS_HEX SIZE_BYTES
  LITEFURY_FLASH_READ_CMD    ADDRESS_HEX SIZE_BYTES OUTPUT_PATH

If `LITEFURY_FLASH_VERIFY_CMD` is present, verify-only mode uses it directly.
Otherwise the script falls back to `LITEFURY_FLASH_READ_CMD` and compares the
readback SHA-256 locally.

Real execution requires:
  GOLDENGATE_LITEFURY_FLASH_CONFIRM=PROGRAM_LITEFURY_FLASH

Programming the permanent golden address additionally requires:
  GOLDENGATE_LITEFURY_GOLDEN_REFRESH_CONFIRM=REFRESH_PERMANENT_GOLDEN

The backend may be a PCIe SPI bridge, vendor tool wrapper, or lab-specific
programmer. Keep it outside this script so the target pack stays auditable.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slot) SLOT="${2:-}"; shift 2 ;;
    --image) IMAGE="${2:-}"; shift 2 ;;
    --address) ADDRESS="${2:-}"; shift 2 ;;
    --verify-only) VERIFY_ONLY=1; VERIFY=1; shift ;;
    --no-verify) VERIFY=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) lf_die "unknown argument: $1" ;;
  esac
done

[[ -n "${IMAGE}" ]] || lf_die "--image is required"
[[ -f "${IMAGE}" ]] || lf_die "image not found: ${IMAGE}"

if [[ -n "${SLOT}" && -n "${ADDRESS}" ]]; then
  lf_die "use --slot or --address, not both"
fi

case "${SLOT}" in
  A|a) ADDRESS="${LITEFURY_SLOT_A_BASE:-0x680000}" ;;
  B|b) ADDRESS="${LITEFURY_SLOT_B_BASE:-0xa80000}" ;;
  golden|GOLDEN) ADDRESS="${LITEFURY_GOLDEN_FLASH_BASE:-0x0}" ;;
  "") ;;
  *) lf_die "slot must be A, B, or golden" ;;
esac

[[ -n "${ADDRESS}" ]] || lf_die "--slot or --address is required"
address_dec="$(lf_parse_num "${ADDRESS}")"
address_hex="$(printf '0x%06x' "${address_dec}")"
protected_limit_dec="$(lf_parse_num "${LITEFURY_PROTECTED_GOLDEN_LIMIT:-0x400000}")"
image_size="$(wc -c < "${IMAGE}" | tr -d ' ')"
image_sha="$(lf_sha256_file "${IMAGE}")"
LITEFURY_FLASH_PROGRAM_CMD="${LITEFURY_FLASH_PROGRAM_CMD:-${script_dir}/litefury-spi-program.sh}"

printf 'litefury_flash_image_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'image=%s\n' "${IMAGE}"
printf 'image_size_bytes=%s\n' "${image_size}"
printf 'image_sha256=%s\n' "${image_sha}"
printf 'address=%s\n' "${address_hex}"
printf 'verify=%s\n' "${VERIFY}"
printf 'verify_only=%s\n' "${VERIFY_ONLY}"
printf 'dry_run=%s\n' "${DRY_RUN}"

if (( address_dec < protected_limit_dec )); then
  printf 'target_region=golden_or_protected\n'
  [[ "${GOLDENGATE_LITEFURY_GOLDEN_REFRESH_CONFIRM:-}" == "REFRESH_PERMANENT_GOLDEN" || "${DRY_RUN}" == "1" ]] ||
    lf_die "protected golden refresh requires GOLDENGATE_LITEFURY_GOLDEN_REFRESH_CONFIRM=REFRESH_PERMANENT_GOLDEN"
else
  printf 'target_region=app_slot\n'
fi

if [[ "${VERIFY_ONLY}" != "1" && "${DRY_RUN}" != "1" ]]; then
  [[ "${GOLDENGATE_LITEFURY_FLASH_CONFIRM:-}" == "PROGRAM_LITEFURY_FLASH" ]] ||
    lf_die "real flash requires GOLDENGATE_LITEFURY_FLASH_CONFIRM=PROGRAM_LITEFURY_FLASH"
fi

if [[ "${VERIFY_ONLY}" != "1" ]]; then
  printf '+ %s %q %s %s\n' "${LITEFURY_FLASH_PROGRAM_CMD}" "${IMAGE}" "${address_hex}" "${image_size}"
  if [[ "${DRY_RUN}" != "1" ]]; then
    "${LITEFURY_FLASH_PROGRAM_CMD}" "${IMAGE}" "${address_hex}" "${image_size}"
  fi
fi

if [[ "${VERIFY}" == "1" ]]; then
  LITEFURY_FLASH_VERIFY_CMD="${LITEFURY_FLASH_VERIFY_CMD:-${script_dir}/litefury-spi-verify.sh}"
  if [[ -n "${LITEFURY_FLASH_VERIFY_CMD:-}" ]]; then
    printf '+ %s %q %s %s\n' "${LITEFURY_FLASH_VERIFY_CMD}" "${IMAGE}" "${address_hex}" "${image_size}"
    if [[ "${DRY_RUN}" != "1" ]]; then
      "${LITEFURY_FLASH_VERIFY_CMD}" "${IMAGE}" "${address_hex}" "${image_size}"
    fi
  else
    if [[ "${DRY_RUN}" != "1" ]]; then
      [[ -n "${LITEFURY_FLASH_READ_CMD:-}" ]] ||
        lf_die "missing LITEFURY_FLASH_VERIFY_CMD or LITEFURY_FLASH_READ_CMD for verification"
    fi
    readback="$(mktemp)"
    trap 'rm -f "${readback}"' EXIT
    printf '+ %s %s %s %q\n' "${LITEFURY_FLASH_READ_CMD:-<flash-read-backend>}" "${address_hex}" "${image_size}" "${readback}"
    if [[ "${DRY_RUN}" != "1" ]]; then
      "${LITEFURY_FLASH_READ_CMD}" "${address_hex}" "${image_size}" "${readback}"
      readback_sha="$(lf_sha256_file "${readback}")"
      printf 'readback_sha256=%s\n' "${readback_sha}"
      [[ "${readback_sha}" == "${image_sha}" ]] ||
        lf_die "flash readback SHA mismatch"
    fi
  fi
fi

printf 'litefury_flash_image_done=1\n'
