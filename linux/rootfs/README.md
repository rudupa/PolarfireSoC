# Root Filesystem Assets

Use this directory for:

- `systemd/` unit files that orchestrate accelerator bring-up order.
- `configs/` for network, telemetry, and security settings.
- `scripts/` executed during post-install or OTA updates.
- `stage1/` and `stage2/` folders implementing the fast-boot GUI strategy described in `docs/workflows/linux_fast_boot.md`.

Symlink or copy these assets into Yocto recipes via `FILESEXTRAPATHS`.
