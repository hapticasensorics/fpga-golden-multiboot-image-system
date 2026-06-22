# LiteFury Turnkey Gap List

This is the remaining work to make the LiteFury/Framework target truly
clone-and-install from this repository.

## Required For Turnkey LiteFury

1. Board-specific Vivado project
   - part number and constraints
   - PCIe/XDMA shell
   - SPI flash pins and configuration mode
   - ICAPE2 warmboot wrapper

2. Golden bitstream build flow
   - build script
   - timing gate
   - artifact naming
   - bitstream-to-flash-image conversion

3. Host flash tooling
   - SPI erase/program/readback
   - SHA-256 verification
   - protected-region refusal
   - golden refresh ceremony

4. PCIe/XDMA host tooling
   - BAR read/write helpers
   - controlled remove/rescan
   - driver reload and health checks
   - evidence capture

5. Framework 13 appliance integration
   - Linux package/install script
   - systemd services
   - display/audio/input services if used by an app
   - boot splash or console policy, if appliance-like UX matters

6. Mechanical/thermal validation
   - open chassis baseline
   - closed chassis screw-down validation
   - storage adapter clearance validation
   - copper spreader / keyboard deck thermal interface validation
   - live FPGA temperature display

7. Recovery fixtures
   - known-good app image for both slots
   - deliberately bad image for fallback
   - wedging image or watchdog test mode

## What The Current Repo Already Gives

- the standard architecture
- neutral register contracts
- LiteFury slot map
- cleanroom RTL starting point
- gate sequence templates
- safety model
- evidence schema

## Honest Status

The current repository is enough to guide an implementation and avoid repeating
the architecture mistakes. It is not yet a one-command LiteFury installer.

That is a good next target: promote this profile from documentation into a real
`targets/litefury-artix7/` implementation package.

