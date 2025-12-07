#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export ZEPHYR_WORKSPACE="${ZEPHYR_WORKSPACE:-${REPO_ROOT}/zephyr}"
export ZEPHYR_BASE="${ZEPHYR_BASE:-${ZEPHYR_WORKSPACE}/zephyr}"
export WEST_CONFIG="${WEST_CONFIG:-${ZEPHYR_WORKSPACE}/west.yml}"

cat <<EOF
[Zephyr AMP env]
  ZEPHYR_WORKSPACE=${ZEPHYR_WORKSPACE}
  ZEPHYR_BASE=${ZEPHYR_BASE}
  WEST_CONFIG=${WEST_CONFIG}
EOF

if [ ! -d "${ZEPHYR_WORKSPACE}/.west" ]; then
    echo "(hint) Run 'cd ${ZEPHYR_WORKSPACE} && west init -l . && west update' to fetch dependencies." >&2
fi
