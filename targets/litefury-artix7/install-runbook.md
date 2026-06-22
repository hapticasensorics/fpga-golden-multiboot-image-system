# LiteFury / Framework Install Runbook

This runbook is the shape of the eventual turnkey install. Some commands are
already present in this target pack; flash programming and the final Vivado
top-level wrapper still need to be completed before this becomes one-command
turnkey.

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

## 4. Prepare An App Manifest

```bash
targets/litefury-artix7/tools/litefury-create-app-manifest.sh app.bit A \
  > app.slot-a.manifest.json
```

Only set `verified=true` after app-slot flash readback matches the image hash.

## 5. Warmboot Slot A

```bash
GOLDENGATE_LITEFURY_WARMBOOT_CONFIRM=JUMP_TO_VERIFIED_SLOT \
  targets/litefury-artix7/tools/litefury-warmboot-slot.sh A

GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN \
  targets/litefury-artix7/tools/litefury-pcie-rescan.sh

targets/litefury-artix7/tools/litefury-check-app.sh
```

## 6. Return To Golden

```bash
GOLDENGATE_LITEFURY_RETURN_CONFIRM=RETURN_TO_GOLDEN \
  targets/litefury-artix7/tools/litefury-return-golden.sh

GOLDENGATE_LITEFURY_RESCAN_CONFIRM=CONTROLLED_RESCAN \
  targets/litefury-artix7/tools/litefury-pcie-rescan.sh

targets/litefury-artix7/tools/litefury-check-golden.sh
```

## 7. Run The Full Cycle Gate

```bash
. targets/litefury-artix7/tools/litefury-gate-env.sh

GOLDENGATE_APP_CYCLE_CONFIRM=RUN_APP_CYCLE \
  tools/gate-app-cycle.sh --execute --max-temp-c 85
```

## Remaining Turnkey Work

- finish the LiteFury Vivado top-level
- add flash erase/program/readback wrappers
- add protected golden refresh wrapper bound to the actual SPI flash tool
- add installer that places scripts and systemd units under `/opt/goldengate`
- add a live evidence bundle command
