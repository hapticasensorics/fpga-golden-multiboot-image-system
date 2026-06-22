# Failure Modes

## Host Reboot Returns to Golden

Symptom:

```text
Warmbooted app disappears after host reboot.
Golden identity is present again.
```

Likely cause:

The host reboot asserted a board or PCIe reset that caused a coldboot from flash
address `0x0`.

Fix:

Use transport hot remove/rescan and driver reload instead of host reboot when
re-entering a warmbooted app.

## App BAR Vanishes During Watchdog Test

Symptom:

```text
The app identity page disappears while a watchdog gate is still reading it.
```

Likely cause:

The watchdog expired and warmbooted back to golden before the host finished
collecting app-side evidence.

Fix:

Treat app BAR disappearance as an intermediate expiry signal, then require final
golden identity proof.

## Golden Refresh Needs a Power Cycle

Symptom:

```text
Golden sectors are protected and cannot be refreshed until physical power cycle.
```

Likely cause:

The flash persistent-protection-bit array was locked until reset.

Fix:

During active development, protect golden sectors without locking the protection
bit array. Save full locking for final hardening.

## Slot Boots Once But Not Repeatably

Likely causes:

- stale transport enumeration
- app image not actually verified
- warmboot address points at the container, not payload
- host reboot coldboots golden
- slot metadata does not match flash contents

## Thermal Gate Blocks Live Runs

Likely causes:

- cooling path is insufficient
- app image is stressing the FPGA
- board is in a closed chassis without adequate conduction

Fix:

Treat this as useful protection. Improve cooling or lower test intensity before
repeating flash/warmboot storms.

