# Target Platform Specification

Comprehensive description of the reference hardware (PolarFire SoC Discovery Kit) that underpins the hybrid Linux/QNX/Zephyr AMP platform.

## 1. Hardware Overview
- **Board**: PolarFire SoC Discovery Kit (MPFS095T-1FCVG784E device).
- **Primary Use Case**: Mixed-criticality radar/NN workloads with FPGA acceleration plus asymmetric multiprocessing (Linux + QNX + Zephyr).
- **Key Hardware Blocks**
  - **E51 Monitor Core** – Supervises boot and low-level services.
  - **Four U54 Application Cores** – 64-bit RV64GC w/ L1 caches, shared L2 (2 MB) and DDR4 controller.
  - **FPGA Fabric** – ~95k logic elements, DSP slices for FIR/FFT, CoreAXI DMA, custom accelerators.

## 2. Core Allocation Roadmap
| Hart | Default Role | Notes |
|------|--------------|-------|
| E51  | Hart Software Services (HSS) | Loads FPGA bitstream, sequences hart startup. |
| U54_0 | Linux | Stage 1/Stage 2 Yocto image with GUI, networking, ROS2, accelerator control. |
| U54_1 | Linux (SMP peer) | Shares ROS2 workloads, telemetry services, and accelerator orchestration with U54_0. |
| U54_2 | QNX Neutrino | Safety-critical control loops; supervises shared memory/mailboxes. |
| U54_3 | Zephyr RTOS | Radar control plane, DMA programming, telemetry helper. |

HSS payload manifests, device trees, and scripts are locked to this allocation to keep every OS aligned.

## 3. Memory & Storage
- **LPDDR4**: 1 GB (32-bit bus) accessible to all U54 cores and FPGA DMA masters.
- **L2 Cache**: 2 MB shared.
- **Scratchpad**: 256 KB coherent cache (L2 coherent fabric) for real-time exchanges.
- **Non-Volatile**: 64 MB QSPI NOR for first-stage boot; microSD slot for Yocto images, HSS payloads, and data logging.
- **Shared Memory Map**: Reserve carve-outs for Linux/QNX/Zephyr IPC queues and FPGA DMA buffers; document in `qnx/ipc`.

## 4. On-Board Peripherals
- Gigabit Ethernet PHY (RGMII) – default Linux networking path.
- USB 2.0 OTG (Type-C) – supports gadget or host modes.
- UARTs (at least 3) – console, HSS monitor, and user diagnostics.
- mikroBUS + dual PMOD headers – attach radar front-end boards or other sensors.
- CAN-FD, I²C, SPI headers – low-speed control interfaces.
- GPIO banks for debug and accelerator control pins.
- JTAG connectors for MSS + FPGA.

## 5. Jumpers & Power
| Jumper | Default | Purpose |
|--------|---------|---------|
| JP1 | 1-2 closed | Sets bank & IO voltages (1.8 V for MSS I/O). |
| JP2 | 1-2 closed | Enables 5 V to sensor header. |
| JP3 | 2-3 closed | Route USB-C power to board. |
| JP4 | 2-3 closed | Selects 3.3 V for GPIO/mikroBUS. |
| JP5 | 1-2 closed | Boot mode selection (SD). |
| JP7 | 2-3 closed | UART routing to USB bridge. |
| JP8 | 1-2 closed | Sensor supply at 5 V. |

Reference quickstart guide for complete jumper matrix when changing boot modes or IO standards.

## 6. Boot & Software Stack
1. **HSS (E51)**
   - Initializes clocks, PLL, DDR, and loads Libero FPGA bitstream.
   - Launches Linux, QNX, and Zephyr payloads per manifest.
2. **Linux on U54_0/U54_1**
   - Built via Yocto BSP (Microchip `meta-polarfire-soc` + custom `meta-polarfire-nn`).
   - Hosts accelerator drivers, telemetry services, and networking.
3. **QNX on U54_2**
   - BSP derived from QNX SDP; packaged into HSS payload slot.
   - Provides deterministic control loops and resource managers bridging to Linux/Zephyr.
4. **Zephyr on U54_3**
   - West-based builds targeting hart-specific board configs.
   - Implements radar control, DMA coordination, and telemetry collection for the single RTOS hart.

## 7. FPGA Acceleration Plan
- **Blocks**: FIR filters, FFT stages, pulse compression, neural net accelerator modules.
- **Interfaces**: CoreAXI4DMA/CoreAXI4Stream for bulk transfers; APB/AXI-Lite for control.
- **Tool Flow**: Libero SoC, SoftConsole for bare-metal tests, HSS payload bundling.
- **Data Path**: Radar data enters via PMOD/mikroBUS or LVDS mezzanine → FPGA DSP chain → shared DDR buffers → processed by Linux/QNX/Zephyr.

## 8. Simulation & Validation
- **QEMU Linux**: Boot Yocto image on `virt` board for kernel/driver validation.
- **QEMU Zephyr**: Run AMP OpenAMP demos per hart.
- **Integrated AMP Sim**: Validate HSS manifest launching Linux+QNX+Zephyr; use shared-memory stubs when FPGA blocks unavailable.

## 9. Tooling Checklist
| Tool | Purpose | Location/Notes |
|------|---------|----------------|
| Libero SoC | FPGA design + synthesis | See `bsp/libero`. Requires license (free for kit). |
| SoftConsole | Bare-metal debug, initial BSP work | Use for low-level bring-up/testing. |
| Yocto BSP | Linux image generation | `yocto/` workspace; mirror of Microchip BSP + custom layer. |
| QNX SDP | QNX BSP + Momentics | Required for `qnx/` builds. |
| HSS Payload Generator | Bundles OS images + bitstreams | Scripts in `bsp/hss`. |
| West + Zephyr SDK | Zephyr builds | `zephyr/` workspace. |

## 10. Reference & Resources
- **Discovery Kit Hardware User Guide** – Board-level overview, schematics pointer.
- **Board Files (Allegro, schematics)** – Layout reference for signal integrity.
- **YouTube: Using the Discovery Kit** – Quickstart video to confirm hardware setup.
- **PolarFire SoC Bare Metal Example & Github Repo** – Sample HSS payloads and MSS examples.
- **PolarFire SoC Yocto BSP** – Official BSP documentation & release notes.
- **AMP on PolarFire SoC** – Application note covering hart partitioning strategies.
- **Libero SoC Design Suite User Guide** – FPGA toolchain instructions.
- **PFSoC Knowledge Base & Reference Manual** – Deep dives into MSS peripherals, event fabric, and security.

Track document updates as hardware revisions or tool versions change to keep the target spec current.
