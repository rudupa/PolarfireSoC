#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export LIBERO_PROJECT_ROOT="${LIBERO_PROJECT_ROOT:-${REPO_ROOT}/bsp/libero}"
export LIBERO_DESIGN_SCRIPTS="${LIBERO_DESIGN_SCRIPTS:-${LIBERO_PROJECT_ROOT}}"
export HSS_PAYLOAD_GEN="${HSS_PAYLOAD_GEN:-${REPO_ROOT}/zephyr/zephyr/blobs/payload-generator}"

cat <<EOF
[Libero/HSS env]
  LIBERO_PROJECT_ROOT=${LIBERO_PROJECT_ROOT}
  LIBERO_DESIGN_SCRIPTS=${LIBERO_DESIGN_SCRIPTS}
  HSS_PAYLOAD_GEN=${HSS_PAYLOAD_GEN}
EOF

if ! command -v libero-socexport >/dev/null 2>&1 && ! command -v libero >/dev/null 2>&1; then
    echo "(hint) Add the Libero SoC installation directory to PATH before running automation." >&2
fi
