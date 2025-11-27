# Scripts

Helper scripts live here, grouped by responsibility to keep Yocto, Zephyr, and deployment workflows reproducible. Scripts should be idempotent and runnable from Windows PowerShell or WSL when possible.

- `env/` – Environment setup (toolchains, west, Yocto variables).
- `build/` – Automation for Yocto/Zephyr builds.
- `deploy/` – Flashing, SD card prep, and HSS payload delivery.
