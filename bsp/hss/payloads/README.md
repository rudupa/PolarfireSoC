# HSS Payload Artifacts

Drop build outputs here before invoking the west `generate-payload` command.

Recommended structure:

- `linux/` – Kernel image (`Image`), OpenSBI (`fw_dynamic.bin`), device tree blobs, initramfs/rootfs artifacts produced by Yocto.
- `zephyr/` – Optional staging area if you prefer copying Zephyr ELFs out of `zephyr/build/`.
- `build/` – Generated payload binaries (e.g., `amp-linux-zephyr.bin`).

Artifacts in this folder are consumed by the manifest files under `../manifests/`.
