# Cleanroom Notes

This repository is a generalization of a standard FPGA appliance pattern:
permanent golden image, update slots, warmboot, app heartbeat, watchdog, and
fallback.

It intentionally avoids product-specific names, private register maps, and
application-specific behavior.

Concepts retained:

- permanent golden image at coldboot address
- protected flash region
- app slots with payload offsets
- host-triggered warmboot
- app-triggered return to golden
- heartbeat and watchdog liveness
- thermal guard before live mutation
- event log and boot-status readback

Concepts intentionally not retained:

- product-specific video, audio, or input paths
- board-specific host service names
- private app register maps
- single-project constants except as clearly marked examples
- application launch or game-core assumptions

