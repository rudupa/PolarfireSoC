# Device Tree Sources

- Maintain board-level DTS/DTSI files for Linux and Zephyr here.
- Capture overlays for FPGA radar DSP, DMA engines, and shared-memory mailbox blocks.
- Provide patch queues (e.g., `linux/0001-add-radar-dsp.dts.patch`) that Yocto can apply via `SRC_URI`.

Use subfolders (e.g., `linux/`, `zephyr/`) if the divergence grows.
