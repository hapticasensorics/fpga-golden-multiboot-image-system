# Glossary

**A/B slots**

Two app regions in flash. One can hold a known-good image while the other holds a
candidate.

**App contract**

The small standard register surface every application image exposes for identity,
heartbeat, return-to-golden, and watchdog.

**Golden image**

The permanent recovery bitstream configured at cold boot.

**IPROG**

Xilinx internal reconfiguration command used to restart configuration from a
selected flash address.

**JTAG**

Hardware debug/programming interface. Useful for recovery and bring-up, but not
the desired day-to-day update path.

**PPB**

Persistent protection bit in many SPI flash devices. Used to protect sectors
from erase/program.

**Slot**

A flash container holding an application bitstream and optional metadata.

**Warmboot**

Reconfiguration from a selected flash address without physically power cycling
the board.

**Watchdog**

A timer that returns the device to golden when the app stops proving liveness.

