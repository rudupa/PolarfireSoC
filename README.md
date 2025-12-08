# PolarFire SoC Learning Project

Overview
--------

This project uses Microchip's Yocto BSP and PolarFire SoC toolchain to build a
learning playground for Yocto, BitBake, board support packages, FPGA
integration, neural network acceleration, and the RISC-V architecture. The
reference target is the PolarFire SoC Discovery Kit, but the flow generalises to
custom boards built around MPFS devices.

AMP Hart Allocation
-------------------

- `U54_0` / `U54_1` – Linux SMP pair handling GUI, ROS2, and accelerator control.
- `U54_2` – QNX Neutrino safety/diagnostics supervisor coordinating shared memory.
- `U54_3` – Zephyr RTOS running radar DSP, DMA steering, and near-real-time tasks.

Repository Layout
-----------------

- `docs/` – Architecture notes (AMP, radar DSP, RTOS↔FPGA comms) plus workflow guides for Yocto and Zephyr.
- `scripts/` – Environment, build, and deployment helpers used across Yocto, Zephyr, and HSS flows.
- `yocto/` – Workspace metadata: manifests, layer stubs (`meta-polarfire-nn`), and sample `conf` templates.
- `bsp/` – Hart Software Services payload configs, device-tree overlays, and Libero FPGA sources.
- `zephyr/` – West workspace root for the Zephyr RTOS image assigned to hart U54_3, covering board tweaks, AMP-targeted apps, and reusable modules.
- `linux/` – Kernel patch queues, rootfs overlays (Stage 1 initramfs + Stage 2 ROS2 GUI), and userspace HAL/apps for the Linux SMP harts (U54_0/U54_1).
- `qnx/` – BSP metadata, sample services, and IPC contracts for QNX Neutrino on hart U54_2 alongside Linux and Zephyr in the AMP configuration.
- `docs/workflows/` and `docs/architecture/` (see `docs/architecture/target.md` and `docs/resources_budgeting.md`) capture target hardware specs, resource budgets, and AMP/RR radar DSP guidance referenced in the plan.
- `sim/` – QEMU and emulator assets that replicate Linux-only, Zephyr-only, and integrated AMP boot flows before touching real hardware.

Quickstart
----------

1. **Sync workspaces**
  - `repo init -u yocto/manifests -m default.xml && repo sync` seeds Yocto layers.
  - `west init -l zephyr && west update` pulls Zephyr + modules.
2. **Configure environments**
  - Windows PowerShell: `pwsh -File scripts/env/setup-yocto-env.ps1` or `setup-zephyr-env.ps1`.
  - WSL/Linux: `source scripts/env/setup-yocto-env.sh` and `setup-zephyr-env.sh` to export `MACHINE=mpfs-disco-kit`, `ZEPHYR_BASE`, etc.
3. **Build Yocto Linux (U54_0/U54_1)**
  - `bitbake core-image-full-cmdline` (or future `mpfs-dev-image`) with `local.conf` derived from `yocto/conf/templates/` (the sample already adds the `amp-runtime` package so shared-memory/IPMsg services come preinstalled).
4. **Build Zephyr (U54_3)**
  - `pwsh -File scripts/build/zephyr_amp.sh -b amp_pingpong -H 3` stitches `bsp/device-tree/zephyr/mpfs-amp.overlay` with `zephyr/boards/mpfs_discovery_u54_3.overlay` and runs `west build`.
5. **Assemble HSS payload**
  - `scripts/build/amp_basic.sh --yocto out/ --zephyr build/amp_pingpong` copies artifacts into `bsp/hss`, runs `west generate-payload`, and emits an HSS image matching `bsp/hss/manifests/amp_linux_zephyr.yaml`.

Prerequisites
-------------

- Git 2.40+, Python 3.10+, CMake 3.24+, Ninja, and the `repo` + `west` command-line tools (see `scripts/env/README.md`).
- Zephyr SDK or a RISC-V GNU toolchain in `PATH` for building apps in `zephyr/apps/*`.
- Yocto host packages (Ubuntu example): `sudo apt install gawk wget git diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping libsdl2-dev`. See `docs/workflows/yocto_build.md` for the authoritative list.
- WSL2 + PowerShell 7 if working from Windows; scripts are dual-hosted so both shells share environment helpers.
- Optional: QNX SDP and Libero SoC installations when you are ready to exercise the `qnx/` and `bsp/libero` flows.

Reference Repositories
----------------------

- [Zephyr Applications](https://github.com/polarfire-soc/zephyr-applications) – Zephyr workspace manifest, AMP-ready sample apps, and West extensions (`generate-payload`, `flash-payload`) that wrap the HSS payload generator.
- [PolarFire SoC Documentation](https://github.com/polarfire-soc/polarfire-soc-documentation) – Official Microchip knowledge base covering AMP workflows, HSS payload formats, boot modes, and board-specific guides.
- [meta-mchp](https://github.com/linux4microchip/meta-mchp) – Vendor Yocto layers (`meta-mchp-polarfire-soc`, `meta-mchp-common`) supplying kernel/U-Boot recipes, machine confs, and device trees for MPFS devices.
- [Discovery Kit Reference Design](https://github.com/polarfire-soc/polarfire-soc-discovery-kit-reference-design) – Libero Tcl scripts and MSS configs for generating the Discovery Kit reference bitstream, including optional arguments for HSS updates and accelerator-facing fabric tweaks.

Resource Budgets (Approximate)
------------------------------

| Domain | RAM Minimum | RAM Typical | Flash / Storage Minimum | Flash / Storage Typical | Notes |
|--------|-------------|-------------|-------------------------|-------------------------|-------|
| Linux Stage 1 (kernel + initramfs GUI) | 64 MB | 96 MB | 32 MB | 64 MB | Kernel plus SDL2 framebuffer UI required for ~1.5 s readiness.
| Linux Stage 2 (rootfs + Weston + ROS2) | 700 MB | 1.1 GB | 1.6 GB | 2.0 GB | Includes Yocto rootfs, compositor, ROS2 middleware, and visualization apps.
| QNX (BSP + services) | 64 MB | 128 MB | 128 MB | 256 MB | Covers startup code, resource managers, and deterministic control apps.
| Zephyr (per hart) | 4 MB | 8 MB | 8 MB | 16 MB | OpenAMP-enabled ELFs plus minimal assets loaded via HSS payloads.

These budgets keep overall usage within the Discovery Kit’s 1 GB LPDDR4 and SD/eMMC storage capacity while leaving headroom for telemetry buffers and accelerator data.

Why leverage Microchip's Yocto BSP?
-----------------------------------

- Provides vendor-maintained kernel, U-Boot, and device tree support for the
  PolarFire SoC platform, including clock, DDR, and peripheral bring-up.
- Delivers a validated cross toolchain and sysroots tuned for the MPFS RISC-V
  cores, reducing bootstrap friction compared to rolling a toolchain from
  scratch.
- Ships FPGA-oriented utilities (HSS payload tooling, Libero hooks) that align
  with the Microchip boot architecture.
- Integrates tightly with PolarFire SoC security features, secure boot flows,
  and lifecycle management, which would otherwise demand significant custom
  engineering.

High-Level Architecture
-----------------------

1. **Hardware Layer**
   - PolarFire SoC device with quad RISC-V (U54) application cores and the E51
     monitor core.
   - Discovery Kit carrier board supplying LPDDR4, Gigabit Ethernet, UART,
     and expansion headers (PMOD, mikroBUS) for accelerator I/O.
   - FPGA fabric region programmed with a neural network accelerator (NN
     accelerator), optional DSP blocks, and supporting IP (DMA, AXI interconnect,
     scratchpad RAM).

Target Hardware Specifications
------------------------------

- **SoC**: MPFS095T PolarFire SoC FPGA (≈95K logic elements, 3.8 Mb LSRAM,
  18 Mb uSRAM, 300+ DSP slices) integrating one `E51` monitor core and four
  `U54` 64-bit RISC-V application cores (up to ~667 MHz) with hardware PMP/MMU.
- **Memory**: 1 GB LPDDR4 (32-bit bus) as main memory, 64 MB QSPI NOR flash for
  first-stage boot, and a microSD slot for removable storage or alt rootfs.
- **Connectivity**: Single Gigabit Ethernet port, USB 2.0 OTG (Type-C), three
  UART ports (console + expansion), mikroBUS and dual PMOD headers, plus CAN-FD
  and I²C/SPI general-purpose headers.
- **Clocking & Power**: On-board programmable PLLs and regulators sized for
  FPGA accelerators, powered from 12 V DC or USB-C PD.
- **Debug & Trace**: Dedicated JTAG for MSS and FPGA, on-board USB-to-UART
  bridge, SmartDebug fabric monitor access, and GPIO test headers.

2. **Boot and SoC Management**
   - Hart Software Services (HSS) responsible for loading the FPGA bitstream,
     setting up clocking, and launching the Linux payload on the U54 cores.
   - Optional trusted boot chain leveraging eMMC/QSPI with signed payloads.

3. **Yocto Build System**
   - Base distro: Microchip BSP layers (`meta-microchip`, `meta-polarfire-soc`).
   - Custom layer: `meta-polarfire-nn` extending vendor recipes with accelerator
     drivers, userspace libraries, and example applications.
   - Build configurations: one for developer images (SSH, debug tools) and one
     for deployment images (read-only rootfs, OTA hooks).

4. **Software Stack**
   - Linux kernel from Microchip BSP with device-tree overlays enabling the NN
     accelerator, AXI bridges, DMA engines, and optional DSP soft IP.
   - Userspace components packaged via BitBake: 
     - Accelerator kernel module (out-of-tree if required).
     - Userspace HAL/driver library exposing ioctl or RPC interface.
     - Sample RISC-V applications and Python bindings for inference workflows.
     - Telemetry and diagnostics tools for monitoring accelerator performance.
   - Optional container runtime (Podman) for portable ML workloads.

5. **FPGA & Accelerator Tooling**
   - Libero SoC project describing the accelerator, using DSP slices and
     inference-friendly datapaths.
   - Exported bitstream packaged as an HSS payload, consumed during boot or
     delivered via dynamic partial reconfiguration.
   - Synthesis scripts capture neural network model quantisation and mapping to
     FPGA resources, with optional integration to frameworks (e.g., FINN,
     hls4ml).

6. **Development Workflow**
   - Use Yocto to generate images, SDKs, and rootfs overlays.
   - Deploy bitstreams and firmware using HSS and HSS payload utility.
   - Cross compile NN workloads with the Yocto SDK, run profiling on-board, and
     iterate on accelerator design through Libero+Yocto integration.

Relevant Architecture Patterns
------------------------------

- **Split Filesystem and Payload Delivery**: Pair a minimal rootfs (for fast
  boot and system services) with a secondary partition or artifact carrying the
  ML models and accelerator binaries. Useful for OTA updates and rollback.
- **Service-Oriented Boot Pipeline**: Use systemd to serialise hardware init
  orders, ensuring the FPGA accelerator and supporting drivers are ready before
  inference services start.
- **A/B System Partitions**: Maintain redundant root partitions so that
  experiments with accelerator firmware or NN stacks can roll back safely.
- **Data Governance & Telemetry Bus**: Route accelerator metrics (latency,
  throughput, thermal sensors) into an edge-to-cloud telemetry pipeline for
  DSP and ML workload analysis.
- **Hardware Abstraction Layer**: Wrap accelerator functionality behind a HAL
  that exposes standard interfaces to RISC-V applications, easing experimentation
  with different accelerator revisions.

Next Exploration Steps
----------------------

1. Clone Microchip's Yocto BSP and study the layer structure (`meta-polarfire-soc`,
   `meta-microchip-bsp`).
2. Create `meta-polarfire-nn` with recipes for the accelerator driver, HAL,
   sample inference application, and telemetry agent.
3. Draft a Libero project instantiating a simple neural network accelerator,
   and script its generation for integration with the Yocto build (bitstream
   packaging and deployment hooks).
4. Define an OTA/update story (SWUpdate or RAUC) aligned with the A/B partition
   pattern.
5. Document profiling workflows that measure accelerator throughput versus
   pure RISC-V or DSP implementations, validating architecture choices.
