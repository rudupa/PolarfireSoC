#!/usr/bin/env bash
# Helper to export common Yocto variables for the PolarFire SoC AMP build.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ensure_yocto_sources() {
  local yocto_dir="${REPO_ROOT}/yocto"
  local poky_init="${yocto_dir}/sources/poky/oe-init-build-env"

  if [ -x "${poky_init}" ]; then
    return
  fi

  echo "[Yocto AMP env] poky sources missing — running repo init/sync" >&2

  if ! command -v repo >/dev/null 2>&1; then
    echo "[Yocto AMP env] error: 'repo' command not found; install it and rerun" >&2
    exit 1
  fi

  local manifest_repo="file://${REPO_ROOT}"
  local manifest_xml="yocto/manifests/default.xml"
  local manifest_branch
  manifest_branch="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"

  pushd "${yocto_dir}" >/dev/null || return 1
  if [ ! -d ".repo" ]; then
    if ! repo init -u "${manifest_repo}" -m "${manifest_xml}" -b "${manifest_branch}"; then
      echo "[Yocto AMP env] error: repo init failed" >&2
      popd >/dev/null
      return 1
    fi
  fi
  if ! repo sync; then
    echo "[Yocto AMP env] error: repo sync failed" >&2
    popd >/dev/null
    return 1
  fi
  popd >/dev/null || return 1
}

ensure_yocto_sources

export TEMPLATECONF="${REPO_ROOT}/yocto/layers/meta-polarfire-nn/conf/templates/mpfs-amp"
export MACHINE="${MACHINE:-mpfs-disco-kit}"

DEFAULT_DISTRO="polarfire-amp"
DISTRO_CONF="${REPO_ROOT}/yocto/layers/meta-polarfire-nn/conf/distro/${DEFAULT_DISTRO}.conf"
if [ ! -f "${DISTRO_CONF}" ]; then
  DEFAULT_DISTRO="poky"
fi
export DISTRO="${DISTRO:-${DEFAULT_DISTRO}}"

cat <<EOF
[Yocto AMP env]
  TEMPLATECONF=${TEMPLATECONF}
  MACHINE=${MACHINE}
  DISTRO=${DISTRO}
EOF

return 0 2>/dev/null || exit 0
