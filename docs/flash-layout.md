# Flash Layout

The exact addresses are board-specific. This example uses a 16 MiB SPI flash and
two 4 MiB app slots.

```text
0x00000000..0x003fffff  golden image and protected metadata
0x00400000..0x0067ffff  reserved / factory / future use
0x00680000..0x00a7ffff  app slot A container
0x00a80000..0x00e7ffff  app slot B container
0x00e80000..0x00ffffff  logs / manifests / future use
```

Each slot is a container. The app payload can start at an offset inside the
container, for example `slot_base + 0x100`, leaving room for metadata.

## Slot Container

```text
slot_base + 0x000  slot header / manifest pointer
slot_base + 0x100  FPGA bitstream payload warmboot address
```

The offset must match the target device's multiboot requirements. On many Xilinx
7-series designs, the warmboot address points at a sync-word-aligned bitstream
payload inside flash, not necessarily the first byte of an outer container.

## Safety Rules

- Golden lives at the coldboot address.
- App warmboot targets must be outside the protected golden region.
- Slot payload addresses must be aligned to the device's configuration-address
  requirements.
- Slot A and slot B must not overlap.
- The host must verify flash readback before booting a new image.
- Golden should reject any boot address outside the update region.
- Persistent flash protection should be used for golden sectors.
- Volatile PPB or block-protect locks are a separate policy decision: useful for
  final hardening, annoying during active golden iteration.

## A/B Policy

Use both slots even before you have two products:

- slot A: candidate image
- slot B: known-good reference image

During slot-system bring-up, put the same known-good app in both slots. That
proves pointer selection and slot switching without confusing slot bugs with app
bugs.

