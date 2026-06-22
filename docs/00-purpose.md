# Purpose

FPGA development gets dangerous when every new bitstream is allowed to become
the only path back into the hardware. A normal software system can usually be
restarted, ssh'd into, or recovered through a bootloader that lives outside the
application. An FPGA board is less forgiving. A bad image can break the PCIe
endpoint, hide the flash controller, drive clocks incorrectly, wedge a bus, or
leave the host with no useful device to talk to. JTAG can rescue that situation
in the lab, but JTAG is not a product architecture. It is a bench tool.

A golden-image multiboot system gives FPGA work the same kind of recovery plane
that mature embedded systems already expect. The first image in flash is not the
product. It is a small, trusted supervisor. It boots cold, exposes a minimal
control and diagnostics interface, validates application slots, and transfers
control only to a selected app image. If the app is healthy, it runs normally. If
the app is bad, missing, wedged, or simply experimental, the board still has a
way home.

This matters most during fast iteration. Developers should be able to flash a
new app image into a slot, ask golden to warmboot it, prove that it came alive,
and return to golden without opening the chassis. That loop turns JTAG from a
daily dependency into an emergency fallback. It also creates a better testing
model: the host can verify the exact image hash, slot address, boot reason,
heartbeat, watchdog behavior, and health telemetry before treating a hardware
run as meaningful.

The architecture is deliberately simple. Keep golden small. Keep it boring. Give
it only the responsibilities that protect the board: slot metadata, warmboot,
basic flash policy, health, app heartbeat, watchdog, and event logging. Put
product features in app images. Use A/B slots so a known-good image can remain
available while a candidate image is tested. Add a deliberately bad fixture so
fallback paths are proven, not merely described.

The key design boundary is ownership. The golden image owns recovery. The host
owns file transfer, image verification, and operator policy. The app owns the
actual workload. None of those layers should pretend to be the others. A
golden image that grows into the product becomes risky. A host script that
assumes an unverified app is alive becomes brittle. An app that cannot return to
golden becomes a trap.

GoldenGate FPGA is a clean reference for that pattern. It is not a board vendor
flow and it is not a single project's debug harness. It is the reusable shape of
a professional FPGA appliance boot system: permanent golden, update slots,
warmboot, health, watchdog, event log, and recovery-first development. The goal
is not cleverness. The goal is to make FPGA iteration feel survivable.

That survivability changes the way teams work. Once the board can always prove
which image is running, always report why it booted, and always return to a
boring supervisor, developers become willing to test real payloads earlier. The
golden system is not a detour from the product. It is the enabling substrate that
lets product images be bold without making the hardware fragile.
