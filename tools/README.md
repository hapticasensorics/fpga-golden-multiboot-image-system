# Tools

These scripts are portable examples. They do not know your flash programmer,
driver, or PCIe topology.

- `slot-plan.sh` validates a two-slot flash layout and prints derived payload
  addresses.
- `manifest-check.sh` checks a JSON manifest using shell-friendly checks.
- `warmboot-write-example.sh` shows how a host script can write a generic BAR
  register sequence to request warmboot.

Real projects should wrap these with board-specific tools for:

- flash erase/program/readback
- SHA-256 verification
- PCIe remove/rescan or equivalent transport re-entry
- thermal policy
- app identity and heartbeat proof

