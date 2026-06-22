# App Contract v1

Every application bitstream should expose this small contract somewhere in its
control plane.

## App Identity Page

| Offset | Name | Description |
|---:|---|---|
| `0x000` | `APP_MAGIC` | `0x47415050` (`GAPP`) |
| `0x004` | `APP_ABI_VERSION` | App contract version |
| `0x008` | `APP_CAPABILITIES` | App feature bits |
| `0x00c` | `APP_STATUS` | Running, degraded, faulted |
| `0x010` | `APP_BUILD_ID_LO` | Build id low word |
| `0x014` | `APP_BUILD_ID_HI` | Build id high word |
| `0x018` | `HEARTBEAT` | Must advance while app is alive |
| `0x01c` | `LAST_FAULT` | App-defined fault code |

## Return Page

| Offset | Name | Description |
|---:|---|---|
| `0x100` | `RETURN_MAGIC` | `0x47524554` (`GRET`) |
| `0x104` | `RETURN_STATUS` | Idle, armed, busy, accepted |
| `0x108` | `RETURN_REASON` | Host, app fault, watchdog, operator |
| `0x10c` | `RETURN_TRIGGER` | Write trigger magic to return |

## Watchdog Page

Watchdog must be disabled and locked by default.

| Offset | Name | Description |
|---:|---|---|
| `0x200` | `WATCHDOG_MAGIC` | `0x47574454` (`GWDT`) |
| `0x204` | `WATCHDOG_STATUS` | Locked, enabled, expired |
| `0x208` | `WATCHDOG_TIMEOUT_MS` | Timeout after explicit unlock |
| `0x20c` | `WATCHDOG_PET` | Write any value to pet |
| `0x210` | `WATCHDOG_UNLOCK` | Write board-specific unlock value |

## Rules

- App heartbeat must be independent of host reads.
- Volume keys, menu keys, or diagnostics must not accidentally pet the watchdog.
- The return trigger should be idempotent.
- An app that cannot expose this contract is not a safe production tenant.

