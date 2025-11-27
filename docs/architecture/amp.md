# AMP Configuration Notes

PolarFire SoC natively supports asymmetric multiprocessing across the U54 cores. We will adopt the following baseline partition:

- **U54_0** runs Linux (or a bare-metal debug stub during bring-up).
- **U54_1..3** boot dedicated Zephyr RTOS images for deterministic radar control and inter-core services.

Key action items:

1. Track HSS handover configuration for each hart, including payload manifests and boot arguments.
2. Document Zephyr build invocations (e.g., `west build -b mpfs_discovery/polarfire/u54_1`).
3. Capture OpenAMP / IPC Service settings (e.g., `CONFIG_OPENAMP=y`, `CONFIG_IPC_SERVICE=y`) for shared-memory messaging.
4. Define shared buffers and mailbox register maps used between Linux, Zephyr, and FPGA DMA engines.

Reference: Microchip AMP app notes and the "AMP on PolarFire SoC" examples cited in the project README.
