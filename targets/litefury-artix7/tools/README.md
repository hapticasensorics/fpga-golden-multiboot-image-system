# LiteFury Target Tools

These scripts are the first target-specific binding layer for LiteFury Artix-7
inside a Framework 13 host.

They are meant to run on the Framework Linux host that owns `/dev/xdma0_user`.
Use SSH or another orchestration layer from a development machine if desired,
but keep the BAR reads/writes local to the Framework whenever possible.

## Scripts

| Script | Purpose |
|---|---|
| `litefury-read32.sh` | Read one little-endian 32-bit BAR word |
| `litefury-write32.sh` | Write one little-endian 32-bit BAR word |
| `litefury-check-golden.sh` | Require GoldenGate `GMB0` or legacy `LFGO` at the golden page |
| `litefury-check-app.sh` | Require GoldenGate `GAPP` or legacy app heartbeat page |
| `litefury-warmboot-slot.sh` | Trigger golden warmboot into slot A or B |
| `litefury-return-golden.sh` | Trigger app return to golden |
| `litefury-pcie-rescan.sh` | Controlled PCIe remove/rescan and XDMA reload |
| `litefury-cycle-slot.sh` | Warmboot a slot, prove app, return to golden, prove golden |
| `litefury-watchdog.sh` | Arm or pet the app watchdog |
| `litefury-health.sh` | Read `GHLT`/legacy health telemetry and print `temperature_c` |
| `litefury-flash-image.sh` | Program or verify an image through a target SPI backend |
| `litefury-protect-golden.sh` | Status/protect/unprotect/verify the golden flash region |
| `litefury-gate-env.sh` | Exports callback commands for root GoldenGate gate templates |
| `litefury-install-framework-host.sh` | Stages target tools onto Framework Linux |

## Default Addresses

```text
LITEFURY_USER_DEVICE=/dev/xdma0_user
LITEFURY_GOLDEN_BASE=0x7000
LITEFURY_APP_BASE=0x6000
LITEFURY_SLOT_A_PAYLOAD=0x680100
LITEFURY_SLOT_B_PAYLOAD=0xa80100
```

The tools intentionally accept both clean GoldenGate magic values and the
legacy names from the proven appliance. That keeps the target pack useful for
existing boards while the greenfield ABI moves toward generic `GMB0/GAPP/GRET`.

## Example

```bash
cd /opt/goldengate/fpga-golden-multiboot-image-system
. targets/litefury-artix7/tools/litefury-gate-env.sh

tools/gate-coldboot.sh --skip-thermal

GOLDENGATE_APP_CYCLE_CONFIRM=RUN_APP_CYCLE \
  tools/gate-app-cycle.sh --execute --max-temp-c 85
```

Install dry-run:

```bash
targets/litefury-artix7/tools/litefury-install-framework-host.sh --dry-run
```

Flash backend dry-run:

```bash
targets/litefury-artix7/tools/litefury-flash-image.sh \
  --slot A --image app-slot-a.bin --dry-run
```

Live flash programming requires target backend commands:

```text
LITEFURY_FLASH_PROGRAM_CMD IMAGE_PATH ADDRESS_HEX SIZE_BYTES
LITEFURY_FLASH_READ_CMD    ADDRESS_HEX SIZE_BYTES OUTPUT_PATH
```

Golden protection similarly delegates to backend commands:

```text
LITEFURY_FLASH_PROTECT_STATUS_CMD BASE_HEX LIMIT_HEX
LITEFURY_FLASH_PROTECT_CMD        BASE_HEX LIMIT_HEX LOCK_PPB_0_OR_1
LITEFURY_FLASH_UNPROTECT_CMD      BASE_HEX LIMIT_HEX
LITEFURY_FLASH_VERIFY_PROTECT_CMD BASE_HEX LIMIT_HEX
```

This split is deliberate. The target pack owns the safe ceremony and evidence;
the board installation binds those commands to the actual LiteFury SPI bridge.

## Safety

Mutating commands require explicit confirmation environment variables for live
execution. Dry-run modes can be used without touching hardware.
