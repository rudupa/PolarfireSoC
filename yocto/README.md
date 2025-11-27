# Yocto Workspace

This directory houses everything needed to build PolarFire SoC images with Microchip's BSP plus the custom `meta-polarfire-nn` layer.

Recommended layout:

- `manifests/` – Repo/manifest files that pin BSP revisions.
- `layers/` – Local layers checked into this repository (custom content only).
- `conf/templates/` – Sample `local.conf` and `bblayers.conf` for new build dirs.
- `artifacts/` – Optional drop zone for build outputs staged for deployment.

Instructions for running BitBake live under `docs/workflows/yocto_build.md`.
