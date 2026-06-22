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
| `litefury-spi-program.sh` | LiteFury SPI-loader adapter for image program + verify |
| `litefury-spi-verify.sh` | LiteFury SPI-loader adapter for verify-only compare |
| `litefury-spi-protect-status.sh` | S25FL PPB protection status adapter |
| `litefury-spi-protect.sh` | S25FL PPB protect adapter for the golden range |
| `litefury-spi-unprotect.sh` | S25FL PPB erase adapter for golden refresh |
| `litefury-spi-verify-protect.sh` | S25FL PPB verify adapter for gate use |
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

This target pack ships LiteFury backend adapters. By default they look for the
LiteFury `spi-loader` binary in:

```text
/opt/goldengate/bin/spi-loader
/opt/haptica/litefury/bin/spi-loader
$PATH
```

Override with `LITEFURY_SPI_LOADER=/path/to/spi-loader` if your install differs.
The live adapter command contract remains:

```text
litefury-spi-program.sh IMAGE_PATH ADDRESS_HEX SIZE_BYTES
litefury-spi-verify.sh  IMAGE_PATH ADDRESS_HEX SIZE_BYTES
```

Golden protection uses a second adapter around the S25FL PPB helper. By default
it looks for:

```text
/opt/goldengate/bin/haptica-spi-protect
/opt/haptica/litefury/bin/haptica-spi-protect
$PATH
```

Override with `LITEFURY_SPI_PROTECT_TOOL=/path/to/haptica-spi-protect` if your
install differs. The adapter command contract is:

```text
litefury-spi-protect-status.sh BASE_HEX LIMIT_HEX
litefury-spi-protect.sh        BASE_HEX LIMIT_HEX LOCK_PPB_0_OR_1
litefury-spi-unprotect.sh      BASE_HEX LIMIT_HEX
litefury-spi-verify-protect.sh BASE_HEX LIMIT_HEX
```

This split is deliberate but not hand-wavy. The target pack owns the safe
ceremony, addresses, locks, confirmation prompts, and evidence. The underlying
board install only needs to provide the LiteFury SPI bridge binaries.

## Safety

Mutating commands require explicit confirmation environment variables for live
execution. Dry-run modes can be used without touching hardware.
