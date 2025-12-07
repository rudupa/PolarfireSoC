#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Prepare shared-memory regions and mailbox devices for the Linux AMP harts.

set -euo pipefail

SHMEM_BASE="0xB8000000"
SHMEM_SIZE="0x00200000"
MAILBOX_CH_LINUX_RX=0
MAILBOX_CH_LINUX_TX=1

RUNTIME_DIR="/run/amp"
mkdir -p "$RUNTIME_DIR"

cat >"${RUNTIME_DIR}/shmem.env" <<EOF
AMP_SHMEM_BASE=${SHMEM_BASE}
AMP_SHMEM_SIZE=${SHMEM_SIZE}
AMP_MAILBOX_CH_LINUX_RX=${MAILBOX_CH_LINUX_RX}
AMP_MAILBOX_CH_LINUX_TX=${MAILBOX_CH_LINUX_TX}
EOF

chmod 0644 "${RUNTIME_DIR}/shmem.env"

if [[ -e /dev/mem ]]; then
    chgrp root /dev/mem 2>/dev/null || true
    chmod 0660 /dev/mem 2>/dev/null || true
fi

if command -v udevadm >/dev/null 2>&1; then
    udevadm control --reload || true
fi

echo "[amp-shmem] exported ${RUNTIME_DIR}/shmem.env" | systemd-cat -t amp-shmem-setup || true
