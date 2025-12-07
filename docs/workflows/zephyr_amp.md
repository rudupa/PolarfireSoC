# Zephyr AMP Workflow

## 1. Bootstrap west + dependencies

```sh
cd zephyr
west init -l .
west update                      # pulls Zephyr v4.0.0 + hal_microchip + zephyr-applications
pip install -r zephyr/zephyr/scripts/requirements.txt
pip install -r modules/zephyr-applications/scripts/requirements.txt
```

Tip: run `source scripts/env/setup-zephyr-env.sh` (or the PowerShell equivalent) to set `ZEPHYR_WORKSPACE`, `ZEPHYR_BASE`, and `WEST_CONFIG` before invoking west.

`modules/zephyr-applications` brings in the Microchip `generate-payload` and `flash-payload` west commands so we can package Zephyr ELFs with HSS automatically.

## 2. Build the AMP demo applications

The repo ships with two starter apps:

- `zephyr/apps/amp_pingpong` – Minimal RPMsg echo and benchmarking hooks.
- `zephyr/apps/ipc_service_gateway` – Registers the `ipc_gateway` endpoint that Linux expects (`linux/rootfs/systemd/zephyr-ipc-gateway.service` creates the matching RPMsg channel), parses commands (`PING`, `STATUS`, `RADAR_START`, `RADAR_STOP`, `HELP`), and mirrors responses back across RPMsg.

On the Linux side, `amp-runtime` drops a FIFO at `/run/amp/ipc_gateway.cmd`. Writing a line such as `RADAR_START medium_range` sends the command to Zephyr; responses are visible via `journalctl -u zephyr-ipc-gateway` or by tailing `/run/amp/ipc_gateway.log`.

Example build for hart `u54_3`:

```sh
west build -b mpfs_icicle zephyr/apps/amp_pingpong \
   -- -DCONFIG_MPFS_HART_INDEX=3 \
   -- -DDTC_OVERLAY_FILE="${ZEPHYR_BASE}/../bsp/device-tree/zephyr/mpfs-amp.overlay;${ZEPHYR_BASE}/../zephyr/boards/mpfs_discovery_u54_3.overlay"
```

Set `CONFIG_MPFS_HART_INDEX` to `3` for the default layout. The CMAKE define simply lands in Kconfig via `CONFIG_MPFS_HART_INDEX` for logging clarity; adjust as you introduce alternate overlays.

The overlay wires the `amp_shmem` node into `zephyr,ipc-shm`, guaranteeing the IPC Service backend lands on the same DDR window as Linux. Keep the overlay path relative to the repo root (as above) so every hart build uses the authoritative `bsp/device-tree/zephyr/mpfs-amp.overlay` copy.

Prefer using `scripts/build/zephyr_amp.sh` once the workspace is initialised. It defaults to hart `3`, chains the shared-memory overlay with `zephyr/boards/mpfs_discovery_u54_3.overlay`, and writes build outputs under `zephyr/build/amp_pingpong_hart3`. Pass `-a zephyr/apps/ipc_service_gateway -b mpfs_amp_gateway -H 3` to build the new IPC service sample, or change the `-H` flag when temporarily targeting a different hart.

Per-hart board overlays now live in `zephyr/boards/mpfs_discovery_u54_<n>.overlay`. For the default layout, use `mpfs_discovery_u54_3.overlay`, which disables the Linux/QNX harts and records Zephyr’s mailbox/doorbell routing. Chain it with the shared-memory overlay via `-DDTC_OVERLAY_FILE=".../mpfs-amp.overlay;.../boards/mpfs_discovery_u54_3.overlay"` (the helper script performs this automatically and warns if a matching overlay is missing).

Key configuration knobs (see `prj.conf`):

- `CONFIG_OPENAMP=y` and `CONFIG_IPC_SERVICE_BACKEND_RPMSG=y` ensure compatibility with the Linux RPMsg char driver expectations.
- `CONFIG_MAIN_STACK_SIZE=4096` and `CONFIG_HEAP_MEM_POOL_SIZE=8192` leave headroom for message buffers.
- `CONFIG_LOG=y` pipes status updates to the shared UART console when debugging.

## 3. Generate Zephyr payloads

The upstream west extensions live inside `modules/zephyr-applications/scripts`. After building the ELFs:

```sh
# DDR-resident payload that boots Zephyr on hart u54_3
west generate-payload ../bsp/hss/manifests/amp_linux_zephyr.yaml \
   ../bsp/hss/payloads/build/amp-zephyr.bin
```

Alternatively, run `scripts/build/amp_basic.sh` from the repo root to copy Yocto artifacts into `bsp/hss/payloads/` and invoke the same `west generate-payload` command automatically.

Payload manifests live alongside the Yocto + Libero artifacts (see `bsp/hss/`).

## 4. Flash or boot via HSS

Once `amp-zephyr.bin` is produced (and optionally merged with Linux via `scripts/build/amp_basic.sh`), flash it to the Discovery Kit eMMC using:

```sh
west flash-payload bsp/hss/payloads/build/amp-zephyr.bin /dev/ttyUSBx
```

The command powers the board, mounts eMMC through the HSS CLI, and writes the payload image.

## 5. Debugging hooks

- Place hart-specific OpenOCD configs in `zephyr/boards/` once available.
- Capture Zephyr UART output and store golden logs under `docs/architecture/amp_logs/` (see architecture doc for logging expectations).
- Use `west debug` with SoftConsole launch configs shipped in `modules/zephyr-applications/softconsole-launch-configs` if JTAG is required.
