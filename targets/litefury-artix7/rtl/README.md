# LiteFury Target RTL

This directory contains LiteFury-specific RTL adapters that bind GoldenGate's
generic contracts to Xilinx 7-series behavior.

Current file:

- `litefury_artix7_icap_multiboot.sv`: cleanroom ICAPE2 warmboot sequencer
  skeleton for `WBSTAR` + `IPROG`.

The next required file is a real `litefury_goldengate_top.sv` that connects:

- PCIe/XDMA AXI-Lite control bus
- `golden_multiboot_controller`
- `health_telemetry_regs`
- SPI flash/protection status
- ICAPE2 multiboot sequencer
- app-slot compatibility pages if needed

