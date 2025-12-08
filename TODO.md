# Repository TODO

> Track major tasks required to make the PolarFire SoC learning repo fully functional. Use GitHub issues for detailed tracking; keep this list curated at the top level.

## Hart Allocation Reference
- Linux SMP: U54_0 + U54_1
- QNX Neutrino: U54_2
- Zephyr RTOS: U54_3

## 1. Tooling & Infrastructure
- [ ] Add CI jobs for linting markdown/docs and validating repo structure.
 - [x] Provide PowerShell + Bash versions of `scripts/env` setup helpers (Yocto, Zephyr, Libero).
	- [x] Bash: `scripts/env/setup-yocto-env.sh` exports `MACHINE=mpfs-disco-kit` defaults.
	- [x] Bash: `scripts/env/setup-zephyr-env.sh` wires `ZEPHYR_WORKSPACE`, `ZEPHYR_BASE`, and `WEST_CONFIG`.
	- [x] Bash: `scripts/env/setup-libero-env.sh` captures Libero + HSS payload generator paths.
	- [x] PowerShell: `setup-yocto-env.ps1`, `setup-zephyr-env.ps1`, and `setup-libero-env.ps1` mirror the same variables under Windows.
- [ ] Implement logging/shared helper library for scripts to standardise output and error handling.

## 2. Yocto Platform
- [ ] Import vendor BSP layers via `yocto/manifests` and document exact revisions.
	- [x] Added `yocto/manifests/default.xml` pointing at Poky, meta-openembedded, and `linux4microchip/meta-mchp`.
	- [x] Recorded pinned revisions/SHAs in `docs/workflows/yocto_build.md`.
- [ ] Flesh out `meta-polarfire-nn` with `layer.conf`, recipes for kernel patches, accelerator drivers, HAL libs, and telemetry apps.
	- [x] Added `conf/layer.conf` and `conf/machine/mpfs-amp.conf` with hart layout variables.
	- [x] Added `recipes-kernel/linux/linux-microchip_%.bbappend` + overlay sources to keep Linux reserved-memory in sync with `include/amp/shmem_layout.h`.
	- [ ] Implement kernel/device-tree/driver recipes plus userspace packages.
- [ ] Add image recipes (`mpfs-dev-image`, `mpfs-prod-image`) plus `wic` layout covering A/B partitions.
- [ ] Integrate HSS payload packaging step into Yocto deploy artifacts.
	- [x] Provide standalone helper `scripts/build/amp_basic.sh` to assemble Yocto + Zephyr artifacts into a payload.
	- [x] Added `classes/amp-payload.bbclass` and enabled it via `local.conf.sample` so `bitbake mpfs-dev-image` generates payloads automatically.

## 3. Linux Harts (U54_0 / U54_1)
- [x] Capture kernel defconfig fragments for AMP + radar DSP support under `linux/kernel`.
	- Added `linux/kernel/fragments/mpfs_amp.fragment` and wired it into Yocto via `linux-microchip_%.bbappend`.
- [x] Provide systemd units and configs orchestrating FPGA + accelerator bring-up in `linux/rootfs`.
	- `amp-runtime` Yocto recipe now packages `amp-shmem.service` + `zephyr-ipc-gateway.service`, exposes `/run/amp/ipc_gateway.cmd`, and logs responses for validation.
- [ ] Publish sample userspace tools (CLI + Python) demonstrating accelerator control in `linux/userspace`.

## 4. Zephyr RTOS (U54_3)
- [x] Define custom board overlays (defaulting to hart `u54_3`) inside `zephyr/boards`.
	- Added shared-memory overlay `bsp/device-tree/zephyr/mpfs-amp.overlay`.
- [x] Author baseline applications (`ipc_service_gateway`, `radar_control`, `telemetry_agent`).
	- `ipc_service_gateway` implements a PING/STATUS/RADAR_START/RADAR_STOP command router and emits ready banners that Linux can observe.
- [ ] Create reusable Zephyr modules for shared-memory buffers and radar HAL bindings.
- [ ] Document west workspace initialisation and tie builds into scripts.
	- [x] Expanded `docs/workflows/zephyr_amp.md` + `zephyr/README.md` with west init/update steps referencing `zephyr/west.yml`.
	- [x] Documented shared-memory overlay usage in `docs/workflows/zephyr_amp.md` and `zephyr/README.md` so all harts pull the canonical DTS fragment.
	- [x] Added `scripts/build/zephyr_amp.sh` and documented it under `docs/workflows/zephyr_amp.md` for per-hart build automation.

## 5. AMP & Inter-Core Messaging
- [x] Write HSS payload manifests mapping Linux/Zephyr binaries to harts (`bsp/hss`).
- [x] Implement OpenAMP/IPC Service sample demonstrating Linux↔Zephyr messaging.
- [x] Specify shared-memory layout + mailbox/interrupt routing in docs and reference headers (`docs/architecture/amp.md`, `include/amp/shmem_layout.h`).

## 6. FPGA / Libero Flow
- [ ] Check in Libero TCL scripts that regenerate the radar DSP design.
- [ ] Automate bitstream exports into `bsp/libero/exports` with version metadata.
- [ ] Provide documentation of AXI/APB interfaces plus DMA descriptors for software teams.

## 7. Simulation & QEMU
- [ ] Create QEMU launcher scripts for Linux-only, Zephyr-only, and integrated AMP runs under `sim/qemu/*`.
- [ ] Hook QEMU smoke tests into CI to catch regressions before hardware deployment.
- [ ] Capture known emulation gaps vs real hardware in `sim/README.md`.

## 8. Documentation
- [ ] Expand architecture docs with diagrams (AMP flow, radar DSP datapath, communication fabric).
- [ ] Add onboarding guide describing end-to-end workflow from cloning repo to first deployment.
- [ ] Maintain troubleshooting section (build failures, HSS payload issues, Zephyr IPC problems).

## 9. QNX Integration
- [ ] Import/port the PolarFire SoC QNX BSP into `qnx/bsp` with hart-aware startup code.
- [ ] Provide sample QNX services demonstrating shared-memory coordination with Linux and Zephyr.
- [ ] Document QNX build + deployment instructions, including how HSS loads all three OSes.
- [ ] Define IPC header files shared among Linux/QNX/Zephyr under `qnx/ipc` and sync them with `docs/architecture/interconnect.md`.
