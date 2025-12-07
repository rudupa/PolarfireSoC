#!/usr/bin/env bash
# Aggregate Yocto + Zephyr artifacts into a single HSS payload for the AMP demo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DEFAULT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REPO_ROOT="${REPO_ROOT:-${REPO_ROOT_DEFAULT}}"
YOCTO_BUILD_DIR="${YOCTO_BUILD_DIR:-}"
YOCTO_DEPLOY_DIR="${YOCTO_DEPLOY_DIR:-}"
ZEPHYR_WORKSPACE="${ZEPHYR_WORKSPACE:-}"
ZEPHYR_BUILD_DIR="${ZEPHYR_BUILD_DIR:-}"
STAGING_LINUX_DIR="${STAGING_LINUX_DIR:-}"
OUTPUT_DIR="${OUTPUT_DIR:-}"
MANIFEST_PATH="${MANIFEST_PATH:-}"
PAYLOAD_OUT="${PAYLOAD_OUT:-}"
LINUX_IMAGE_SRC="${LINUX_IMAGE_SRC:-}"
LINUX_DTB_SRC="${LINUX_DTB_SRC:-}"
LINUX_INITRD_SRC="${LINUX_INITRD_SRC:-}"
LINUX_OPENSBI_SRC="${LINUX_OPENSBI_SRC:-}"
ZEPHYR_ELF="${ZEPHYR_ELF:-}"

usage() {
    cat <<EOF
Usage: amp_basic.sh [options]

Options:
  --repo-root PATH             Override repository root (default: auto-detected)
  --yocto-build-dir PATH       Yocto build directory (default: \\$REPO_ROOT/yocto/build-mpfs-amp)
  --yocto-deploy-dir PATH      Yocto deploy directory (default: \\${YOCTO_BUILD_DIR}/tmp/deploy/images/mpfs-amp)
  --zephyr-workspace PATH      Zephyr west workspace root (default: \\$REPO_ROOT/zephyr)
  --zephyr-build-dir PATH      Zephyr build directory (default: \\${ZEPHYR_WORKSPACE}/build)
  --manifest PATH              Path to HSS payload manifest yaml
  --payload-out PATH           Output payload path
  --help                       Show this message

Environment variables may also be used to override the same paths.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root)
            REPO_ROOT="$2"; shift 2 ;;
        --yocto-build-dir)
            YOCTO_BUILD_DIR="$2"; shift 2 ;;
        --yocto-deploy-dir)
            YOCTO_DEPLOY_DIR="$2"; shift 2 ;;
        --zephyr-workspace)
            ZEPHYR_WORKSPACE="$2"; shift 2 ;;
        --zephyr-build-dir)
            ZEPHYR_BUILD_DIR="$2"; shift 2 ;;
        --manifest)
            MANIFEST_PATH="$2"; shift 2 ;;
        --payload-out)
            PAYLOAD_OUT="$2"; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "[amp_basic] Unknown argument: $1" >&2
            usage >&2
            exit 1 ;;
    esac
done

YOCTO_BUILD_DIR="${YOCTO_BUILD_DIR:-${REPO_ROOT}/yocto/build-mpfs-amp}"
YOCTO_DEPLOY_DIR="${YOCTO_DEPLOY_DIR:-${YOCTO_BUILD_DIR}/tmp/deploy/images/mpfs-amp}"
REPO_ROOT="$(cd "${REPO_ROOT}" && pwd)"

ZEPHYR_WORKSPACE="${ZEPHYR_WORKSPACE:-${REPO_ROOT}/zephyr}"
ZEPHYR_BUILD_DIR="${ZEPHYR_BUILD_DIR:-${ZEPHYR_WORKSPACE}/build}"

STAGING_LINUX_DIR="${STAGING_LINUX_DIR:-${REPO_ROOT}/bsp/hss/payloads/linux}"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/bsp/hss/payloads/build}"
MANIFEST_PATH="${MANIFEST_PATH:-${REPO_ROOT}/bsp/hss/manifests/amp_linux_zephyr.yaml}"
PAYLOAD_OUT="${PAYLOAD_OUT:-${OUTPUT_DIR}/amp-linux-zephyr.bin}"

LINUX_IMAGE_SRC="${LINUX_IMAGE_SRC:-${YOCTO_DEPLOY_DIR}/Image}"
LINUX_DTB_SRC="${LINUX_DTB_SRC:-${YOCTO_DEPLOY_DIR}/polarfire-soc-amp.dtb}"
LINUX_INITRD_SRC="${LINUX_INITRD_SRC:-${YOCTO_DEPLOY_DIR}/mpfs-dev-image-mpfs-amp.cpio.gz.u-boot}"
LINUX_OPENSBI_SRC="${LINUX_OPENSBI_SRC:-${YOCTO_DEPLOY_DIR}/fw_dynamic.bin}"

ZEPHYR_ELF="${ZEPHYR_ELF:-${ZEPHYR_BUILD_DIR}/zephyr/zephyr.elf}"

mkdir -p "${STAGING_LINUX_DIR}" "${OUTPUT_DIR}"

copy_artifact() {
    local src="$1"
    local dst="$2"

    if [ ! -f "${src}" ]; then
        echo "[amp_basic] Missing artifact: ${src}" >&2
        echo "Set LINUX_*_SRC or build Yocto first." >&2
        exit 1
    fi

    install -m 0644 "${src}" "${dst}"
}

copy_artifact "${LINUX_IMAGE_SRC}" "${STAGING_LINUX_DIR}/Image"
copy_artifact "${LINUX_DTB_SRC}" "${STAGING_LINUX_DIR}/polarfire-soc-amp.dtb"
copy_artifact "${LINUX_INITRD_SRC}" "${STAGING_LINUX_DIR}/rootfs.cpio.gz"
copy_artifact "${LINUX_OPENSBI_SRC}" "${STAGING_LINUX_DIR}/fw_dynamic.bin"

if [ ! -f "${ZEPHYR_ELF}" ]; then
    echo "[amp_basic] Missing Zephyr ELF at ${ZEPHYR_ELF}. Run west build first." >&2
    exit 1
fi

if [ ! -f "${MANIFEST_PATH}" ]; then
    echo "[amp_basic] Missing manifest: ${MANIFEST_PATH}" >&2
    exit 1
fi

pushd "${ZEPHYR_WORKSPACE}" >/dev/null
west generate-payload "${MANIFEST_PATH}" "${PAYLOAD_OUT}"
popd >/dev/null

echo "[amp_basic] Payload ready: ${PAYLOAD_OUT}"
