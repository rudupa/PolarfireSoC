#!/usr/bin/env bash
# Helper to export common Yocto variables for the PolarFire SoC AMP build.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export TEMPLATECONF="${REPO_ROOT}/yocto/layers/meta-polarfire-nn/conf/templates/mpfs-amp"
export MACHINE="${MACHINE:-mpfs-disco-kit}"
export DISTRO="${DISTRO:-polarfire-amp}"

cat <<EOF
[Yocto AMP env]
  TEMPLATECONF=${TEMPLATECONF}
  MACHINE=${MACHINE}
  DISTRO=${DISTRO}
EOF
