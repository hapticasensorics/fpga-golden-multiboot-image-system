# Safety Model

The safety model assumes app images are untrusted until proven otherwise.

## Trust Boundary

Trusted:

- permanent golden image
- host-side verifier
- slot manifest policy
- flash readback result

Untrusted:

- newly built app images
- stale app manifests
- transport state after warmboot
- old evidence bundles
- app health claims until heartbeat advances

## Golden Must Reject

Golden should reject warmboot requests when:

- the boot address points into the protected golden region
- the boot address is outside the update region
- the boot address is unaligned
- the slot is not verified
- the board is above the configured thermal limit
- the app image hash does not match the manifest
- the operator confirmation or trigger magic is missing

## Thermal Guard

Thermal policy belongs in every live gate that can flash, warmboot, or stress the
board. A safe default is:

```text
refuse live mutation when FPGA temperature is above the configured limit
allow read-only health checks at higher temperatures
print current temperature in every gate result
```

## JTAG Posture

JTAG is the last-resort recovery tool, not the normal programming path.

The desired daily loop is:

```text
golden -> flash slot over host transport -> warmboot app -> prove app -> return golden
```

JTAG remains useful for:

- first golden installation
- recovering an erased or corrupted golden
- low-level board bring-up
- verifying configuration registers before the host transport works

## Failure Fixtures

A working app cannot prove fallback. Use two fixtures:

- known-good app: proves the happy path
- known-bad or wedging app: proves rejection, fallback, and watchdog

