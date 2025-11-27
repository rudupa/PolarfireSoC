# Linux Workspace

Linux content complements the Yocto recipes and captures sources that may not belong inside a BitBake layer yet.

- `kernel/` – Patch queues, defconfigs, and helper scripts for Microchip's kernel tree.
- `rootfs/` – Systemd units, configuration overlays, and scripts staged into the image.
- `userspace/` – Standalone apps, HAL libraries, or diagnostic utilities meant to run on Linux U54_0.

## Fast-Boot GUI Strategy

Linux on U54_0 follows a two-stage boot plan:

1. **Stage 1 (Initramfs + SDL2)** – stored under `rootfs/stage1/`; minimal BusyBox environment that launches the critical framebuffer UI within ~1.5 seconds after reset.
2. **Stage 2 (ROS2 + Weston)** – assets live in `rootfs/stage2/`; once secondary storage is mounted, Weston compositor and ROS2 visualization apps start, eventually replacing or augmenting the Stage 1 UI.

See `docs/workflows/linux_fast_boot.md` for build and deployment details.
