# Stage 1 Initramfs UI

Artifacts stored here build the ultra-fast boot image that launches directly from initramfs.

Include:
- `init` scripts (BusyBox or systemd) that set up framebuffer + SDL2 app.
- Minimal configs for DRM/KMS or framebuffer selection.
- SDL2 assets/binaries for the critical GUI.
- Hooks to signal Stage 2 readiness (FIFO, socket, file flag).

Keep binaries size-constrained to maintain ~1.5 s GUI readiness.
