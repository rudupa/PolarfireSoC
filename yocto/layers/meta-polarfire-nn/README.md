# meta-polarfire-nn

Custom Yocto layer that packages PolarFire-specific accelerator components:

- Kernel/device-tree patches for radar DSP and NN IP blocks.
- Out-of-tree accelerator driver modules.
- Userspace HAL libraries and Python bindings.
- Example inference + telemetry applications.

The layer already ships with:

- `conf/layer.conf` – standard metadata wiring + kirkstone compatibility guard.
- `conf/machine/mpfs-amp.conf` – thin wrapper over Microchip's `mpfs-dev-kit` that encodes hart assignments and shared-memory carve-outs for AMP.
- `recipes-kernel/linux/linux-microchip_%.bbappend` – appends the shared-memory/device-mailbox overlay and merges `linux/kernel/fragments/mpfs_amp.fragment` so Linux reserves the DDR window consumed by Zephyr/OpenAMP while enabling RPMsg/SMP tracing options.
- `recipes-core/amp-runtime/amp-runtime.bb` – installs the shared-memory prep + RPMsg gateway systemd units/scripts from `linux/rootfs` and auto-enables them in the image.
- `classes/amp-payload.bbclass` – adds a post-processing hook that calls `scripts/build/amp_basic.sh` to bundle Linux + Zephyr artifacts into an HSS payload once BitBake finishes an image.

Next steps: introduce recipes (`recipes-*`) for accelerator drivers, userland HALs, and the Linux/Zephyr IPC demo app.
