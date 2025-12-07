# SPDX-License-Identifier: MIT
# Post-processing hook that bundles Linux + Zephyr artifacts into an HSS payload.

AMP_PAYLOAD_ENABLED ?= "0"
AMP_PAYLOAD_REPO_ROOT ?= "${TOPDIR}/.."
AMP_PAYLOAD_SCRIPT ?= "${AMP_PAYLOAD_REPO_ROOT}/scripts/build/amp_basic.sh"
AMP_PAYLOAD_MANIFEST ?= "${AMP_PAYLOAD_REPO_ROOT}/bsp/hss/manifests/amp_linux_zephyr.yaml"
AMP_PAYLOAD_OUTPUT ?= "${AMP_PAYLOAD_REPO_ROOT}/bsp/hss/payloads/build/amp-linux-zephyr.bin"
AMP_PAYLOAD_ZEPHYR_WORKSPACE ?= "${AMP_PAYLOAD_REPO_ROOT}/zephyr"

amp_payload_generate() {
    if [ "${AMP_PAYLOAD_ENABLED}" != "1" ]; then
        bbnote "AMP payload generation disabled"
        return
    fi

    if [ ! -x "${AMP_PAYLOAD_SCRIPT}" ]; then
        bbwarn "AMP payload script not found: ${AMP_PAYLOAD_SCRIPT}"
        return
    fi

    bbnote "Generating AMP payload via ${AMP_PAYLOAD_SCRIPT}"
    ${AMP_PAYLOAD_SCRIPT} \
        --repo-root "${AMP_PAYLOAD_REPO_ROOT}" \
        --yocto-build-dir "${TOPDIR}" \
        --yocto-deploy-dir "${DEPLOY_DIR_IMAGE}" \
        --zephyr-workspace "${AMP_PAYLOAD_ZEPHYR_WORKSPACE}" \
        --manifest "${AMP_PAYLOAD_MANIFEST}" \
        --payload-out "${AMP_PAYLOAD_OUTPUT}" \
        || bbfatal "AMP payload generation failed"
}

IMAGE_POSTPROCESS_COMMAND += "amp_payload_generate; "
