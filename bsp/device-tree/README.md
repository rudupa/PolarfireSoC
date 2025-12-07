# Device Tree Sources

- Maintain board-level DTS/DTSI files for Linux and Zephyr here.
- Capture overlays for FPGA radar DSP, DMA engines, and shared-memory mailbox blocks.
- Provide patch queues (e.g., `linux/0001-add-radar-dsp.dts.patch`) that Yocto can apply via `SRC_URI`.

Use subfolders (e.g., `linux/`, `zephyr/`) if the divergence grows.

## Current overlays

- `linux/amp-shmem-overlay.dtsi` – reserved-memory + mailbox definitions that align with `include/amp/shmem_layout.h`. Consume it via your Yocto kernel recipe as described in `docs/workflows/yocto_build.md`.
- `zephyr/mpfs-amp.overlay` – Zephyr-specific overlay wiring the shared-memory node into `zephyr,ipc-shm`. Pass it to `west build` through `-DDTC_OVERLAY_FILE` (see `docs/workflows/zephyr_amp.md`).
