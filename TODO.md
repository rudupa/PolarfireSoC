# Repository TODO

> Track major tasks required to make the PolarFire SoC learning repo fully functional. Use GitHub issues for detailed tracking; keep this list curated at the top level.

## 1. Tooling & Infrastructure
- [ ] Add CI jobs for linting markdown/docs and validating repo structure.
- [ ] Provide PowerShell + Bash versions of `scripts/env` setup helpers (Yocto, Zephyr, Libero).
- [ ] Implement logging/shared helper library for scripts to standardise output and error handling.

## 2. Yocto Platform
- [ ] Import vendor BSP layers via `yocto/manifests` and document exact revisions.
- [ ] Flesh out `meta-polarfire-nn` with `layer.conf`, recipes for kernel patches, accelerator drivers, HAL libs, and telemetry apps.
- [ ] Add image recipes (`mpfs-dev-image`, `mpfs-prod-image`) plus `wic` layout covering A/B partitions.
- [ ] Integrate HSS payload packaging step into Yocto deploy artifacts.

## 3. Linux Hart (U54_0)
- [ ] Capture kernel defconfig fragments for AMP + radar DSP support under `linux/kernel`.
- [ ] Provide systemd units and configs orchestrating FPGA + accelerator bring-up in `linux/rootfs`.
- [ ] Publish sample userspace tools (CLI + Python) demonstrating accelerator control in `linux/userspace`.

## 4. Zephyr RTOS (U54_1..3)
- [ ] Define custom board overlays for each hart inside `zephyr/boards`.
- [ ] Author baseline applications (`ipc_service_gateway`, `radar_control`, `telemetry_agent`).
- [ ] Create reusable Zephyr modules for shared-memory buffers and radar HAL bindings.
- [ ] Document west workspace initialisation and tie builds into scripts.

## 5. AMP & Inter-Core Messaging
- [ ] Write HSS payload manifests mapping Linux/Zephyr binaries to harts (`bsp/hss`).
- [ ] Implement OpenAMP/IPC Service sample demonstrating Linux↔Zephyr messaging.
- [ ] Specify shared-memory layout + mailbox/interrupt routing in docs and reference headers.

## 6. FPGA / Libero Flow
- [ ] Check in Libero TCL scripts that regenerate the radar DSP design.
- [ ] Automate bitstream exports into `bsp/libero/exports` with version metadata.
- [ ] Provide documentation of AXI/APB interfaces plus DMA descriptors for software teams.

## 7. Simulation & QEMU
- [ ] Create QEMU launcher scripts for Linux-only, Zephyr-only, and integrated AMP runs under `sim/qemu/*`.
- [ ] Hook QEMU smoke tests into CI to catch regressions before hardware deployment.
- [ ] Capture known emulation gaps vs real hardware in `sim/README.md`.

## 8. Documentation
- [ ] Expand architecture docs with diagrams (AMP flow, radar DSP datapath, communication fabric).
- [ ] Add onboarding guide describing end-to-end workflow from cloning repo to first deployment.
- [ ] Maintain troubleshooting section (build failures, HSS payload issues, Zephyr IPC problems).

## 9. QNX Integration
- [ ] Import/port the PolarFire SoC QNX BSP into `qnx/bsp` with hart-aware startup code.
- [ ] Provide sample QNX services demonstrating shared-memory coordination with Linux and Zephyr.
- [ ] Document QNX build + deployment instructions, including how HSS loads all three OSes.
- [ ] Define IPC header files shared among Linux/QNX/Zephyr under `qnx/ipc` and sync them with `docs/architecture/interconnect.md`.
