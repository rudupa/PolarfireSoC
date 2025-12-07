# QNX + Linux + Zephyr AMP Workflow

1. **Prerequisites**
   - QNX SDP (version TBD) installed on the host with access to the PolarFire SoC BSP kit.
   - Repo cloned with subdirectories (`linux/`, `zephyr/`, `qnx/`) populated.
   - HSS payload generator available via `bsp/hss` scripts.

2. **Build Steps**
   1. **Linux** – Use Yocto to create the Linux image and copy kernel/rootfs artifacts into `bsp/hss/payloads/linux/`.
   2. **QNX** – Build the startup + IFS image targeting hart `u54_2`; drop resulting binaries into `bsp/hss/payloads/qnx/`.
   3. **Zephyr** – Create the Zephyr ELF for hart `u54_3` and place it under `bsp/hss/payloads/zephyr/`.

3. **HSS Payload Manifest**
   - Define per-hart entries specifying load address, entry point, and reset vector overrides.
   - Tie shared-memory carve-outs to the `qnx/ipc` header definitions so all OSes agree on layout.

4. **Inter-Core Messaging**
   - Configure OpenAMP/RPMsg instances on Linux and Zephyr.
   - Implement QNX resource managers or PPS services to forward messages through the shared-memory mailboxes.

5. **Debug & Validation**
   - Start with QEMU (if available) to validate boot sequencing.
   - Use JTAG to halt/resume each hart and confirm caches and MPU settings align with the shared-memory map.

Capture deviations or additional steps in this file as the workflow matures.
