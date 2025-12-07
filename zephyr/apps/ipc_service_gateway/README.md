# ipc_service_gateway

Zephyr-side service that exposes an RPMsg endpoint (`ipc_gateway`) for Linux/QNX clients.
It leverages Zephyr's `ipc_service` subsystem with the RPMsg shared-memory backend so the
Linux harts (U54_0/U54_1) can push control messages into Zephyr running on U54_3.

## Features

- Registers a named endpoint and sends a ready banner once the channel is bound.
- Parses textual commands from Linux/QNX (PING, STATUS, RADAR_START `<profile>`, RADAR_STOP, HELP) and emits structured responses.
- Tracks a minimal "radar" state machine so RADAR_START/STOP requests immediately reflect in STATUS replies.

The Linux service (`zephyr_ipc_gateway.sh`) exposes `/run/amp/ipc_gateway.cmd`; writing a line such as `PING` or `RADAR_START medium_range` into that FIFO forwards the command to Zephyr. Responses are logged to `journalctl -u zephyr-ipc-gateway` and mirrored into `/run/amp/ipc_gateway.log`.

## Building

```powershell
pwsh -File scripts/build/zephyr_amp.sh `
  -a zephyr/apps/ipc_service_gateway `
  -b mpfs_amp_gateway `
  -H 3
```

The build helper automatically applies the shared-memory overlay and the hart-specific
overlay for U54_3, so the resulting ELF can be dropped into the `bsp/hss` payload.

## Extending

- Replace the built-in command handlers with application-specific routing logic (e.g., call radar HAL drivers or DMA submission APIs).
- Introduce additional IPC endpoints (e.g., `ipc_gateway.telemetry`) by duplicating the endpoint config and updating the Linux `rpmsg_ctrl` setup script in `linux/rootfs`.
