# Yocto Build Workflow

1. **Source Layers**
   - Vendor BSP: `meta-microchip`, `meta-polarfire-soc`, `meta-microchip-bsp`.
   - Custom layer: `meta-polarfire-nn` (drivers, HAL, apps).
2. **Initialize Build Dir**
   ```sh
   source scripts/env/setup-yocto-env.sh
   oe-init-build-env build-polarfire
   ```
3. **Configure**
   - Copy `yocto/conf/templates/local.conf.sample` and `bblayers.conf.sample` into `build-polarfire/conf/`.
   - Select `mpfs-dev-image` (debug) or `mpfs-prod-image` (deployment) in `local.conf`.
4. **Build**
   ```sh
   bitbake mpfs-dev-image
   ```
5. **Deliverables**
   - HSS payload bundle containing Linux, Zephyr, and FPGA bitstreams.
   - SDK via `bitbake mpfs-dev-image -c populate_sdk`.
6. **Next Steps**
   - Hand artifacts to `scripts/deploy/` utilities for flashing or network boot.
