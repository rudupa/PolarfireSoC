# QNX BSP Assets

- Store the PolarFire SoC BSP port exported from QNX SDP (startup code, hwinfo files, pinmux configs).
- Track patches that align hart assignments with the HSS AMP layout (Linux on `u54_0/u54_1`, QNX on `u54_2`, Zephyr on `u54_3`).
- Include scripts that package QNX images into HSS payload slots or SD card partitions.

Keep sensitive or licensed binaries out of the repo; check in only the metadata and scripts needed to reproduce the BSP when the SDP is available.
