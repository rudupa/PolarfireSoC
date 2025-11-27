# Zephyr AMP Workflow

1. **West Workspace** – Use `zephyr/` as the west root so board overlays and apps live alongside Yocto content.
2. **Board Targets** – Derive from `mpfs_dev_kit` but disable SMP and tailor each build for `u54_1`, `u54_2`, or `u54_3`.
3. **Build Example**
   ```sh
   west build -b mpfs_discovery/u54_1 zephyr/apps/ipc_service_gateway
   ```
4. **OpenAMP / IPC Service** – Enable `CONFIG_OPENAMP`, `CONFIG_IPC_SERVICE`, and `CONFIG_IPC_SERVICE_BACKEND_RPMSG` to communicate with Linux on U54_0.
5. **Packaging** – Copy resulting ELFs into `bsp/hss/payloads/` so HSS can launch them alongside Linux.
6. **Debugging** – Document JTAG scripts or semihosting traces inside `zephyr/boards/README.md` as they solidify.
