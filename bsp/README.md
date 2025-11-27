# Board Support Package Assets

Anything that configures the PolarFire SoC platform outside of Yocto recipes lives here:

- `hss/` – Hart Software Services payload manifests and build scripts.
- `device-tree/` – DTS overlays plus generated headers consumed by Linux and Zephyr.
- `libero/` – Libero SoC exports, constraints, and build automation for the radar DSP.

Keep authoritative sources here and reference them from Yocto or Zephyr via git submodules or `FILESEXTRAPATHS` entries.
