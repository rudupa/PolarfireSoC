# Zephyr Applications

Store AMP-targeted Zephyr apps here. Suggested starters:

1. `ipc_service_gateway` – Bridges OpenAMP endpoints to Linux.
2. `radar_control` – Programs FPGA registers, manages DMA queues.
3. `telemetry_agent` – Publishes hart/fabric metrics via shared memory or RPMsg.

Each app should include a `prj.conf` capturing AMP-specific Kconfig settings.
