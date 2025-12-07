# Hart Software Services (HSS)

Store payload configuration here:

- `payloads/` – Linux images, Zephyr ELFs, FPGA bitstreams ready for bundling (see `payloads/README.md`).
- `manifests/` – YAML configs for the HSS payload generator (e.g., `amp_linux_zephyr.yaml`).
- `scripts/` – Place custom helpers here if the upstream west commands need wrappers.

Link this folder with Yocto deploy artifacts so CI can build turn-key SD card or UART payloads. The repo-level helper `scripts/build/amp_basic.sh` copies Yocto outputs into `payloads/` and invokes `west generate-payload` against the manifests above.
