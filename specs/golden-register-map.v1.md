# Golden Register Map v1

This is the stable software-facing contract for the golden image.

## Constants

```text
GOLDEN_MAGIC        = 0x474d4230  # GMB0
APP_MAGIC           = 0x47415050  # GAPP
RETURN_MAGIC        = 0x47524554  # GRET
HEALTH_MAGIC        = 0x47484c54  # GHLT
WATCHDOG_MAGIC      = 0x47574454  # GWDT
WARMBOOT_TRIGGER    = 0xb00710ad
```

## Capability Bits

| Bit | Name | Meaning |
|---:|---|---|
| 0 | `CAP_WARMBOOT` | Golden can warmboot app slots |
| 1 | `CAP_SLOT_AB` | Golden knows slot A and slot B |
| 2 | `CAP_BOOT_STATUS` | Configuration status readback present |
| 3 | `CAP_EVENT_LOG` | Event log present |
| 4 | `CAP_HEALTH` | Health telemetry present |
| 5 | `CAP_WATCHDOG` | App watchdog present |
| 6 | `CAP_FLASH_PROTECT` | Flash protection status present |

## Boot Reasons

| Value | Meaning |
|---:|---|
| 0 | Unknown |
| 1 | Coldboot golden |
| 2 | Host-requested warmboot |
| 3 | App-requested return |
| 4 | Watchdog recovery |
| 5 | Bad-slot fallback |
| 6 | Configuration fallback |

## Event Codes

| Value | Meaning |
|---:|---|
| 0 | None |
| 1 | Golden reset observed |
| 2 | Warmboot request rejected |
| 3 | Warmboot request accepted |
| 4 | App identity observed |
| 5 | App return observed |
| 6 | Watchdog armed |
| 7 | Watchdog expired |
| 8 | Flash protection changed |

