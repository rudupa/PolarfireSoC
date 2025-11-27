# QNX Applications

Use this directory for small services and demos that prove the hybrid AMP model:

1. `radar_resource_mgr` – Mediates shared radar buffers between QNX and Linux/Zephyr clients.
2. `telemetry_bridge` – Publishes QNX performance counters into the shared telemetry bus.
3. `control_console` – Provides a CLI for commanding Zephyr tasks via shared mailboxes.

Each app should include build instructions (QCC/QNX Momentics) and note any IPC contracts it relies on.
