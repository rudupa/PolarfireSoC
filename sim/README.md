# Simulation Workspace

Use this area for emulator- and QEMU-based validation when hardware is unavailable.

Recommended layout:

- `qemu/linux/` – Scripts, configs, and disk images for booting the Yocto-built Linux image on QEMU (e.g., mpfs emulation or generic RISC-V virt).
- `qemu/zephyr/` – Zephyr-specific simulations, including multi-hart OpenAMP tests.
- `qemu/amp/` – Integrated scenarios that boot Linux on hart0 and Zephyr payloads on the remaining harts to validate AMP interactions.
- `assets/` – Prebuilt images, device trees, or helper binaries shared across simulations.

Document how each scenario maps to real hardware limitations (e.g., which peripherals are stubbed or simulated) so results can be interpreted correctly.
