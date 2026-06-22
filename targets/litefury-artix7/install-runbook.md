# LiteFury / Framework Install Runbook

This runbook is the target-specific install path for the LiteFury Artix-7 M.2
FPGA in a Framework 13 appliance. The board-neutral GoldenGate contracts live
at the repo root; this file is allowed to name LiteFury, XDMA, Framework Linux,
S25FL flash protection, and the proven slot addresses directly.

The pack is not yet a one-command installer for a fresh owner, but the flash
program/protect adapters now exist. The remaining external dependency is the
actual LiteFury SPI bridge binary and S25FL PPB protection helper on the
Framework host.

## 0. Hardware Assumptions

- LiteFury M.2 FPGA installed in a Framework 13
- Framework Linux can see the PCIe endpoint after golden boots
- `/dev/xdma0_user` exists after XDMA service starts
- SPI flash is 16 MiB with golden at `0x0`
- slot A is `0x680000`, payload `0x680100`
- slot B is `0xa80000`, payload `0xa80100`

## 1. First Golden Install

Use JTAG or vendor tooling only for the first permanent golden install.

```text
build golden
program flash address 0x0
coldboot the board
verify golden identity over PCIe
```

After this point, app-slot development should use GoldenGate over PCIe rather
than routine JTAG.

## 2. Install Host Tools

Intended final layout:

```text
/opt/goldengate/fpga-golden-multiboot-image-system
/opt/goldengate/bin/litefury-read32
/opt/goldengate/bin/litefury-write32
/opt/goldengate/bin/litefury-check-golden
/opt/goldengate/bin/litefury-warmboot-slot
/opt/goldengate/bin/spi-loader
/opt/goldengate/bin/haptica-spi-protect
```

Install dry-run:

```bash
targets/litefury-artix7/tools/litefury-install-framework-host.sh --dry-run
```

Install for real:

```bash
GOLDENGATE_LITEFURY_INSTALL_CONFIRM=INSTALL_FRAMEWORK_HOST_TOOLS \
  targets/litefury-artix7/tools/litefury-install-framework-host.sh --execute
```

Current development usage from a checkout:

```bash
cd /opt/goldengate/fpga-golden-multiboot-image-system
. targets/litefury-artix7/tools/litefury-gate-env.sh
```

## 3. Prove Coldboot Golden

```bash
targets/litefury-artix7/tools/litefury-check-golden.sh
```

Or through the generic gate:

```bash
. targets/litefury-artix7/tools/litefury-gate-env.sh
tools/gate-coldboot.sh --skip-thermal
```

Read live health/temperature:

```bash
targets/litefury-artix7/tools/litefury-health.sh
```

## 4. Prepare An App Manifest

```bash
targets/litefury-artix7/tools/litefury-create-app-manifest.sh app.bit A \
  > app.slot-a.manifest.json
```

Only set `verified=true` after app-slot flash readback matches the image hash.

## 5. Program And Verify An App Slot

The target pack includes wrappers for the LiteFury SPI bridge. By default they
look for `spi-loader` in `/opt/goldengate/bin`, `/opt/haptica/litefury/bin`, or
`$PATH`. If your Framework install keeps it elsewhere, set:

```bash
export LITEFURY_SPI_LOADER=/absolute/path/to/spi-loader
```

The adapter uses the proven live shape:

```text
device   /dev/xdma0_user
SPI base 0x10000
target   0
program  spi-loader -d DEVICE -r SPI_BASE -a ADDRESS -t TARGET -f IMAGE -l SIZE -v
verify   spi-loader -d DEVICE -r SPI_BASE -a ADDRESS -t TARGET -f IMAGE -l SIZE -c -v
```

Those defaults can be changed with `LITEFURY_SPI_DEVICE`,
`LITEFURY_SPI_BASE`, `LITEFURY_SPI_TARGET`, `LITEFURY_SPI_LOCK`,
`LITEFURY_SPI_LOCK_WAIT_SECONDS`, `LITEFURY_SPI_TIMEOUT_SECONDS`, and
`LITEFURY_SPI_USE_SUDO`.

Dry-run slot A:

```bash
targets/litefury-artix7/tools/litefury-flash-image.sh \
  --slot A --image app-slot-a.bin --dry-run
```

Program slot A:

```bash
GOLDENGATE_LITEFURY_FLASH_CONFIRM=PROGRAM_LITEFURY_FLASH \
  targets/litefury-artix7/tools/litefury-flash-image.sh \
    --slot A --image app-slot-a.bin --execute
```

## 6. Warmboot Slot A

```bash
GOLDENGATE_LITEFURY_WARMBOOT_CONFIRM=JUMP_TO_VERIFIED_SLOT \
  targets/litefury-artix7/tools/litefury-warmboot-slot.sh A

GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN \
  targets/litefury-artix7/tools/litefury-pcie-rescan.sh

targets/litefury-artix7/tools/litefury-check-app.sh
```

## 7. Return To Golden

```bash
GOLDENGATE_LITEFURY_RETURN_CONFIRM=RETURN_TO_GOLDEN \
  targets/litefury-artix7/tools/litefury-return-golden.sh

GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN \
  targets/litefury-artix7/tools/litefury-pcie-rescan.sh

targets/litefury-artix7/tools/litefury-check-golden.sh
```

## 8. Run The Full Cycle Gate

```bash
. targets/litefury-artix7/tools/litefury-gate-env.sh

GOLDENGATE_APP_CYCLE_CONFIRM=RUN_APP_CYCLE \
  tools/gate-app-cycle.sh --execute --max-temp-c 85
```

## 9. Protect Or Refresh Golden

During active development, protect without the volatile/global PPB lock. Save
locking for the final shipping posture.

The target pack includes S25FL PPB protection adapters. By default they look
for `haptica-spi-protect` in `/opt/goldengate/bin`,
`/opt/haptica/litefury/bin`, or `$PATH`. If your Framework install keeps it
elsewhere, set:

```bash
export LITEFURY_SPI_PROTECT_TOOL=/absolute/path/to/haptica-spi-protect
```

The PPB protection helper is target-specific to the LiteFury SPI flash. The
important policy is portable: protect golden during iteration without the
volatile PPB lock, and use `--lock-ppb` only for a final shipping freeze.

Protection status:

```bash
targets/litefury-artix7/tools/litefury-protect-golden.sh --status --dry-run
```

Generic gate binding:

```bash
. targets/litefury-artix7/tools/litefury-gate-env.sh
tools/gate-golden-protect.sh --status --dry-run
```

Permanent golden refresh uses the same backend plus `LITEFURY_GOLDEN_IMAGE`:

```bash
export LITEFURY_GOLDEN_IMAGE=golden.bin

GOLDENGATE_REFRESH_CONFIRM=REFRESH_PERMANENT_GOLDEN \
  tools/gate-protected-golden-refresh.sh --execute --max-temp-c 85
```

## Remaining Turnkey Work

- finish the LiteFury Vivado top-level
- package or document installation of `spi-loader`
- package or document installation of `haptica-spi-protect`
- add a live evidence bundle command
