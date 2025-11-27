# Hart Software Services (HSS)

Store payload configuration here:

- `payloads/` – Linux images, Zephyr ELFs, FPGA bitstreams ready for bundling.
- `manifests/` – JSON/TOML describing hart assignments and boot order.
- `scripts/` – Helpers wrapping Microchip's `hss-payload-generator`.

Link this folder with Yocto deploy artifacts so CI can build turn-key SD card or UART payloads.
