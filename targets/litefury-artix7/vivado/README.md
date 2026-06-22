# LiteFury Vivado Target Flow

This is the build-flow scaffold for the LiteFury Artix-7 target.

It is not yet a complete Vivado project. The missing board-specific items are:

- exact Artix-7 part number
- LiteFury board constraints
- PCIe/XDMA shell integration
- SPI flash pin/configuration constraints
- bitstream property policy for multiboot flash images
- timing reports and artifact packaging

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

The future build wrapper should look like:

```bash
vivado -mode batch \
  -source targets/litefury-artix7/vivado/build-golden.tcl \
  -tclargs \
    -part xc7a100t... \
    -top litefury_goldengate_top \
    -out build/litefury-goldengate
```

The current `build-golden.tcl` is a cleanroom Tcl scaffold that validates
arguments and reads the generic RTL. It deliberately stops before pretending to
have a real board shell.

