# Linux Fast-Boot GUI Workflow

Two-stage boot strategy for U54_0 (Linux) so user-critical UI appears ~1.5 s after power-on while the richer ROS2 experience comes online later.

## Stage 1 – Initramfs + SDL2 Framebuffer UI

1. **Initramfs Build**
   - Create a minimal Yocto image (or custom `initramfs` recipe) containing:
     - BusyBox + udev minimal services.
     - SDL2 runtime and critical UI application binaries.
     - Lightweight framebuffer drivers (no compositor).
   - Mount only tmpfs/ramfs; no external storage.
2. **Boot Flow**
   - Kernel boots with `root=/dev/ram0` referencing the baked-in initramfs.
   - `init` script launches `stage1-gui.service`, which:
     1. Sets framebuffer mode (`fbset` or DRM KMS helper).
     2. Starts SDL2 app that provides the immediate UX (status, safety controls, etc.).
   - Target readiness goal: ≤1.5 s from reset (per boot logs).
3. **Handoff Hooks**
   - Stage 1 exports a watchdog FIFO or shared memory block so Stage 2 can notify it when to exit.
   - Service monitors `/run/stage2.ready` flag to know when richer UI is prepared.

## Stage 2 – Persistent Rootfs + Weston/ROS2

1. **Mount Secondary Root**
   - Systemd unit `stage2-root.mount` attaches eMMC/SD partition containing the full Yocto filesystem.
   - Overlays `/usr`, `/var`, and `/home` or pivot-root entirely (using `switch_root`).
2. **Services Launched**
   - Weston's compositor (`weston.service`) to host GTK/Qt apps.
   - ROS2 core stack (`ros2-daemon`, `colcon`-built nodes) for visualization/telemetry.
   - Optional container runtime if ROS2 runs in containers.
3. **Coordination**
   - Once ROS2 UI is ready, Stage 2 signals Stage 1 via shared file/socket; Stage 1 either hides, hands off display buffer, or terminates.
   - Use systemd targets: `stage1.target` (default) and `stage2.target` (pulled in after mass-storage available).

## Deployment Checklist

- **Yocto Recipes**
  - `image-stage1-initramfs.bb` → builds initramfs with SDL2 app.
  - `image-stage2-rootfs.bb` → full distro with Weston + ROS2.
- **Systemd Units**
  - `stage1-gui.service`, `stage2-root.mount`, `stage2.target`, `weston.service`, `ros2-core.service`.
- **Scripts**
  - `scripts/rootfs/pivot-to-stage2.sh` handles switch_root once stage2 partition is mounted.
  - `scripts/rootfs/notify-stage1.sh` triggers Stage 1 exit.
- **Testing**
  - Use QEMU to validate Stage 1 timing with `rdinit` pointing to SDL2 app stub.
  - Measure real hardware boot logs to ensure <1.5 s for Stage 1.

Update `linux/rootfs/stage1` and `stage2` folders with configs, units, and assets as they become available.

  ## Resource Budget (RAM / Flash)

  | Component | RAM Minimum | RAM Typical | Flash/Storage Minimum | Flash/Storage Typical | Notes |
  |-----------|-------------|-------------|-----------------------|-----------------------|-------|
  | Stage 1 Initramfs (kernel + SDL2 app) | 64 MB | 96 MB | 32 MB | 64 MB | Kernel + initramfs loaded to RAM; keep binaries <40 MB to minimize load time. |
  | SDL2 Critical GUI Assets | 8 MB | 16 MB | 8 MB | 16 MB | Textures/fonts/audio bundled inside initramfs image. |
  | Stage 2 Rootfs Base (Yocto) | 256 MB | 384 MB | 1.2 GB | 1.5 GB | Rootfs stored on SD/eMMC; RAM footprint includes system services and Weston compositor. |
  | Weston + GTK/Qt Shell | 128 MB | 192 MB | — | — | Runs after storage mount; depends on theme assets. |
  | ROS2 Core + Visualization Nodes | 256 MB | 512 MB | 400 MB | 600 MB | DDS middleware + Python nodes + logs. |
  | Overall Linux Hart (Stage 2 active) | ~700 MB | ~1.1 GB | ~1.6 GB | ~2.0 GB | Ensures headroom for telemetry buffers and caching; within 1 GB LPDDR4 but leaves limited space for other processes. |

  Notes:
  - Measurements assume stripped binaries and zstd-compressed rootfs images; adjust upward if debug symbols or extra ROS2 packages are needed.
  - Flash numbers refer to persistent storage (SD/eMMC). Keep Stage 1 small because it is bundled into the kernel image and lives in QSPI/SD boot partition.
