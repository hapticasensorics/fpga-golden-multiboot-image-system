# Register Map

This register map is intentionally small. Use it as the stable infrastructure
contract, then add board-specific or product-specific pages elsewhere.

All registers are 32-bit little-endian unless a platform says otherwise.

## Golden Page: `GMB0`

| Offset | Name | Description |
|---:|---|---|
| `0x000` | `MAGIC` | `0x474d4230` (`GMB0`) |
| `0x004` | `ABI_VERSION` | Register ABI version |
| `0x008` | `IMAGE_KIND` | `1 = golden` |
| `0x00c` | `CAPABILITIES` | Feature bits |
| `0x010` | `BUILD_ID_LO` | Build identifier low word |
| `0x014` | `BUILD_ID_HI` | Build identifier high word |
| `0x020` | `BOOT_REASON` | Coldboot, warmboot, fallback, watchdog |
| `0x024` | `LAST_REJECT` | Last warmboot reject code |
| `0x028` | `LAST_EVENT` | Last event-log code |

## Slot Page

| Offset | Name | Description |
|---:|---|---|
| `0x080` | `SLOT_A_BASE` | App slot A container base |
| `0x084` | `SLOT_A_PAYLOAD` | App slot A warmboot payload address |
| `0x088` | `SLOT_A_SIZE` | App slot A container size |
| `0x08c` | `SLOT_A_STATE` | Empty, verified, bootable, bad |
| `0x090` | `SLOT_B_BASE` | App slot B container base |
| `0x094` | `SLOT_B_PAYLOAD` | App slot B warmboot payload address |
| `0x098` | `SLOT_B_SIZE` | App slot B container size |
| `0x09c` | `SLOT_B_STATE` | Empty, verified, bootable, bad |

## Warmboot Page

| Offset | Name | Description |
|---:|---|---|
| `0x120` | `BOOT_ADDR` | Requested warmboot payload address |
| `0x124` | `BOOT_FLAGS` | Slot id and policy flags |
| `0x128` | `STATUS` | Idle, busy, accepted, rejected |
| `0x12c` | `REJECT_CODE` | Validation failure code |
| `0x130` | `CLEAR` | Write `1` to clear sticky status |
| `0x134` | `TRIGGER` | Write trigger magic to request warmboot |

Recommended trigger magic: `0xb00710ad`.

Reject codes:

| Code | Meaning |
|---:|---|
| `0` | No reject |
| `1` | Not armed |
| `2` | Controller busy |
| `3` | Address below update region |
| `4` | Address above update region |
| `5` | Address not aligned |
| `6` | Bad trigger magic |
| `7` | Slot not verified |

## Configuration Status Page

| Offset | Name | Description |
|---:|---|---|
| `0x140` | `BOOTSTS` | Device boot-status readback, if available |
| `0x144` | `STAT` | Device configuration-status readback |
| `0x148` | `WBSTAR` | Warmboot start-address readback |
| `0x14c` | `TIMER` | Configuration timer or heartbeat |

## App Contract Pages

Apps should expose:

- `GAPP`: app identity and heartbeat
- `GRET`: app return-to-golden trigger
- `GWDT`: app watchdog pet/timeout control
- `GHLT`: app health and telemetry

See [App Contract](../specs/app-contract.v1.md).

