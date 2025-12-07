# Root Filesystem Assets

Use this directory for:

- `systemd/` unit files that orchestrate accelerator bring-up order.
- `configs/` for network, telemetry, and security settings.
- `scripts/` executed during post-install or OTA updates.
- `stage1/` and `stage2/` folders implementing the fast-boot GUI strategy described in `docs/workflows/linux_fast_boot.md`.

### Initial Units & Scripts

- `systemd/amp-shmem.service` – Calls `/usr/libexec/amp/amp-shmem-setup.sh` to export the canonical shared-memory layout into `/run/amp/shmem.env` and ensure `/dev/mem` permissions are ready before higher-level services start.
- `systemd/zephyr-ipc-gateway.service` – Uses `/usr/libexec/amp/zephyr_ipc_gateway.sh` to wait for `rpmsg_ctrl*` devices, create the `ipc_service_gateway` endpoint, expose `/run/amp/ipc_gateway.cmd` (FIFO for commands) and `/run/amp/ipc_gateway.log` (responses), and keep the RPMsg pipe alive for Zephyr↔Linux messaging.

Install scripts under `/usr/libexec/amp/` through the Yocto recipe, then enable the units:

```
install -Dm0755 scripts/amp-shmem-setup.sh ${D}/usr/libexec/amp/amp-shmem-setup.sh
install -Dm0755 scripts/zephyr_ipc_gateway.sh ${D}/usr/libexec/amp/zephyr_ipc_gateway.sh
install -Dm0644 systemd/amp-shmem.service ${D}${systemd_system_unitdir}/amp-shmem.service
install -Dm0644 systemd/zephyr-ipc-gateway.service ${D}${systemd_system_unitdir}/zephyr-ipc-gateway.service
systemctl enable amp-shmem.service zephyr-ipc-gateway.service
```

The Yocto layer (`meta-polarfire-nn`) now ships `recipes-core/amp-runtime/amp-runtime.bb`, which automates the installation and enabling of these scripts, so users no longer need to manually copy them.
```

Symlink or copy these assets into Yocto recipes via `FILESEXTRAPATHS`.
