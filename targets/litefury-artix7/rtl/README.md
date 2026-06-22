# LiteFury Target RTL

This directory contains LiteFury-specific RTL adapters that bind GoldenGate's
generic contracts to Xilinx 7-series behavior.

Current files:

- `litefury_artix7_icap_multiboot.sv`: cleanroom ICAPE2 warmboot sequencer
  skeleton for `WBSTAR` + `IPROG`.
- `litefury_artix7_goldengate_top.sv`: AXI-Lite wrapper that exposes the
  GoldenGate golden page and health page to a LiteFury PCIe/XDMA shell.

Still needed for a full board image:

- PCIe/XDMA physical shell and block design
- LiteFury clock/reset and PCIe reset binding
- SPI flash/protection status
- XADC/SYSMON sampler feeding `health_telemetry_regs`
- app-slot compatibility pages if needed
