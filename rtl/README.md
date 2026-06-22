# RTL Reference Blocks

These modules are cleanroom reference blocks for the public contracts in
`../docs` and `../specs`.

They are intentionally small:

- `golden_multiboot_controller.sv` validates warmboot requests and emits a
  single-cycle `warmboot_request` pulse.
- `app_recovery_contract.sv` exposes app identity, heartbeat, return request,
  and a locked-by-default watchdog.
- `health_telemetry_regs.sv` exposes temperature, voltage, and alarm counters.

They do not instantiate vendor configuration primitives. A real board wrapper
must connect `warmboot_request` and `warmboot_address` to the correct primitive,
for example Xilinx `ICAPE2` or another vendor's remote-update block.

The bus is deliberately generic:

```verilog
bus_wr_en
bus_rd_en
bus_addr
bus_wdata
bus_rdata
```

Adapt it to AXI-Lite, Wishbone, Avalon-MM, CSR bus, or a soft CPU register file
in your platform wrapper.

