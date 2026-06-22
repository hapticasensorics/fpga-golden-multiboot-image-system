#!/usr/bin/env bash
set -euo pipefail

PCI_VENDOR="${PCI_VENDOR:-0x10ee}"
PCI_DEVICE="${PCI_DEVICE:-0x7011}"
XDMA_SERVICE="${XDMA_SERVICE:-haptica-xdma-load}"
HW_SERVICE="${HW_SERVICE:-haptica-hw-server}"
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-180}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

if [[ "${DRY_RUN}" != "1" && "${GOLDENGATE_LITEFURY_RESCAN_CONFIRM:-}" != "CONTROLLED_RESCAN" ]]; then
  printf 'error: real rescan requires GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN\n' >&2
  exit 1
fi

find_devices() {
  local dev
  for dev in /sys/bus/pci/devices/*; do
    [[ -r "${dev}/vendor" && -r "${dev}/device" ]] || continue
    if [[ "$(cat "${dev}/vendor")" == "${PCI_VENDOR}" && "$(cat "${dev}/device")" == "${PCI_DEVICE}" ]]; then
      basename "${dev}"
    fi
  done
}

printf 'litefury_pcie_rescan_start_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'pci_vendor=%s\n' "${PCI_VENDOR}"
printf 'pci_device=%s\n' "${PCI_DEVICE}"
printf 'xdma_service=%s\n' "${XDMA_SERVICE}"
printf 'dry_run=%s\n' "${DRY_RUN}"

if [[ "${DRY_RUN}" == "1" ]]; then
  printf '+ stop XDMA, remove matching endpoint, rescan PCIe, restart XDMA\n'
  exit 0
fi

sudo -n systemctl stop "${XDMA_SERVICE}" >/dev/null 2>&1 || true
if lsmod | awk '$1 == "xdma" { found=1 } END { exit !found }'; then
  sudo -n modprobe -r xdma >/dev/null 2>&1 || sudo -n rmmod xdma >/dev/null 2>&1 || true
fi

for pci_addr in $(find_devices); do
  printf 'remove_pci_device=%s\n' "${pci_addr}"
  echo 1 | sudo -n tee "/sys/bus/pci/devices/${pci_addr}/remove" >/dev/null || true
done

sleep 1
echo 1 | sudo -n tee /sys/bus/pci/rescan >/dev/null

deadline=$((SECONDS + WAIT_TIMEOUT_SECONDS))
while (( SECONDS < deadline )); do
  devices="$(find_devices | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  if [[ -n "${devices}" ]]; then
    printf 'rescanned_devices=%s\n' "${devices}"
    sudo -n systemctl reset-failed "${XDMA_SERVICE}" >/dev/null 2>&1 || true
    sudo -n systemctl start "${XDMA_SERVICE}"
    break
  fi
  echo 1 | sudo -n tee /sys/bus/pci/rescan >/dev/null
  sleep 2
done

deadline=$((SECONDS + WAIT_TIMEOUT_SECONDS))
while (( SECONDS < deadline )); do
  xdma_state="$(systemctl is-active "${XDMA_SERVICE}" 2>/dev/null || true)"
  hw_state="$(systemctl is-active "${HW_SERVICE}" 2>/dev/null || true)"
  if [[ "${xdma_state}" == "active" && "${hw_state}" == "active" && -e /dev/xdma0_user ]]; then
    printf 'litefury_pcie_rescan_pass=1\n'
    exit 0
  fi
  sleep 2
done

printf 'litefury_pcie_rescan_pass=0\n'
exit 1

