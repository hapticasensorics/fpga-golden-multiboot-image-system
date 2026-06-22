# LiteFury Vivado Target Flow

This is the build-flow scaffold for the LiteFury Artix-7 target.

It is not yet a complete full-board Vivado project. The missing board-specific
items are:

- LiteFury board constraints
- PCIe/XDMA shell integration
- SPI flash pin/configuration constraints
- bitstream property policy for multiboot flash images
- timing reports and artifact packaging

The proven target part is:

```text
XC7A100T-L2FGG484E
vivado part: xc7a100tfgg484-2L
```

## Intended Flow

```text
build golden bitstream
  -> write coldboot flash image at load offset 0
  -> build app bitstream
  -> write app flash image at load offset 0x100
  -> program app slot over PCIe/SPI
  -> warmboot through GoldenGate
```

## Commands

Use the target wrapper:

```bash
targets/litefury-artix7/vivado/build-golden.sh --dry-run
targets/litefury-artix7/vivado/build-golden.sh --execute --run-synth
targets/litefury-artix7/vivado/build-golden.sh --execute --run-impl
```

The current `build-golden.tcl` is a cleanroom Tcl flow for the GoldenGate
AXI-Lite wrapper. It can create the project, run synthesis, and optionally run
implementation for:

```text
top:  litefury_artix7_goldengate_top
part: xc7a100tfgg484-2L
```

The full turnkey board build still needs the PCIe/XDMA shell, SPI flash backend,
and physical pin constraints from the actual LiteFury board design.
