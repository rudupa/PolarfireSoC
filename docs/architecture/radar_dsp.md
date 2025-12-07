# Radar DSP on FPGA

Libero SoC hosts the radar-oriented signal-processing chain. Planned building blocks:

- FIR filters for front-end conditioning.
- FFT blocks for range/Doppler processing.
- Pulse-compression and detection modules tuned for the target waveform set.

Integration tasks:

1. Define AXI/APB interfaces from fabric to MSS (Microprocessor Subsystem) for control and status.
2. Choose CoreAXI4DMA or CoreAXI4Stream IP blocks for high-rate data moves into LPDDR4.
3. Provide DMA or MMIO pathways so Linux (U54_0/U54_1), QNX (U54_2), and Zephyr (U54_3) can stream data in/out.
4. Capture versioned Libero project files plus export scripts so Yocto builds can package bitstreams alongside HSS payloads.


# Radar Processing Pipeline

This document describes the layered radar signal processing pipeline implemented on the PolarFire SoC platform, detailing the responsibilities and data flow across hardware, FPGA, and software domains.

---

## 1. External Radar Front-Ends (4x)

- **Antennas:** TX/RX arrays for signal transmission and reception.
- **RF/IF Chain:** Low-noise amplifiers (LNA), mixers, amplifiers for analog signal conditioning.
- **ADC Digitization:** Raw data acquisition from analog signals.
- **Control:** Managed via SPI/I²C from the SoC.

---

## 2. PolarFire SoC FPGA Fabric

- **Interference Suppression:** Filters and cancellation blocks for signal cleaning.
- **FIR / FFT / Pulse Compression:** Core DSP operations for radar signal processing.
- **Optional Angle Estimation:** Additional processing for spatial resolution.
- **DMA Channels:** Dedicated DMA per radar lane for efficient data transfer to RTOS.

---

## 3. Zephyr RTOS (U54_3)

- **DMA Servicing & ISR Handling:** Real-time management of DMA interrupts and data movement.
- **Radar Cube Assembly:** Constructs range × Doppler × angle data cubes.
- **Timestamp Alignment & Buffering:** Ensures temporal consistency and prepares data for validation.

---

## 4. QNX Neutrino (U54_2)

- **Safety Supervisor:** Monitors and validates radar cube data.
- **Validation:** Checks plausibility and integrity of processed radar data.
- **Policy Enforcement:** Enforces rate limits and fail-safe mechanisms for system reliability.

---

## 5. Linux (U54_0 / U54_1)

- **ROS2 Fusion:** Integrates radar, camera, and IMU data for advanced perception.
- **Point Cloud Generation:** Builds spatial representations for visualization and further processing.
- **Visualization:** Uses SDL2/GTK/Qt on Weston compositor for GUI display.
- **Telemetry & Networking:** Handles external communications and data logging.

---

## Data Flow Summary

1. **Raw data** is acquired by external radar front-ends and digitized.
2. **FPGA fabric** performs initial DSP and passes processed data via DMA.
3. **Zephyr RTOS** assembles radar cubes and aligns timestamps.
4. **QNX Neutrino** validates data integrity and enforces safety policies.
5. **Linux** fuses radar with other sensors, generates point clouds, visualizes results, and manages networking.

---

## References

- See [`system_architecture.md`](system_architecture.md) for core allocation and responsibilities.
- See [`resources_budgeting.md`](../resources_budgeting.md) for resource allocation details.

Theoretically, the PolarFire SoC Discovery Kit (MPFS095T) can handle:

Antennas (channels):
With 1 GB LPDDR4 RAM, 95k FPGA logic elements, 300+ DSP slices, and ~7 Gbps LVDS/JESD204B bandwidth, you can typically support 8–16 channels at 12–16 bits, 5–10 MSPS per channel, per radar lane, with 4 radar lanes.
For higher channel counts (e.g., 32), you quickly approach FPGA resource and DDR bandwidth limits—especially if you want real-time FIR/FFT/pulse compression and buffering for all lanes.

Data size:
For 16 channels × 12 bits × 10 MSPS = ~1.92 Gbps per lane, 4 lanes = ~7.68 Gbps aggregate.
The FPGA can process this if you optimize pipeline concurrency and memory layout, but RAM for buffering and CPU for post-processing become bottlenecks above 16 channels.

Summary:

8–16 channels per lane is practical for real-time radar DSP and fusion on this kit.
32 channels is possible for raw acquisition, but may require reduced sample rates, more FPGA offload, and careful resource budgeting.
Always validate with your actual FPGA design and memory usage—real-world limits depend on your DSP pipeline complexity and buffer sizes.