# Resource Budgeting Guide

Compares available hardware resources on the PolarFire SoC Discovery Kit with planned allocations for Linux, QNX, Zephyr, and FPGA payloads.

## 1. Available Resources

### 1.1 CPU Resources
| Core | Type | Max Frequency | L1 Cache | Shared L2 | Notes |
|------|------|---------------|----------|-----------|-------|
| E51 | RV64IMAC monitor | ~375 MHz | 32 KB I / 32 KB D | Shared 2 MB | Runs HSS, handles low-level services.
| U54_0 | RV64GC app core | up to 667 MHz | 32 KB I / 32 KB D | Shared 2 MB | Hosts Linux (Stage 1/2, ROS2, GUI).
| U54_1 | RV64GC app core | up to 667 MHz | 32 KB I / 32 KB D | Shared 2 MB | Linux SMP peer handling ROS2 workloads/telemetry overflow.
| U54_2 | RV64GC app core | up to 667 MHz | 32 KB I / 32 KB D | Shared 2 MB | Assigned to QNX Neutrino safety manager.
| U54_3 | RV64GC app core | up to 667 MHz | 32 KB I / 32 KB D | Shared 2 MB | Zephyr radar/telemetry controller.

CPU interconnect provides coherent access to DDR with typical latencies ~80–120 ns (controller dependent). Keep cache-friendly data structures to minimize DDR trips.

### 1.2 Memory & Storage Resources
| Category | Capacity | Latency / Notes |
|----------|----------|-----------------|
| LPDDR4 RAM | 1 GB | 32-bit bus @ up to 1600 MT/s; shared across harts and FPGA DMA.
| L2 Memory Subsystem | 2 MB | Inclusive cache; ~10–15 ns access from U54 cores.
| L2 Coherent Scratchpad | 128 KB | Low-latency buffer for shared descriptors.
| QSPI NOR Flash | 64 MB | <100 ns read access; holds boot payloads and Stage 1 image.
| microSD / eMMC | ≥ 8 GB | 25–50 MB/s typical throughput; Stage 2 rootfs and ROS2 workspace.
| FPGA Fabric | ~95k LE, 300+ DSP, 3.8 Mb LSRAM, 18 Mb uSRAM | Resource pool for radar DSP, NN/IP blocks; schedule via Libero.
| FPGA LSRAM/uSRAM | 3.8 Mb / 18 Mb | On-chip memories for DSP/NN blocks; accessible to CPUs via AXI bridges.

### 1.3 Core Allocation Summary
| Hart | OS / Role | Responsibilities |
|------|-----------|------------------|
| E51 | HSS | Boot sequencing, bitstream loading, power management. |
| U54_0 | Linux | Stage 1 SDL2 UI, Stage 2 Weston + ROS2, networking, storage. |
| U54_1 | Linux | SMP peer running ROS2 nodes/telemetry overflow, accelerator hosts. |
| U54_2 | QNX | Deterministic control loops, watchdogs, shared-memory validation. |
| U54_3 | Zephyr | Radar DMA orchestration, telemetry, IPC gateway.

## 2. Planned Budgets
| Domain | RAM Budget (Min/Typical) | Flash/Storage Budget (Min/Typical) | Key Components |
|--------|-------------------------|-----------------------------------|----------------|
| Linux Stage 1 (kernel + initramfs GUI) | 64 MB / 96 MB | 32 MB / 64 MB | Kernel, BusyBox, SDL2 GUI assets. |
| Linux Stage 2 (rootfs + Weston + ROS2) | 700 MB / 1.1 GB | 1.6 GB / 2.0 GB | Yocto rootfs, compositor, ROS2 nodes/apps. |
| QNX (U54_2) | 64 MB / 128 MB | 128 MB / 256 MB | BSP image, resource managers, shared-memory services. |
| Zephyr (U54_3) | 4 MB / 8 MB | 8 MB / 16 MB | IPC service gateway, radar control app, telemetry agent. |
| FPGA Bitstreams + HSS Payloads | N/A RAM | 50 MB / 100 MB | Bitstream, payload manifests, Zephyr/ QNX binaries in HSS bundle. |

## 3. Headroom Analysis
- **RAM**: Summing typical allocations (~1.1 GB Linux + 0.128 GB QNX + 0.016 GB Zephyr) exceeds the physical 1 GB if peaks coincide. Real-world usage is lower because Linux releases memory when Stage 1 exits and ROS2 nodes rarely hit peak simultaneously. Still, keep Linux closer to 900 MB via service trimming, zstd-compressed rootfs, and zram swap.
- **Flash**: Stage 1 fits within QSPI (64 MB) if assets stay minimal. Stage 2 image + ROS2 workspace (≈2 GB) comfortably fits standard SD cards. Plan for log rotation to avoid SD wear.
- **Shared Buffers**: Allocate dedicated DDR carve-outs (e.g., 64 MB) for Linux ↔ QNX/Zephyr IPC and FPGA DMA. Reserve addresses in device tree/HSS to prevent fragmentation.

## 4. Resource Management Strategies
1. **Memory Pressure Controls**
   - Enable zram swap (128–256 MB) so occasional ROS2 spikes don’t OOM the system.
   - Use cgroups/systemd slices to cap ROS2 and GUI processes.
   - Strip debug symbols and use `-Os` where possible.
2. **Filesystem Optimization**
   - Compress initramfs via `CONFIG_INITRAMFS_COMPRESSION_ZSTD`.
   - Use read-only squashfs for Stage 2 base image; mount writable overlayfs for state.
   - Store large ROS2 models/data on secondary partition with LZ4 compression.
3. **IPC Buffer Planning**
   - Centralize shared-memory layout in `qnx/ipc/` headers; allocate contiguous regions early at boot.
   - Use ring buffers sized to actual throughput (~16–32 MB) instead of blanket allocations.
4. **Monitoring**
   - Deploy `systemd-oomd`, `ps_mem`, or custom telemetry to track RAM usage.
   - Log Stage 1 → Stage 2 transition times and memory snapshots to validate design goals.
5. **FPGA Payload Size Control**
   - Strip unused IP cores, keep partial bitstreams modular.
   - Automate bitstream compression before bundling into HSS payloads.

## 5. FPGA Fabric Budget
Align FPGA resource usage with the interaction model described in `docs/architecture/system_architecture.md` so each hart has predictable access to accelerators.

| Function / IP Block | Primary Owner(s) | Logic / DSP Budget (approx) | Memory Budget | Notes |
|---------------------|------------------|-----------------------------|---------------|-------|
| Radar FIR + FFT Chain (lane A) | Zephyr U54_3 | 25k LE, 120 DSP | 4 Mb LSRAM | Main radar path; tied to DMA channel 0.
| Radar FIR + FFT Chain (lane B / optional) | Linux U54_1 (fallback) | 20k LE, 90 DSP | 3 Mb LSRAM | Activated only when Linux offloads telemetry and assumes a second radar lane via shared DMA channel 1.
| Pulse Compression / CFAR module | Zephyr U54_3 + Linux U54_1 | 10k LE, 40 DSP | 2 Mb LSRAM | Shared via descriptor arbitration across Zephyr and Linux worker threads.
| NN / Camera Accelerator | Linux U54_0/U54_1 | 20k LE, 40 DSP | 6 Mb uSRAM | Implements CNN or ISP pipeline; controlled via Linux drivers.
| Health & Monitors | QNX U54_2 | 2k LE | negligible | Watchdog, status registers, performance counters exposed read-only.
| Interconnect / DMA glue | Shared | 15k LE | 1 Mb LSRAM | CoreAXI4DMA, AXI interposers, gateways for shared-memory buffers.

**Management Notes**
- Keep cumulative usage within ~95k logic + 300 DSP envelope; leave ≥10% headroom for future IP.
- Assign dedicated DMA channels per owner (e.g., channel 0 = Zephyr U54_3 radar lane, channel 1 = optional Linux U54_1 radar lane, channel 2 = Linux camera/NN) to reduce contention.
- Document register maps in `qnx/ipc` so Linux/QNX/Zephyr know which descriptors control which pipelines.
- Evaluate partial-reconfiguration if NN accelerators evolve rapidly; reserve 10–15 MB of SD storage for multiple bitstream variants.

### 5.1 FPGA Fabric Allocation Breakdown

| Function | Control Hart(s) | DSP Blocks | Logic Elements | On-Chip RAM | DMA / Stream Binding | Notes |
|----------|-----------------|------------|----------------|-------------|----------------------|-------|
| Radar ingest + decimation | Zephyr U54_3 | 20 | 8k | 0.5 Mb LSRAM | AXI Stream → DMA0 | Front-end feeds radar lane; tightly coupled to ISR cadence.
| Radar lane A (FIR → FFT) | Zephyr U54_3 | 100 | 17k | 2 Mb LSRAM | DMA0 burst, 256-bit AXI | Primary high-rate path; Zephyr scheduler assumes exclusive DMA ownership.
| Radar lane B (optional parallel path) | Linux U54_1 (optional) | 80 | 15k | 1.5 Mb LSRAM | DMA1 burst, 128-bit AXI | Enable when Linux offloads telemetry and assumes second radar lane; clock-gate when idle.
| Pulse compression + CFAR | Zephyr U54_3 & Linux U54_1 | 40 | 10k | 1 Mb LSRAM | Shared descriptor queue | Shared-stage arbitration handled via OpenAMP mailbox.
| Neural net / camera accelerator | Linux U54_0/U54_1 | 40 | 20k | 6 Mb uSRAM | DMA2 scatter-gather | Supports either CNN or ISP firmware; Linux driver negotiates bandwidth with QNX.
| Health/diagnostic IP | QNX U54_2 | 0 | 2k | 0.1 Mb LSRAM | AXI Lite registers | Exposes performance counters + watchdog windows to safety supervisor.
| Interconnect + CoreAXI4DMA | Shared | 20 | 13k | 0.8 Mb LSRAM | DMA0–DMA3 | Glue logic, descriptor SRAMs, and stream routers for all fabrics.

Keep this document updated as software grows or new workloads (e.g., additional ROS2 nodes) change the budget assumptions.
