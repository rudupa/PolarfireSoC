# System Architecture (PolarFire SoC Discovery Kit)

Consolidates the current AMP plan (Linux + QNX + Zephyr + FPGA) so that documentation, boot flows, and resource budgets line up with the actual hardware: four U54 application cores plus one E51 monitor core.

## 1. Hardware Snapshot
- **SoC**: MPFS095T (E51 monitor + 4× U54 RV64GC cores, shared 2 MB L2 cache, 1 GB LPDDR4, 64 MB QSPI, microSD/eMMC storage, FPGA fabric with DSP resources).
- **Primary accelerators**: Radar DSP chain (FIR, FFT, pulse compression) and optional NN IP in Libero; communicates over CoreAXI4DMA / CoreAXI4Stream.
- **Supporting docs**: docs/architecture/target.md (platform spec), docs/resources_budgeting.md (capacity), docs/architecture/memory_layout.md (DDR carve-outs).

## 2. Hart Allocation (Current Baseline)
| Hart | Role | OS / Payload | Responsibilities | FPGA Interactions |
|------|------|--------------|------------------|-------------------|
| E51 | Boot supervisor | HSS | Loads FPGA bitstream, configures clocks/DDRs, launches payloads. | Programs bitstream via HSS payload, exposes management registers.
| U54_0 | Application/core services | Linux (Stage 1 + Stage 2) | Stage 1 initramfs with SDL2 framebuffer UI; Stage 2 Yocto rootfs running Weston, ROS2 graph, camera ingest, ROS2 fusion, NN/image accelerator orchestration, telemetry, networking, storage. | Controls NN/image-processing IP, shares DMA descriptors with Zephyr, receives processed radar/camera data via shared buffers.
| U54_1 | Safety / deterministic control | QNX Neutrino | Safety supervision, watchdogs, shared-memory validation, gatekeeper for commands toward Linux & Zephyr. | Read-only or limited write access to FPGA health/status registers to enforce safety policies.
| U54_2 | Radar control | Zephyr RTOS | Configures radar front-end, owns radar-facing DMA queues, services ISR-to-task FFT/pulse-compression scheduling. | Primary driver for radar DSP accelerators; manages CoreAXI4DMA channels feeding FIR/FFT blocks.
| U54_3 | Telemetry / auxiliary control | Zephyr RTOS | Telemetry agent, secondary radar stages or spare radar lanes, experimental workloads, fallback radar controller if U54_2 saturates. | Optional co-owner of radar accelerators (secondary lane) or other fabric IP; can release telemetry role to Linux/QNX when dedicating bandwidth to FPGA tasks.

> Allocation aligns with Yocto, Zephyr, and QNX folder structure; adjust only if measurements prove another split materially better.

**FPGA & Camera Interaction Summary** – Linux (U54_0) manages camera capture, ROS2 fusion, and any NN/image accelerators instantiated in the FPGA; Zephyr harts (U54_2/U54_3) own radar DMA + DSP pipelines; QNX touches FPGA registers only for health monitoring. Multiple harts may share FPGA DMA/IP through coordinated descriptor tables and doorbells defined in `qnx/ipc`.

## 3. Boot & Runtime Flow
1. **ROM → HSS (E51)**
   - Initialize PLL, DDR, MSS peripherals.
   - Load Libero bitstream and stage HSS payload entries per hart.
2. **Stage 1 (Fast Boot Linux on U54_0)**
   - Kernel boots with built-in initramfs (see docs/workflows/linux_fast_boot.md).
   - stage1-gui.service launches SDL2 framebuffer UI within ~1.5 s.
   - Exposes heartbeat + shared FIFO for later handoff.
3. **Parallel Bring-up**
   - U54_1 → QNX: starts safety manager, shared-memory sanitizers.
   - U54_2/U54_3 → Zephyr: start radar DMA, OpenAMP endpoints, telemetry.
4. **Stage 2 (Linux Rootfs Pivot)**
   - HSS loaders (or Linux scripts) mount SD/eMMC partition; pivot-to-stage2.sh transitions into the full Yocto rootfs.
   - Weston compositor, ROS2 core, visualization nodes, and networking services start.
   - Stage 1 UI hides or yields once ROS2 visualization is responsive.
5. **Late Services**
   - OTA agents, logging, container runtimes start after core workloads stabilize.

## 4. Radar / Vision Acceleration & Parallelization Strategy
- **Fabric offload**: FIR/FFT/pulse-compression blocks and optional NN/image-processing IP run in FPGA, fed by CoreAXI4DMA/CoreAXI4Stream. Multiple CPU harts can share DMA doorbells and AXI-Lite control windows as long as software arbitrates ownership.
- **Primary FPGA clients**:
   - U54_2 (Zephyr) drives radar DMA descriptors, schedules FFT/FIR pipelines, and services ISR completions.
   - U54_3 (Zephyr) handles secondary radar features, telemetry, or can be reassigned for additional radar throughput.
   - U54_0 (Linux) programs NN or camera accelerators when present, pulls results into ROS2 graph, and may share DMA queues with Zephyr via shared-memory descriptors.
   - U54_1 (QNX) accesses FPGA only for safety/health monitoring (e.g., watchdog registers) to avoid contention.
- **Camera image processing**: No dedicated ISP/GPU is on-board, but the FPGA fabric can host custom image-processing pipelines (debayer, filtering, CNN). Linux (U54_0) orchestrates camera capture via CSI/parallel interface, then either streams frames directly into DDR for CPU processing or routes them through FPGA IP before ROS2 nodes consume the data.
- **Parallelization options**:
   1. Increase FPGA pipeline concurrency (multiple FFT engines, separate radar lanes) and expose unique DMA channels to U54_2/U54_3.
   2. Use Zephyr worker threads pinned to different priorities; OpenAMP backpressure ensures Linux ROS2 consumers don’t overrun shared buffers.
   3. Allow Linux to offload camera NN workloads to FPGA while Zephyr maintains radar throughput; coordinate via shared descriptor tables defined in `qnx/ipc` headers.
   4. For extreme radar load, dedicate U54_3 entirely to radar control and migrate telemetry helpers to Linux/QNX.

## 5. Resource Budgets & Allocations
Summary (see docs/resources_budgeting.md for detail):
| Domain | RAM Min / Typical | Flash / Storage Min / Typical | Notes |
|--------|------------------|-------------------------------|-------|
| Linux Stage 1 | 64 MB / 96 MB | 32 MB / 64 MB | Kernel + initramfs + SDL2 assets in QSPI/SD boot partition.
| Linux Stage 2 (ROS2 + Weston) | 700 MB / 1.1 GB | 1.6 GB / 2.0 GB | Yocto rootfs, ROS2 workspace, GUI assets on SD/eMMC.
| QNX (U54_1) | 64 MB / 128 MB | 128 MB / 256 MB | IFS image + resource managers.
| Zephyr (per hart) | 4 MB / 8 MB | 8 MB / 16 MB | ELFs stored in HSS payloads; includes OpenAMP buffers.
| Shared IPC & DMA carve-outs | 64 MB (static) | N/A | Reserved DDR per memory_layout.md for OpenAMP, QNX mailboxes, FPGA queues.

**Headroom**: Typical RAM total (~1.1 GB + 0.128 GB + 0.016 GB) exceeds 1 GB when peaks coincide. Mitigations: zram swap (128–256 MB), cgroup limits for ROS2, optional redistribution of Zephyr telemetry tasks to Linux to free memory on U54_3.

## 6. Allocation Updates & Actions
1. **Confirm DDR layout** – Align linker scripts and device tree reserved-memory with memory_layout.md; adjust if ROS2 footprint changes.
2. **Validate boot order** – Ensure HSS payload manifest loads Linux Stage 1 first but launches QNX/Zephyr concurrently so deterministic paths are live before ROS2 pivot completes.
3. **Measure parallel radar throughput** – Profile DMA + Zephyr pipelines; if CPU becomes bottleneck, move additional stages into FPGA or leverage PLIC priorities to reduce ISR latency.
4. **Update resource budgets** – Feed real measurements back into docs/resources_budgeting.md and adjust Stage 2 image composition when adding ROS2 packages.

This document should stay synchronized with TODO.md, QNX integration work, and Yocto recipes so architectural intent matches implementation.
