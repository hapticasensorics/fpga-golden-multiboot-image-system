# Operations Runbook

This runbook describes the intended operating rhythm for a board that has been
ported to GoldenGate FPGA.

## Initial Bring-Up

1. Program the golden image using JTAG or the board vendor's factory method.
2. Coldboot the board and prove `GMB0`.
3. Read health and configuration status.
4. Protect the golden flash region.
5. Program a known-good app into slot A.
6. Verify slot A readback hash.
7. Warmboot slot A.
8. Re-enter the host transport without full board reset.
9. Prove app identity and heartbeat.
10. Return to golden through the app contract.

Once this loop passes, JTAG is no longer the normal development path.

## Daily App Development Loop

```text
build app
  -> write slot A or B
  -> readback/hash verify
  -> warmboot selected slot
  -> transport rescan
  -> prove app heartbeat/product surface
  -> return to golden
```

Use `gate-app-cycle.sh` as the standard loop once board-specific commands are
bound.

## Golden Refresh Loop

Golden refreshes are rare and more dangerous than app-slot updates.

```text
build candidate golden
  -> verify candidate artifact
  -> thermal preflight
  -> unprotect golden for refresh
  -> program address 0
  -> readback/hash verify
  -> protect golden again
  -> coldboot proof
```

During active development, protect golden sectors without volatile/global
protection locks that require a physical power cycle to release. Use those locks
only when the golden image is genuinely frozen for deployment.

## A/B Slot Validation

Put the same known-good app in both slots first. That isolates slot selection
bugs from app bugs.

```text
slot A known-good -> app cycle pass
slot B known-good -> app cycle pass
```

Only after A/B mechanics are proven should slot B become the stable reference
while slot A takes candidate images.

## Failure-Path Validation

A working app cannot prove fallback. Use a bad fixture.

```text
prepare deliberately bad slot
  -> attempt boot
  -> require golden fallback
  -> require boot reason/event log evidence
```

Use a wedging app fixture for watchdog validation:

```text
boot app
  -> arm watchdog
  -> pet briefly
  -> stop petting
  -> require return to golden
```

## Live Run Guardrails

Every live gate that can mutate flash, warmboot, or stress the FPGA should:

- read temperature first
- refuse above policy limit unless explicitly overridden
- record source hash and bitstream hash
- record slot id and payload address
- record final identity page
- avoid host reboot as a transport re-entry method unless the board requires it

