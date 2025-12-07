# Zephyr Applications

Store AMP-targeted Zephyr apps here. Suggested starters:

1. `amp_pingpong` – Basic IPC Service echo sample included in this repo (built with `bsp/device-tree/zephyr/mpfs-amp.overlay`).
2. `ipc_service_gateway` – Registers the `ipc_gateway` RPMsg endpoint for Linux/QNX peers, exposes a small command set (PING/STATUS/RADAR_START/RADAR_STOP), and emits a ready banner once bound.
3. `radar_control` – Programs FPGA registers, manages DMA queues.
4. `telemetry_agent` – Publishes hart/fabric metrics via shared memory or RPMsg.

Each app should include a `prj.conf` capturing AMP-specific Kconfig settings.
