# LiteFury Artix-7 Target Profile

This target pack describes the concrete hardware that motivated GoldenGate
FPGA. It is the reference implementation target, not a generic placeholder.

It is a **LiteFury M.2 FPGA board** using a Xilinx Artix-7
`XC7A100T-L2FGG484E` device, used as an internal FPGA appliance in a Framework
13 laptop. The working appliance also uses Framework-hosted Linux, PCIe/XDMA
control, SPI flash slots, and a separate internal storage arrangement.

This directory is the cleanroom LiteFury/Framework implementation surface. It is
not yet a complete one-command board port, but hardware-specific details belong
here rather than being diluted into the generic root. It now includes the first
implementation layer: Framework-side BAR tools, warmboot/return/rescan helpers,
manifest generation, systemd examples, an AXI-Lite GoldenGate wrapper, an
ICAPE2 warmboot sequencer, and a Vivado scaffold.

Cleanroom does **not** mean target-agnostic. For this repository it means the
LiteFury target pack is expressed from first principles with explicit contracts,
proven addresses, named dependencies, and reproducible gates instead of being a
private pile of lab scripts. A second owner with the same LiteFury/Framework
hardware should be able to follow this pack and know exactly which remaining
pieces are dependencies, gaps, or board-specific choices.

## Hardware Shape

Observed target:

- LiteFury M.2 FPGA card
- Xilinx Artix-7 `XC7A100T-L2FGG484E` FPGA
- SPI flash used for coldboot golden plus app slots
- PCIe endpoint exposed to Framework Linux
- XDMA-style host path for BAR/register access
- Framework 13 laptop as the host appliance
- internal storage via an M.2 E-key / Wi-Fi-card-slot style SSD adapter in the
  Framework chassis

Mechanical note:

The Framework internal integration is sensitive to clearances, grounding, and
thermal coupling. A metal screw, standoff, storage adapter, or copper interface
can create electrical or thermal behavior that does not appear on an open bench.
Any target-port guide should treat chassis-closed operation as a separate
validation gate, not a cosmetic final step.

## Proven Layout Used By The Appliance

The current proven layout uses a 16 MiB SPI flash shape:

```text
0x000000..0x3fffff  permanent golden region
0x680000..0xa7ffff  slot A container
0xa80000..0xe7ffff  slot B container
```

The app payload begins at `slot_base + 0x100`:

```text
slot A warmboot payload: 0x680100
slot B warmboot payload: 0xa80100
```

Those values are examples from the proven LiteFury appliance. A different flash
size or bitstream container format should regenerate the slot plan.

## Proven Runtime Ideas

The concrete appliance used these ideas:

- coldboot golden image at flash address `0x0`
- app slots elsewhere in flash
- warmboot into app slot without JTAG
- app return-to-golden path
- controlled PCIe remove/rescan instead of host reboot
- A/B good-app slots
- bad-slot fallback proof
- watchdog recovery proof
- FPGA health/temperature readback
- golden flash sector protection

## Target-Specific Bindings Needed

To make this target turnkey inside this repo, add:

- completed full-board Vivado project or Tcl flow for the LiteFury Artix-7
  board
- Xilinx `ICAPE2` warmboot binding
- SPI flash read/write/protect command engine
- PCIe/XDMA BAR transport tools
- Framework Linux install scripts
- systemd units for XDMA/health/control services
- Framework chassis and thermal validation notes
- exact bitstream packaging flow for `slot_base + 0x100`
- permanent golden flash refresh procedure
- app-slot flash procedure

Some of those pieces now exist under `tools/`, `rtl/`, `vivado/`,
`constraints/`, and `systemd/`; see [turnkey-gap-list.md](turnkey-gap-list.md)
for what remains.

## Why This Is Not In The Generic Root

Most GoldenGate concepts are portable. These details are not:

- PCI device IDs
- XDMA device paths
- BAR offsets
- SPI flash command quirks
- Framework service names
- thermal thresholds for a closed laptop chassis
- Artix-7 `ICAPE2` sequencing

They belong in this target profile or a future target-specific package.

That is the key boundary: generality lives in the GoldenGate contracts; turnkey
use lives in a target pack. A second LiteFury/Framework owner should start here,
not from the board-neutral examples.
