# LiteFury Register Binding

This file maps the generic GoldenGate concepts onto the proven LiteFury
appliance vocabulary.

The generic repository uses neutral names:

- `GMB0`: golden multiboot manager
- `GAPP`: app identity/heartbeat
- `GRET`: app return-to-golden
- `GWDT`: app watchdog
- `GHLT`: health telemetry

The existing LiteFury appliance used project-local names such as LFGO, HAPP,
HRET, and health pages. A target implementation may preserve those names for
backward compatibility while documenting the generic GoldenGate equivalent.

## Recommended Target Binding

| Generic page | LiteFury target meaning |
|---|---|
| `GMB0` | permanent golden identity/control page |
| `GAPP` | app identity and heartbeat page |
| `GRET` | app request to return to golden |
| `GWDT` | app watchdog control/status |
| `GHLT` | FPGA health/temperature page |

## Warmboot Binding

For Xilinx Artix-7, the warmboot controller should ultimately drive:

- `WBSTAR` with the selected flash payload address
- `IPROG` through the internal configuration access primitive

The generic RTL emits:

```text
warmboot_request
warmboot_address
```

The LiteFury board wrapper must turn that into the exact Xilinx configuration
sequence and must reject unsafe addresses before asserting the request.

## Transport Binding

The proven appliance used PCIe/XDMA-style access. A target port should provide
commands that satisfy these GoldenGate callbacks:

```bash
GOLDENGATE_CHECK_GOLDEN_CMD
GOLDENGATE_WARMBOOT_APP_CMD
GOLDENGATE_RESCAN_CMD
GOLDENGATE_CHECK_APP_CMD
GOLDENGATE_RETURN_GOLDEN_CMD
GOLDENGATE_HEALTH_CMD
```

Do not use host reboot as the default app re-entry method. On this class of
system, reboot can assert PCIe reset and force the FPGA to coldboot back to
golden.

