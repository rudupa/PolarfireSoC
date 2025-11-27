# System Architecture Overview

This document tracks the end-to-end view of the PolarFire SoC learning platform (see `target.md` for detailed board specs):

1. **Hardware** – MPFS095T device on the Discovery Kit, on-board peripherals, and any daughtercards that feed the radar/DSP accelerator.
2. **Boot Flow** – Hart Software Services (HSS) loads the Libero bitstream, boots Linux on U54_0, and can optionally launch Zephyr images on the remaining U54 cores in AMP mode.
3. **Software Stack** – Microchip Yocto BSP layers deliver Linux + userspace; Zephyr targets inter-core control; FPGA DSP blocks exchange data over AXI/APB and DMA.
4. **Acceleration** – Radar DSP and NN workloads live inside FPGA fabric, with DMA-accessible buffers exposed to Linux or Zephyr via shared-memory descriptors.
5. **Telemetry & OTA** – Systemd services (Linux) or Zephyr threads (RTOS) push performance counters into a telemetry bus and support safe A/B updates via SWUpdate or RAUC.

Each numbered section should link to deeper documentation (AMP, DSP, communications) as it evolves.
