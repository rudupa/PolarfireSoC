# Zephyr Workspace

This directory doubles as the west workspace root for the AMP Zephyr images that run on U54_1..3.

Proposed layout:

- `boards/` – Custom board definitions or overlays derived from `mpfs_dev_kit` with hart-specific tweaks.
- `apps/` – Example applications (IPC service gateway, radar control tasks, telemetry clients).
- `modules/` – Optional Zephyr modules or shields that wrap shared components (e.g., radar HAL, shared-memory APIs).

Keep build instructions synced with `docs/workflows/zephyr_amp.md`.
