# Memory Layout Proposal

Defines how DDR, scratchpads, and shared memory regions are partitioned across Linux, QNX, Zephyr, and FPGA accelerators on the PolarFire SoC Discovery Kit. Addresses both static reservations (HSS/device tree) and runtime allocations.

## 1. DDR Partition Overview
| Region | Start Address (example) | Size | Owner | Purpose |
|--------|-------------------------|------|-------|---------|
| `0x8000_0000` | 0x8000_0000 | 128 MB | Linux (Stage 1) | Kernel + initramfs image, temporary framebuffer buffers. |
| `0x8800_0000` | 0x8800_0000 | 512 MB | Linux (Stage 2) | Rootfs runtime heap, Weston/ROS2 processes, page cache. |
| `0xA800_0000` | 0xA800_0000 | 128 MB | QNX | Deterministic control loops, IPC staging buffers. |
| `0xB000_0000` | 0xB000_0000 | 128 MB | Zephyr | Dedicated to U54_3 for radar DMA descriptors, stacks, and telemetry buffers (Linux can borrow via CMA if Zephyr idle). |
| `0xB800_0000` | 0xB800_0000 | 64 MB | Shared IPC | OpenAMP shared memory, mailbox queues, ROS2 ↔ QNX bridge. |
| `0xBC00_0000` | 0xBC00_0000 | 64 MB | FPGA DMA buffers | Radar DSP output, NN accelerator data staging. |
| `0xC000_0000+` | remaining | 64 MB | Reserved | Future growth / debug.

> Addresses are illustrative; finalize once linker scripts and device tree reservations are available. Keep regions aligned to 64 MB boundaries for MPU configuration.

## 2. Scratchpad & Cache Usage
- **L2 Scratchpad (128 KB)** – shared by Linux, QNX, Zephyr for high-priority descriptors. Allocate 32 KB slices per OS plus 32 KB common pool for interrupt mailboxes.
- **Coherency Considerations** – Enable cache maintenance routines when FPGA masters write into shared regions. Linux drivers should map DMA buffers as uncached or use `dma_alloc_coherent`.

## 3. Shared Memory Map
| Block | Size | Users | Notes |
|-------|------|-------|-------|
| OpenAMP RPMsg pool | 16 MB | Linux ↔ Zephyr | Backed by vrings; map to `0xB800_0000`. |
| QNX ↔ Linux Mailbox | 8 MB | Linux ↔ QNX | Provides message structs + doorbell flags; align to cache lines. |
| Telemetry Buffer | 16 MB | All OSes | Circular buffer for metrics streaming to Linux.
| FPGA Command Queue | 8 MB | Linux/QNX ↔ FPGA | Memory-mapped descriptors consumed by DMA engines.

## 4. Boot-Time Reservations
- **Device Tree** – Reserve shared regions using `reserved-memory` nodes; expose phandles to Linux drivers and Zephyr board overlays.
- **HSS Payload** – Provide `.json/.toml` manifest entries that pass base addresses/size to each hart via boot arguments.

## 5. Future Enhancements
1. **Dynamic Rebalancing** – Investigate CMA (Linux) or memory pools to reclaim unused Zephyr/QNX regions when ROS2 needs bursts.
2. **Security** – Apply PMP/MMU permissions so each hart only touches assigned memory, except shared regions.
3. **Partial Reconfiguration Buffers** – Reserve extra 32 MB if FPGA bitstreams must be staged in DDR before applying.

Update this proposal with actual linker scripts, MPU settings, and measured usage once software is integrated.
