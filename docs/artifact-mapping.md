# Artifact Mapping

This repository rewrites the golden-image system as a board-neutral reference.
The source project had concrete board scripts, addresses, service names, and
application identities. GoldenGate FPGA keeps the architecture and replaces
those details with portable contracts.

For the first real hardware target, the board-specific facts now live under
`targets/litefury-artix7/`.

## Source Category to GoldenGate Artifact

| Source-system category | GoldenGate cleanroom equivalent |
|---|---|
| Permanent golden identity and warmboot BAR | `rtl/golden_multiboot_controller.sv`, `docs/register-map.md` |
| App heartbeat and return-to-golden page | `rtl/app_recovery_contract.sv`, `specs/app-contract.v1.md` |
| FPGA health/XADC readback | `rtl/health_telemetry_regs.sv`, `tools/thermal-wait.sh` |
| Slot A/B flash planning | `tools/slot-plan.sh`, `docs/flash-layout.md` |
| Manifest/readback discipline | `specs/manifest.schema.json`, `tools/manifest-check.sh` |
| Golden coldboot proof gate | `tools/gate-coldboot.sh` |
| Golden -> app -> golden cycle gate | `tools/gate-app-cycle.sh` |
| A/B known-good fixture gate | `tools/gate-ab-good-app.sh` |
| Bad-slot fallback gate | `tools/gate-bad-slot-fallback.sh` |
| App watchdog recovery gate | `tools/gate-app-watchdog.sh`, `specs/app-contract.v1.md` |
| PCIe remove/rescan helper | `tools/transport-rescan-example.sh` |
| Golden write-protection gate | `tools/gate-golden-protect.sh`, `docs/safety-model.md` |
| Protected golden refresh ceremony | `tools/gate-protected-golden-refresh.sh`, `docs/operations-runbook.md` |
| Event and evidence records | `specs/event-log.schema.json`, `specs/gate-evidence.schema.json` |

## Deliberate Omissions

Not copied:

- product-specific game, media, sensor, or UI surfaces
- private hostnames, service names, or network assumptions
- board-specific flash opcodes
- vendor bitstream build scripts
- exact PCI IDs, BAR offsets, or device file paths

Those belong in a board port. This repository owns the reusable structure.

## Cleanroom Rewrite Policy

The files here are not literal copies. Each artifact was rewritten around:

- generic names
- explicit callback boundaries
- board-neutral schemas
- small stable register contracts
- failure modes that apply to any full-chip reconfigurable FPGA system
