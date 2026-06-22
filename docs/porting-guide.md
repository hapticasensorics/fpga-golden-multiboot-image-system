# Porting Guide

Port GoldenGate FPGA by binding the abstract contracts to your board.

## 1. Choose the Control Transport

Common options:

- PCIe BAR
- USB vendor protocol
- UART command channel
- Ethernet management plane
- soft CPU register bus

The transport must be available in golden. It should also be available in apps
through the app contract, but the app transport is not trusted until app identity
and heartbeat are proven.

## 2. Bind Warmboot

Xilinx 7-series designs usually use `ICAPE2` with `WBSTAR` and `IPROG`.
Different families have different primitives and address semantics.

GoldenGate's RTL examples expose a `warmboot_request` and `warmboot_address`.
Your board wrapper should translate those into the vendor primitive sequence.

## 3. Bind Flash

The host or golden image needs a way to write and verify app slots.

Recommended design:

- host performs bulk image transfer and SHA-256 verification
- golden validates addresses and slot state
- golden never blindly erases its own protected region

## 4. Bind Health

Expose at least:

- FPGA temperature
- alarm flags
- sample counter
- highest observed temperature since boot

Voltage rails, PCIe link state, flash status, and error counters are strongly
recommended.

## 5. Bind App Contract

Every app wrapper should implement:

- app identity
- build id
- heartbeat
- return-to-golden trigger
- watchdog pet, if watchdog is enabled

Do this once and reuse it for every app image.

## 6. Prove the Pair of Fixtures

Before testing real products:

- boot a known-good app from both slots
- boot a deliberately bad image and prove fallback
- arm watchdog against a wedging image and prove return to golden

