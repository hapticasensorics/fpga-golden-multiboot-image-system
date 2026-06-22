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

## Safety

`litefury-warmboot-slot.sh`, `litefury-return-golden.sh`, and
`litefury-pcie-rescan.sh` all require explicit confirmation environment
variables for live execution. Dry-run modes can be used without touching
hardware.
