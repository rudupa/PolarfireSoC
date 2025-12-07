# Yocto Build Workflow

1. **Sync BSP sources**
   ```sh
   cd yocto
   repo init -u ../yocto/manifests -m default.xml -b kirkstone
   repo sync
   ```
   This pulls Poky, meta-openembedded, and Microchip's `meta-mchp` (which contains `meta-mchp-common` and `meta-mchp-polarfire-soc`).

### Pinned revisions

| Repository | Branch | Commit |
|------------|--------|--------|
| poky (`git.yoctoproject.org/git/poky`) | `kirkstone` | `40701465df90b38b9068bcbd0ce6aa6587807433` |
| meta-openembedded (`git.openembedded.org/meta-openembedded`) | `kirkstone` | `07ac1890c843b374c27e150f1a2e53ad3db2a8e4` |
| meta-mchp (`github.com/linux4microchip/meta-mchp`) | `scarthgap`* | `085129d94643b12749d327ffcaf1ffcadd18a3cd` |
| polarfire-soc-documentation (`github.com/polarfire-soc/polarfire-soc-documentation`) | `master` | `c38f077b94ab63089e8a8f7f05da31e38b484102` |

> *Microchip currently publishes PolarFire SoC updates on `scarthgap`; adjust the manifest once a `kirkstone` branch becomes available.
2. **Create a build directory**
   ```sh
   source scripts/env/setup-yocto-env.sh   # exports TEMPLATECONF, MACHINE, etc.
   source sources/poky/oe-init-build-env build-mpfs-amp
   ```
3. **Apply templates**
   - Copy `yocto/conf/templates/local.conf.sample` and `bblayers.conf.sample` into `build-mpfs-amp/conf/`.
   - `local.conf` defaults to the new `mpfs-amp` MACHINE (defined inside `meta-polarfire-nn`), appends `amp-runtime` to `IMAGE_INSTALL`, and wires in the `amp-payload` class so AMP helpers land in every image.
   - The `meta-polarfire-nn` layer already appends `bsp/device-tree/linux/amp-shmem-overlay.dtsi` to `KERNEL_DEVICETREE` and merges `linux/kernel/fragments/mpfs_amp.fragment` during `do_configure`, guaranteeing Linux reserves the shared DDR window and enables RPMsg/OpenAMP support out of the box.
4. **Build Linux image + SDK**
   ```sh
   bitbake mpfs-dev-image
   bitbake mpfs-dev-image -c populate_sdk
   ```
   Expect deploy artifacts under `build-mpfs-amp/tmp/deploy/images/mpfs-amp/` for the Linux hart payload.
5. **Export to AMP payload**
   - The sample `local.conf` already appends the `amp-payload` class, which invokes `scripts/build/amp_basic.sh` after the image finishes building. Generated payloads appear under `bsp/hss/payloads/build/`.
   - To run the helper manually (for rebuilds without BitBake), execute `scripts/build/amp_basic.sh` from the repo root.
