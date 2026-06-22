# GoldenGate FPGA

GoldenGate FPGA is a clean, portable reference design for a fail-safe FPGA
golden-image multiboot system.

It is for boards where a small trusted bitstream should always boot first,
keep the device recoverable without JTAG, load application images from flash
slots, observe app health, and return to golden automatically when an app fails.

The repository is intentionally not tied to one board, one PCIe core, or one
application. It documents the standard architecture and provides small
cleanroom examples for:

- a permanent golden image at flash address `0x0`
- one or more application slots elsewhere in flash
- host-triggered warmboot into a selected app slot
- app-to-golden return
- heartbeat and watchdog contracts
- slot manifests and verify-before-boot policy
- telemetry for temperature, voltage, boot status, and event history
- JTAG-free development workflows

## What This Is

Technically, this is a **fail-safe FPGA multiboot manager**. The short name is
GoldenGate FPGA because the golden image is the gate between untrusted app
images and the physical board.

The golden bitstream should be small, boring, and hard to brick. It owns:

- flash layout knowledge
- slot selection
- boot validation
- warmboot/IPROG requests
- health telemetry
- recovery policy
- watchdog fallback

Application bitstreams own the useful product behavior. They should expose a
small app contract so the golden image and host can prove they are alive and can
request a clean return to golden.

## Repository Layout

```text
docs/       Human-readable architecture and operating guides
specs/      Stable interfaces, schemas, and register contracts
rtl/        Small cleanroom RTL reference blocks
tools/      Portable host-side planning and warmboot examples
examples/   Example slot layout and image manifest files
```

## Start Here

Read these in order:

1. [Purpose](docs/00-purpose.md)
2. [Architecture](docs/architecture.md)
3. [Flash Layout](docs/flash-layout.md)
4. [Register Map](docs/register-map.md)
5. [Host Workflows](docs/host-workflows.md)
6. [Verification Gates](docs/verification-gates.md)

## Core Rule

Never let the app image be the only way to recover the board.

If an application bitstream can corrupt flash, wedge PCIe, stop responding, or
misconfigure clocks, then the permanent golden image must still be able to bring
the board back to a known state.

## Status

This repository is a portable specification and starter kit. The RTL blocks are
small reference implementations, not a drop-in replacement for a vendor's full
configuration or flash controller.

When porting to a real board, bind these concepts to the vendor primitives and
host transport you actually use:

- Xilinx `ICAPE2` / `STARTUPE2`, Intel remote update, or board-specific boot IP
- PCIe BAR, USB, UART, Ethernet, or soft CPU control plane
- SPI flash command engine
- XADC/SYSMON or board thermal monitor
- host driver reload or PCIe remove/rescan sequence

