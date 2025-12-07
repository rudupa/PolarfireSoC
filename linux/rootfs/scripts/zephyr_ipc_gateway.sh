#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Bring up an RPMsg endpoint that proxies Linux ↔ Zephyr control messages.

set -euo pipefail

ENDPOINT_NAME=${RPMSG_ENDPOINT_NAME:-ipc_service_gateway}
LOCAL_ADDR=${RPMSG_LOCAL_ADDR:-0x00}
REMOTE_ADDR=${RPMSG_REMOTE_ADDR:-0x01}
CTRL_GLOB="/sys/class/rpmsg/rpmsg_ctrl*"
LOG_TAG="zephyr-ipc-gateway"

wait_for_ctrl()
{
    local timeout=${1:-30}
    local elapsed=0
    while (( elapsed < timeout )); do
        for ctrl in $CTRL_GLOB; do
            [[ -d "$ctrl" ]] && echo "$ctrl" && return 0
        done
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}

CTRL_PATH=$(wait_for_ctrl 60)
if [[ -z "${CTRL_PATH}" ]]; then
    echo "[${LOG_TAG}] rpmsg_ctrl device not found" | systemd-cat -t "$LOG_TAG"
    exit 1
fi

create_endpoint()
{
    local ctrl=$1
    echo ${ENDPOINT_NAME} >"${ctrl}/name"
    echo ${LOCAL_ADDR} >"${ctrl}/src"
    echo ${REMOTE_ADDR} >"${ctrl}/dst"
    echo 1 >"${ctrl}/create_ept"
}

if create_endpoint "$CTRL_PATH" 2>/dev/null; then
    echo "[${LOG_TAG}] endpoint '${ENDPOINT_NAME}' ready via ${CTRL_PATH}" | systemd-cat -t "$LOG_TAG"
else
    echo "[${LOG_TAG}] failed to configure endpoint" | systemd-cat -t "$LOG_TAG"
    exit 1
fi

find_chrdev()
{
    for dev in /sys/class/rpmsg/rpmsg*; do
        [[ -f "${dev}/name" ]] || continue
        if [[ "$(<"${dev}/name")" == "${ENDPOINT_NAME}" ]]; then
            echo "/dev/$(basename "$dev")"
            return 0
        fi
    done
    return 1
}

wait_for_chrdev()
{
    local timeout=${1:-30}
    local elapsed=0
    while (( elapsed < timeout )); do
        local dev
        if dev=$(find_chrdev); then
            echo "$dev"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}

CHRDEV=$(wait_for_chrdev 60)
if [[ -z "${CHRDEV}" ]]; then
    echo "[${LOG_TAG}] rpmsg char device not found for ${ENDPOINT_NAME}" | systemd-cat -t "$LOG_TAG"
    exit 1
fi

RUNTIME_DIR=/run/amp
CMD_FIFO=${RUNTIME_DIR}/ipc_gateway.cmd
DEV_SYMLINK=${RUNTIME_DIR}/ipc_gateway.dev
LOG_FILE=${RUNTIME_DIR}/ipc_gateway.log

mkdir -p "${RUNTIME_DIR}"
ln -sf "${CHRDEV}" "${DEV_SYMLINK}"
[[ -p "${CMD_FIFO}" ]] || mkfifo -m 0660 "${CMD_FIFO}"
touch "${LOG_FILE}"
chmod 0660 "${LOG_FILE}"

echo "[${LOG_TAG}] rpmsg device ${CHRDEV} linked at ${DEV_SYMLINK}" | systemd-cat -t "$LOG_TAG"

forward_commands()
{
    while true; do
        if IFS= read -r line <"${CMD_FIFO}"; then
            [[ -z "$line" ]] && continue
            printf '%s\n' "$line" >"${CHRDEV}"
            echo "[${LOG_TAG}] tx -> $line" | systemd-cat -t "$LOG_TAG"
        fi
    done
}

stream_responses()
{
    stdbuf -o0 cat "${CHRDEV}" | while IFS= read -r resp; do
        echo "$(date --iso-8601=seconds) ${resp}" >> "${LOG_FILE}"
        echo "[${LOG_TAG}] rx <- ${resp}" | systemd-cat -t "$LOG_TAG"
    done
}

cleanup()
{
    [[ -n "${CMD_PID:-}" ]] && kill "${CMD_PID}" 2>/dev/null || true
    [[ -n "${RESP_PID:-}" ]] && kill "${RESP_PID}" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

stream_responses &
RESP_PID=$!
forward_commands &
CMD_PID=$!

# Send a quick status request so logs show Zephyr readiness.
printf 'STATUS\n' >"${CHRDEV}" || true

wait "$RESP_PID" "$CMD_PID"
