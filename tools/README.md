# Tools

These scripts are portable examples. They do not know your flash programmer,
driver, or PCIe topology.

- `slot-plan.sh` validates a two-slot flash layout and prints derived payload
  addresses.
- `manifest-check.sh` checks a JSON manifest using shell-friendly checks.
- `warmboot-write-example.sh` shows how a host script can write a generic BAR
  register sequence to request warmboot.
- `thermal-wait.sh` polls board health until the FPGA is cool enough for live
  mutation.
- `transport-rescan-example.sh` wraps the post-warmboot transport re-entry
  step.
- `gate-coldboot.sh` proves the golden image is alive.
- `gate-app-cycle.sh` proves golden -> app -> golden.
- `gate-ab-good-app.sh` proves slot A and B using a known-good app.
- `gate-bad-slot-fallback.sh` proves failure-path fallback with a bad image.
- `gate-app-watchdog.sh` proves runtime wedge recovery.
- `gate-golden-protect.sh` wraps golden flash-protection status/change/verify.
- `gate-protected-golden-refresh.sh` wraps the deliberate golden refresh
  ceremony.

Real projects should wrap these with board-specific tools for:

- flash erase/program/readback
- SHA-256 verification
- PCIe remove/rescan or equivalent transport re-entry
- thermal policy
- app identity and heartbeat proof

## Callback Style

The gate scripts avoid board-specific assumptions. They call commands supplied
by environment variables:

```bash
export GOLDENGATE_HEALTH_CMD='my-board health --json'
export GOLDENGATE_CHECK_GOLDEN_CMD='my-board check-golden'
export GOLDENGATE_WARMBOOT_APP_CMD='my-board warmboot --slot A'
export GOLDENGATE_RESCAN_CMD='my-board transport-rescan'
export GOLDENGATE_CHECK_APP_CMD='my-board check-app --heartbeat'
export GOLDENGATE_RETURN_GOLDEN_CMD='my-board return-golden'
GOLDENGATE_APP_CYCLE_CONFIRM=RUN_APP_CYCLE tools/gate-app-cycle.sh --execute
```

This keeps GoldenGate FPGA portable: the scripts define sequence, evidence, and
guardrails; the platform supplies the actual transport and flash commands.
