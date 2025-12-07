# Linux Workspace

Linux content complements the Yocto recipes and captures sources that may not belong inside a BitBake layer yet.

- `kernel/` – Patch queues, defconfigs, and helper scripts for Microchip's kernel tree.
- `rootfs/` – Systemd units, configuration overlays, and scripts staged into the image.
- `userspace/` – Standalone apps, HAL libraries, or diagnostic utilities meant to run on the Linux harts (U54_0/U54_1).

### Current Assets

- `kernel/fragments/mpfs_amp.fragment` extends the vendor defconfig with SMP, RPMsg, DMA buffer, and tracing options expected by the AMP layout. Merge it with `scripts/kconfig/merge_config.sh` and feed the result into the Yocto recipe.
- `rootfs/systemd/amp-shmem.service` + `rootfs/systemd/zephyr-ipc-gateway.service` ensure shared-memory metadata is exported and an RPMsg endpoint (backed by `/run/amp/ipc_gateway.cmd` + `/run/amp/ipc_gateway.log`) is available before higher-level services start. Their helper scripts live under `rootfs/scripts/` and should be packaged into `/usr/libexec/amp/` by Yocto.
- Yocto integrates these assets via the `amp-runtime` recipe so every `mpfs-amp` image automatically enables the services.

## Fast-Boot GUI Strategy

Linux on U54_0/U54_1 follows a two-stage boot plan (SMP pair shares the workload):

1. **Stage 1 (Initramfs + SDL2)** – stored under `rootfs/stage1/`; minimal BusyBox environment that launches the critical framebuffer UI within ~1.5 seconds after reset.
2. **Stage 2 (ROS2 + Weston)** – assets live in `rootfs/stage2/`; once secondary storage is mounted, Weston compositor and ROS2 visualization apps start, eventually replacing or augmenting the Stage 1 UI.

See `docs/workflows/linux_fast_boot.md` for build and deployment details.
