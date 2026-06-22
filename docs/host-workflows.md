# Host Workflows

This document describes the common operator loops. Replace the example tools
with board-specific flash, transport, and driver commands.

## Program an App Slot

1. Build an app bitstream.
2. Convert it to the format expected by the flash loader.
3. Write it to a slot container.
4. Read back the slot bytes.
5. Compare SHA-256.
6. Write or update the slot manifest.
7. Mark the slot verified.

Do not warmboot an image that has not passed readback verification.

## Warmboot Into an App

1. Confirm golden identity: `GMB0`.
2. Confirm board health is inside policy limits.
3. Confirm the target slot is verified.
4. Write the app payload address to `BOOT_ADDR`.
5. Write flags to `BOOT_FLAGS`.
6. Write the trigger magic to `TRIGGER`.
7. Re-enter the transport without asserting a full board reset.
8. Confirm app identity: `GAPP`.
9. Confirm app heartbeat advances.

For PCIe systems, prefer device hot remove/rescan and driver reload over host
reboot. A host reboot can assert PCIe fundamental reset and force the FPGA to
coldboot back to golden.

## Return to Golden

Preferred order:

1. Ask the app to return using its `GRET` page.
2. Re-enter the transport.
3. Confirm golden identity: `GMB0`.
4. Read boot reason and event log.

Only use JTAG or physical power cycling when the golden path is unavailable.

## Refresh Golden

Refreshing golden is a higher-risk operation than updating an app slot.

Recommended posture while developing:

- protect golden sectors with persistent protection bits
- do not lock the protection-bit array until the golden image is frozen
- require explicit operator confirmation before erasing `0x0`
- read back and hash the refreshed golden image
- coldboot and prove `GMB0`

Recommended posture before shipping:

- protect golden sectors
- lock golden protection if the board and field workflow can tolerate it
- keep a documented physical recovery path

