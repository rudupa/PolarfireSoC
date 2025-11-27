# Stage 2 ROS2 + Weston Rootfs

This directory contains the full-featured filesystem pieces loaded after the fast-boot UI is already running.

Store:
- `fstab` snippets and mount units to attach SD/eMMC partitions.
- Systemd services (`weston.service`, `ros2-core.service`, etc.).
- ROS2 workspace overlays, colcon build scripts, and visualization assets.
- Handoff scripts that notify Stage 1 when the compositor/ROS2 UI is ready.

The Stage 2 image can be larger and depend on networked resources; prioritize robustness and integration with ROS2 tooling.
