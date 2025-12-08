DESCRIPTION = "AMP shared-memory prep + RPMsg gateway services"
SUMMARY = "Systemd units and helper scripts that expose the AMP layout to Linux"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${THISDIR}/LICENSE;md5=6c477ed7449b0bd782d3898de4d5f0d5"

SRC_URI = " \
    file://amp-shmem-setup.sh \
    file://zephyr_ipc_gateway.sh \
    file://amp-shmem.service \
    file://zephyr-ipc-gateway.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "amp-shmem.service zephyr-ipc-gateway.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} += "bash coreutils systemd udev"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${libexecdir}/amp
    install -m 0755 ${WORKDIR}/amp-shmem-setup.sh ${D}${libexecdir}/amp/amp-shmem-setup.sh
    install -m 0755 ${WORKDIR}/zephyr_ipc_gateway.sh ${D}${libexecdir}/amp/zephyr_ipc_gateway.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/amp-shmem.service ${D}${systemd_system_unitdir}/amp-shmem.service
    install -m 0644 ${WORKDIR}/zephyr-ipc-gateway.service ${D}${systemd_system_unitdir}/zephyr-ipc-gateway.service
}

FILES:${PN} += "${libexecdir}/amp ${systemd_system_unitdir}/amp-shmem.service ${systemd_system_unitdir}/zephyr-ipc-gateway.service"
