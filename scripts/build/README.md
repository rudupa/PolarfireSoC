# Build Automation

Use this folder for repeatable build entry points:

- `build-yocto.sh` / `.ps1` – wraps BitBake invocations with the correct build directory.
- `build-zephyr.sh` – loops through U54 hart targets for AMP.
- `build-hss-payload.sh` – aggregates Linux, Zephyr, and FPGA bitstreams into a single payload.

Keep scripts parametrised (image name, build dir, hart target) so CI pipelines can reuse them.
