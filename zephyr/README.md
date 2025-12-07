# Zephyr Workspace

This directory doubles as the west workspace root for the AMP Zephyr image that runs on U54_3 (with optional overrides if we temporarily repurpose another hart).

Usage:

1. Initialize west with the local manifest: `west init -l . && west update`.
2. Zephyr v4.0.0 plus Microchip's HAL is fetched via `zephyr/west.yml`.
3. The upstream `polarfire-soc/zephyr-applications` repo is pulled under `modules/zephyr-applications` to reuse its `generate-payload` / `flash-payload` west extensions.
4. Pass the repo-level shared-memory overlay (`bsp/device-tree/zephyr/mpfs-amp.overlay`) plus `zephyr/boards/mpfs_discovery_u54_3.overlay` via `-DDTC_OVERLAY_FILE=overlay_a;overlay_b` so the Zephyr hart lands on the canonical DDR carve-out and records its mailbox metadata (swap `_3` only if you intentionally retarget another hart).

Proposed layout:

- `boards/` – Custom board definitions or overlays derived from `mpfs_dev_kit` with hart-specific tweaks.
- `apps/` – Example applications (IPC service gateway, radar control tasks, telemetry clients). `ipc_service_gateway` now registers the RPMsg endpoint expected by the Linux RPMsg char service.
- `modules/` – Optional Zephyr modules or shields that wrap shared components (e.g., radar HAL, shared-memory APIs).

Keep build instructions synced with `docs/workflows/zephyr_amp.md`, which covers overlay usage (shared + per-hart) and the `amp_pingpong` sample configuration.
