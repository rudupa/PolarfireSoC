# Environment Scripts

Place shell or PowerShell helpers here:

- `setup-yocto-env.sh` / `.ps1` – export `TEMPLATECONF`, `MACHINE=mpfs-amp`, and `DISTRO=polarfire-amp` before running `oe-init-build-env`.
- `setup-zephyr-env.sh` / `.ps1` – set `ZEPHYR_WORKSPACE`, `ZEPHYR_BASE`, and `WEST_CONFIG`, plus hint if `.west/` has not been initialised.
- `setup-libero-env.sh` / `.ps1` – define `LIBERO_PROJECT_ROOT`, `LIBERO_DESIGN_SCRIPTS`, and locate the HSS payload generator blobs used by Libero + HSS workflows.

Document prerequisites and expected environment variables inside each script.
