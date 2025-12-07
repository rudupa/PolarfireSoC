# AMP Configuration Notes

PolarFire SoC natively supports asymmetric multiprocessing across the U54 cores. Our consolidated OS mapping is now fixed as:

- **U54_0 & U54_1** → Linux (SMP pair handling networking, storage, GUI, ROS2, accelerator control).
- **U54_2** → QNX Neutrino (safety-critical control loops, watchdog/resource supervision).
- **U54_3** → Zephyr RTOS (radar accelerators, telemetry helpers, OpenAMP peer).

HSS payload manifests, board overlays, and build scripts are aligned to this allocation to avoid drift between documentation and binaries.

Key action items:

1. Track HSS handover configuration for each hart, including payload manifests and boot arguments.
2. Document Zephyr build invocations (e.g., `west build -b mpfs_discovery/polarfire/u54_3`).
3. Capture QNX build + deployment steps (BSP handoff scripts, QNX image packaging for HSS).
4. Record OpenAMP / IPC Service settings (e.g., `CONFIG_OPENAMP=y`, `CONFIG_IPC_SERVICE=y`) and any QNX resource-manager APIs required for shared-memory messaging.
5. Define shared buffers and mailbox register maps used between Linux, QNX, Zephyr, and FPGA DMA engines.

Reference: Microchip AMP app notes and the "AMP on PolarFire SoC" examples cited in the project README.

## Upstream Building Blocks

| Source repo | How we consume it |
|-------------|-------------------|
| `polarfire-soc/zephyr-applications` | Provides Zephyr workspace layout, sample AMP apps (e.g., `apps/smp`), and West extensions `generate-payload` / `flash-payload` that wrap the HSS payload generator for packaging U54 binaries plus MPU settings. |
| `polarfire-soc/polarfire-soc-documentation` | Canonical Microchip flow docs for AMP, remoteproc/rpmsg, HSS boot modes, DDR training, and Discovery Kit bring-up steps referenced below. |
| `linux4microchip/meta-mchp` | Vendor Yocto layers (`meta-mchp-polarfire-soc`) that we sync into `yocto/layers/` to build Linux + HSS artifacts consistent with Discovery Kit hardware. |
| `polarfire-soc/polarfire-soc-discovery-kit-reference-design` | Libero Tcl scripts + MSS XML used to regenerate the FPGA base design, train DDR, and ensure fabric resources (mailboxes, GPIOs, MIV IHC) match the AMP memory map we expect. |

## Integration Plan (Baseline Linux + Zephyr Basic App)

1. **Refresh FPGA + MSS configuration**
	- Clone the Discovery Kit reference-design repo inside `bsp/libero/` and run `MPFS_DISCOVERY_KIT_REFERENCE_DESIGN.tcl` with the `HSS_UPDATE` argument so the latest HSS hex is embedded in eNVM.
	- Capture generated XML + MSS config artifacts under `bsp/libero/generated/` to keep the DDR + IHC layout version-controlled.
	- If the AMP sample app needs fabric mailboxes/DMA, enable the `AXI4_STREAM_DEMO` argument or extend the Tcl script and document deltas here.

2. **Align Yocto workspace**
	- Under `yocto/layers/`, add the upstream `meta-mchp` repo as a Git submodule (keep `meta-polarfire-nn` as the custom layer).
	- Update `yocto/conf/templates/bblayers.conf.sample` to include `meta-mchp-polarfire-soc` and `meta-mchp-common` plus our local layer.
	- Create a `mpfs-amp` machine config overlay that selects SMP Linux on `u54_0/u54_1`, marks `u54_2` for QNX, `u54_3` for Zephyr, and exports CMA regions for OpenAMP (see Microchip doc `applications-and-demos/asymmetric-multiprocessing/amp.md`).

3. **Stage Zephyr AMP workload**
	- Mirror the structure from `polarfire-soc/zephyr-applications` into `zephyr/apps/` (or use it as a west submodule). For the basic AMP validation app, reuse `apps/smp` or `apps/ipc_service` as `zephyr/apps/amp_pingpong`.
	- Document Zephyr SDK prerequisites in `zephyr/README.md` and ensure `west.yml` references our repo for modules.
	- Enable `CONFIG_OPENAMP`, `CONFIG_IPC_SERVICE_BACKEND_RPMSG`, and shared-memory carve-outs that match the `shared_buffers` tracked in this doc.

4. **Package HSS payloads**
	- Use the upstream `west generate-payload` extension (already provided by the Zephyr repo) but store YAML manifests under `bsp/hss/manifests/` with two variants: `amp_linux_zephyr.yaml` and `amp_linux_qnx_zephyr.yaml`.
	- Automate the bundle via `scripts/build/amp_basic.sh`, which stages Yocto artifacts into `bsp/hss/payloads/` before invoking the west extension.
	- Each manifest should describe: FPGA bitstream slot (if reprogramming), Linux payload for `u54_0/u54_1` (SMP), QNX binary for `u54_2`, Zephyr ELF for `u54_3`, and boot arguments pulled from this doc.
	- Commit the resulting `output.bin` artifacts to `bsp/hss/payloads/build/` only when releasing (normally they remain generated assets).

5. **Linux bring-up hooks**
	- In the Yocto layer, add a `systemd` unit that loads the RPMsg char drivers and binds to the Zephyr endpoints declared in the app.
	- Provide a tiny demo daemon in `linux/userspace/amp_demo/` that exchanges messages with Zephyr (matching the basic app requirement in `docs/architecture/overview.md`).

6. **QNX placeholder**
	- Keep `qnx/bsp/README.md` synced with Microchip's doc flow; until QNX artifacts exist, provide stub scripts that reserve `u54_2` and shared memory described in Section 5 above.

7. **Validation workflow**
	- Encode the combined flow inside `scripts/workflows/amp_basic.sh`: regenerate Libero outputs (if needed), trigger Yocto build (`bitbake mpfs-image-amp`), build Zephyr `west build -p -b mpfs_icicle polarfire-soc/apps/amp_pingpong`, generate payload, flash via `west flash-payload`.
	- Capture UART logs for each hart and store golden logs under `docs/architecture/amp_logs/` for regression tracking.

## Shared Memory & Mailbox Layout

Shared buffers are carved out of DDR starting at `0xB800_0000` (2 MiB window). The region is mapped as non-cacheable on Linux via `devicetree` (e.g., `no-map` + `dma-coherent`) and by configuring the PMP attributes in Zephyr/QNX. The C header `include/amp/shmem_layout.h` exposes these constants for all OS builds.

| Region | Start Addr | Size | Purpose | Producer / Consumer |
|--------|------------|------|---------|---------------------|
| Mailboxes (`struct amp_mailbox` array) | `0xB800_0000` | 64 KiB | Doorbells + status flags. Each hart pair gets TX/RX slots plus a shared ownership bitmap. | Linux↔Zephyr, Linux↔QNX, Zephyr↔QNX |
| RPMsg TX buffers | `0xB801_0000` | 512 KiB | Circular buffer used by Linux RPMsg virtio backend to enqueue messages for RTOS peers. | Linux writes, Zephyr/QNX read |
| RPMsg RX buffers | `0xB809_0000` | 512 KiB | Mirror of the TX buffer for RTOS-to-Linux traffic. | Zephyr/QNX write, Linux read |
| Bulk DMA staging | `0xB811_0000` | 768 KiB | Optional scratchpad for FPGA DMA descriptors, radar frames, or QNX telemetry records. | Shared | 
| Reserved / future use | `0xB823_0000` | Remaining | Headroom for additional RTOS instances or secure monitor data. | TBA |

### Doorbell + interrupt mapping

- Mailbox doorbells are implemented with the Mi-V IHC block from the Discovery Kit reference design. The IRQ mapping follows the Libero design: `MSS_INT_F2M[63]` (Linux SMP cluster), `[62]` (`u54_2` / QNX), `[61]` (`u54_3` / Zephyr), `[60]` (spare/reserved). These values are defined in `include/amp/shmem_layout.h` as `AMP_IHC_IRQ_*` for reuse in device trees and driver code.
- Linux exposes the doorbells via the IHC platform driver (`drivers/mailbox/mbox-mv-ihc.c`) and ties them to `rpmsg_chrdev` mailboxes. Zephyr configures `CONFIG_IPC_SERVICE_BACKEND_RPMSG` to reference the same base address using the devicetree snippet below:

```dts
/ {
	amp_shmem: shared-memory@b8000000 {
		compatible = "mmio-sram";
		reg = <0x0 0xb8000000 0x0 0x00200000>;
		no-map;
	};
};
```

- Every OS listens on its dedicated mailbox channel and raises the partner's interrupt by writing to the `AMP_MAILBOX_DOORBELL_SET(ch)` register defined in the shared header.

### Cache policy

- Linux device tree entry (see `bsp/device-tree/linux/amp-shmem-overlay.dtsi`) adds `dma-coherent` so the RPMsg virtio device can use `dma_alloc_coherent()` on the shared region without manual flushing.
- Zephyr `dts` overlay (see `bsp/device-tree/zephyr/mpfs-amp.overlay`) marks the region as `zephyr,memory-region` with `no-cache; shared;` attributes (`MMU` page tables set to uncached).
- QNX BSP will reuse the same header, mapping the region as strongly-ordered via `sys_mem_map()`.

### Header for cross-OS builds

`include/amp/shmem_layout.h` centralises constants for both kernel and userspace builds. Consumers should include the header instead of duplicating offsets. When divergent layouts are required (e.g., Linux-only builds), gate them behind `#ifdef CONFIG_AMP_SHMEM_LEGACY`.

## Open Items

- Validate the shared memory and doorbell layout (`include/amp/shmem_layout.h`) on hardware, then update QNX BSP/device tree overlays if adjustments are required.
- Decide whether Linux boots from eMMC (HSS) or via SD to simplify payload iteration.
- Determine if Zephyr harts need access to DDR via FIC or if scratchpad suffices for the demo.

This plan should be revisited whenever the upstream repositories cut a release; each time, record the commit SHA in `docs/architecture/target.md` for traceability.
