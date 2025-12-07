# Build Automation

Use this folder for repeatable build entry points:

- `amp_basic.sh` – copies Yocto artifacts + Zephyr ELFs into `bsp/hss` and runs `west generate-payload` to produce the AMP demo binary.
- `zephyr_amp.sh` – builds the requested U54 hart targets (default: hart 3), chains the shared-memory overlay with `zephyr/boards/mpfs_discovery_u54_<n>.overlay`, and calls `west build` so each Zephyr image records the correct hart + mailbox metadata. Point `-a` at `zephyr/apps/ipc_service_gateway` to compile the new IPC endpoint sample that pairs with the Linux RPMsg gateway service.

Keep scripts parametrised (image name, build dir, hart target) so CI pipelines can reuse them.
