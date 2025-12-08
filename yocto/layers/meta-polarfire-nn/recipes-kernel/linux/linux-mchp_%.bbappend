# SPDX-License-Identifier: MIT
# Pull in the shared-memory reserved region + mailbox overlay used across AMP builds.

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://amp-shmem-overlay.dtsi"
SRC_URI:append = " file://mpfs_amp.fragment"

# Append the overlay to every MPFS devicetree variant we ship so Linux
# reserves the DDR window aligned with include/amp/shmem_layout.h.
KERNEL_DEVICETREE:append = " microchip/amp-shmem-overlay.dtb"

# Ensure the overlay lives alongside the upstream Microchip DTS sources.
do_configure:prepend() {
    install -Dm0644 "${WORKDIR}/amp-shmem-overlay.dtsi" \
        "${S}/arch/riscv/boot/dts/microchip/amp-shmem-overlay.dts"
}

do_configure:append() {
    if [ -f "${WORKDIR}/mpfs_amp.fragment" ]; then
        bbnote "Applying mpfs_amp.fragment to linux-mchp config"
        # Copy fragment locally so merge_config picks it up relative to ${B}.
        cp "${WORKDIR}/mpfs_amp.fragment" "${B}/mpfs_amp.fragment"
        ( cd "${B}" && \
            bash "${S}/scripts/kconfig/merge_config.sh" -m .config mpfs_amp.fragment )
        oe_runmake olddefconfig
    fi
}
