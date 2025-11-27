# AMP Configuration Notes

PolarFire SoC natively supports asymmetric multiprocessing across the U54 cores. The long-term plan is to exercise multiple OS combinations:

1. **Baseline (bring-up)**
	- **U54_0** → Linux (or a bare-metal stub).
	- **U54_1..3** → Zephyr RTOS.
2. **Multi-OS Hybrid**
	- **U54_0** → Linux (userspace-heavy workloads, networking, storage).
	- **U54_1** → QNX Neutrino (safety-critical control loops, deterministic scheduling).
	- **U54_2..3** → Zephyr RTOS (radar accelerators, telemetry helpers).

HSS payload manifests must describe both layouts so the team can switch between scenarios per workflow.

Key action items:

1. Track HSS handover configuration for each hart, including payload manifests and boot arguments.
2. Document Zephyr build invocations (e.g., `west build -b mpfs_discovery/polarfire/u54_1`).
3. Capture QNX build + deployment steps (BSP handoff scripts, QNX image packaging for HSS).
4. Record OpenAMP / IPC Service settings (e.g., `CONFIG_OPENAMP=y`, `CONFIG_IPC_SERVICE=y`) and any QNX resource-manager APIs required for shared-memory messaging.
5. Define shared buffers and mailbox register maps used between Linux, QNX, Zephyr, and FPGA DMA engines.

Reference: Microchip AMP app notes and the "AMP on PolarFire SoC" examples cited in the project README.
