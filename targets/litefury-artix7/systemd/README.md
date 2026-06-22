# Framework Linux Service Scaffolding

This directory contains service templates for a future turnkey Framework host
install. They are examples until the matching installer is added.

The proven appliance had three important host-side service responsibilities:

1. load and recover the XDMA driver
2. keep a small hardware/health server available
3. expose stable local commands for GoldenGate gates

GoldenGate's root gate scripts do not depend on systemd directly. The LiteFury
target tools expect `/dev/xdma0_user` and any configured services to already be
ready.

## Install Shape

A future installer should:

```text
copy repo to /opt/goldengate/fpga-golden-multiboot-image-system
install target tool wrappers into /opt/goldengate/bin
install systemd units from this directory
enable xdma load/recover service
enable optional health poller
verify /dev/xdma0_user exists
run gate-coldboot.sh
```

## Services

- `goldengate-xdma-load.service.example`: placeholder for loading XDMA and
  creating device nodes.
- `goldengate-health-poller.service.example`: placeholder for periodically
  sampling the FPGA health page and publishing evidence.

The exact XDMA module source, options, udev policy, and service dependencies are
host-specific and should be filled in by the LiteFury installer.

