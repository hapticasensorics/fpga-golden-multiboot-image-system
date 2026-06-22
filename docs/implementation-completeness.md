# Implementation Completeness

GoldenGate FPGA is not magic glue. A user cannot clone this repository, point it
at arbitrary FPGA hardware, and expect a protected golden image to appear.

This repository contains:

- the architecture
- the register contracts
- cleanroom RTL reference blocks
- host workflow/gate templates
- example manifests and slot maps
- a concrete LiteFury/Framework target profile

A board still needs a **target port** that binds those abstractions to its real
configuration primitive, flash device, host transport, thermal monitor, and
driver lifecycle.

## What Is Turnkey Today

| Area | Status |
|---|---|
| Architecture and safety model | Complete reference |
| Golden/app/watchdog register contracts | Complete reference |
| Cleanroom generic RTL blocks | Starter-quality, board wrapper required |
| Gate sequencing scripts | Generic templates, callback-driven |
| Slot layout planning | Runnable generic helper |
| Manifest shape | Runnable generic checker |
| LiteFury/Framework target map | Documented target profile |

## What A User Must Still Bind

| Area | Required target work |
|---|---|
| Warmboot primitive | Connect `warmboot_request` to vendor configuration primitive, e.g. Xilinx `ICAPE2` / `WBSTAR` / `IPROG` |
| Flash access | Provide erase/program/readback/protect commands for the board's SPI flash |
| PCIe or host transport | Provide BAR read/write and post-warmboot re-enumeration commands |
| Health telemetry | Connect XADC/SYSMON or equivalent temperature/rail monitor |
| App wrapper | Expose the app identity/heartbeat/return/watchdog contract |
| Persistent protection | Implement flash-sector protection for the actual flash part |
| Evidence collection | Emit gate evidence with bitstream hash, slot id, boot reason, and final identity |

## LiteFury Reality Check

For the LiteFury/Framework target, most of the concrete system already exists in
the source appliance project. This repo documents that target and extracts the
portable structure, but it does not currently vendor every board-specific Vivado
project, XDMA driver script, SPI flash programmer, or systemd service needed to
recreate the exact appliance from scratch.

So the honest answer is:

- **Can another LiteFury owner use this repo to understand and reimplement the
  golden multiboot system?** Yes.
- **Can they clone only this repo and install the proven Framework/LiteFury
  appliance with no other code?** Not yet.
- **What is missing for that?** A dedicated `targets/litefury-artix7/` port with
  board-specific RTL wrappers, Vivado project hooks, XDMA host tools, SPI flash
  tooling, and install scripts.

The repo now has the right shape for that target pack. The next step, if we want
true turnkey LiteFury support, is to move or rewrite the proven board-specific
implementation into that target directory.

