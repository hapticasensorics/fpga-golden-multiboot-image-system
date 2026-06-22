#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${target_dir}/../.." && pwd)"

DEST_ROOT="${DEST_ROOT:-/opt/goldengate}"
BIN_DIR="${BIN_DIR:-${DEST_ROOT}/bin}"
REPO_DEST="${REPO_DEST:-${DEST_ROOT}/fpga-golden-multiboot-image-system}"
SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"
DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage:
  litefury-install-framework-host.sh [--dry-run|--execute]

Installs the GoldenGate LiteFury target tools onto the Framework Linux host.

Real execution requires:
  GOLDENGATE_LITEFURY_INSTALL_CONFIRM=INSTALL_FRAMEWORK_HOST_TOOLS

This installer copies scripts and systemd example files only. It does not enable
services, load XDMA, flash FPGA images, or mutate SPI flash.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --execute) DRY_RUN=0; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *) printf 'error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "${DRY_RUN}" != "1" && "${GOLDENGATE_LITEFURY_INSTALL_CONFIRM:-}" != "INSTALL_FRAMEWORK_HOST_TOOLS" ]]; then
  printf 'error: real install requires GOLDENGATE_LITEFURY_INSTALL_CONFIRM=INSTALL_FRAMEWORK_HOST_TOOLS\n' >&2
  exit 1
fi

run() {
  printf '+ %s\n' "$*"
  if [[ "${DRY_RUN}" != "1" ]]; then
    "$@"
  fi
}

printf 'litefury_install_framework_host_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repo_root=%s\n' "${repo_root}"
printf 'dest_root=%s\n' "${DEST_ROOT}"
printf 'bin_dir=%s\n' "${BIN_DIR}"
printf 'repo_dest=%s\n' "${REPO_DEST}"
printf 'dry_run=%s\n' "${DRY_RUN}"

run sudo install -d -m 0755 "${DEST_ROOT}" "${BIN_DIR}" "${REPO_DEST}" "${SYSTEMD_DIR}"

for tool in "${script_dir}"/*.sh; do
  name="$(basename "${tool}" .sh)"
  run sudo install -m 0755 "${tool}" "${BIN_DIR}/${name}"
done

run sudo install -d -m 0755 "${REPO_DEST}/targets/litefury-artix7"
run sudo cp -R "${repo_root}/docs" "${REPO_DEST}/"
run sudo cp -R "${repo_root}/specs" "${REPO_DEST}/"
run sudo cp -R "${repo_root}/rtl" "${REPO_DEST}/"
run sudo cp -R "${repo_root}/tools" "${REPO_DEST}/"
run sudo cp -R "${repo_root}/targets/litefury-artix7" "${REPO_DEST}/targets/"

for unit in "${target_dir}/systemd"/*.service.example; do
  [[ -f "${unit}" ]] || continue
  run sudo install -m 0644 "${unit}" "${SYSTEMD_DIR}/$(basename "${unit}")"
done

printf 'litefury_install_framework_host_done=1\n'
printf 'next_steps=review systemd .example files, adapt XDMA loader, then enable explicitly\n'

