#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build all AMP Zephyr harts with a single command.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: zephyr_amp.sh [options]

Options:
    -w, --workspace <path>      Zephyr west workspace (default: <repo>/zephyr)
    -a, --app <path>            Application CMakeLists root (default: <repo>/zephyr/apps/amp_pingpong)
    -o, --overlay <path>        Base shared-memory overlay passed via DTC_OVERLAY_FILE
    -O, --hart-overlay-dir <p>  Directory containing mpfs_discovery_u54_<n>.overlay files (default: <repo>/zephyr/boards)
    -b, --board <name>          Zephyr board (default: mpfs_icicle)
    -H, --harts "list"          Space-separated hart indices to build (default: 3)
    -B, --build-root <path>     Directory prefix for build outputs (default: <workspace>/build/amp_pingpong)
    --cmake-arg <arg>           Extra argument forwarded to CMake (repeatable)
    -h, --help                  Show this help text
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

default_workspace="${repo_root}/zephyr"
default_app="${repo_root}/zephyr/apps/amp_pingpong"
default_overlay="${repo_root}/bsp/device-tree/zephyr/mpfs-amp.overlay"
default_hart_overlay_dir="${repo_root}/zephyr/boards"
default_board="mpfs_icicle"
default_harts="3"
default_build_root="${default_workspace}/build/amp_pingpong"

workspace="${ZEPHYR_WORKSPACE:-$default_workspace}"
app_dir="${ZEPHYR_APP:-$default_app}"
overlay_path="${ZEPHYR_OVERLAY:-$default_overlay}"
hart_overlay_dir="${ZEPHYR_HART_OVERLAY_DIR:-$default_hart_overlay_dir}"
board="${ZEPHYR_BOARD:-$default_board}"
hart_list="${ZEPHYR_HARTS:-$default_harts}"
build_root="${ZEPHYR_BUILD_ROOT:-$default_build_root}"
cmake_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--workspace)
            workspace="$2"; shift 2 ;;
        -a|--app)
            app_dir="$2"; shift 2 ;;
        -o|--overlay)
            overlay_path="$2"; shift 2 ;;
        -O|--hart-overlay-dir)
            hart_overlay_dir="$2"; shift 2 ;;
        -b|--board)
            board="$2"; shift 2 ;;
        -H|--harts)
            hart_list="$2"; shift 2 ;;
        -B|--build-root)
            build_root="$2"; shift 2 ;;
        --cmake-arg)
            cmake_args+=("$2"); shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1 ;;
    esac
done

require_file() {
    if [[ ! -e "$1" ]]; then
        echo "Missing required path: $1" >&2
        exit 1
    fi
}

require_file "$overlay_path"
require_file "$app_dir/CMakeLists.txt"

if [[ ! -d "$workspace" ]]; then
    echo "Zephyr workspace not found: $workspace" >&2
    exit 1
fi

if ! command -v west >/dev/null 2>&1; then
    echo "west command not found in PATH" >&2
    exit 1
fi

if [[ ! -d "$hart_overlay_dir" ]]; then
    echo "Warning: hart overlay directory not found ($hart_overlay_dir); per-hart DTS fragments will be skipped" >&2
fi

echo "Building AMP harts ${hart_list} for board ${board}" | sed 's/  */ /g'

pushd "$workspace" >/dev/null
trap 'popd >/dev/null' EXIT

for hart in $hart_list; do
    build_dir="${build_root}_hart${hart}"
    per_hart_overlay="${hart_overlay_dir}/mpfs_discovery_u54_${hart}.overlay"
    overlay_arg="$overlay_path"
    if [[ -f "$per_hart_overlay" ]]; then
        overlay_arg="${overlay_arg};${per_hart_overlay}"
    else
        echo "Warning: no per-hart overlay found for u54_${hart} (expected $per_hart_overlay)" >&2
    fi

    cmake_extra=(
        "-DCONFIG_MPFS_HART_INDEX=${hart}"
        "-DDTC_OVERLAY_FILE=${overlay_arg}"
    )

    echo "\n==> west build (hart ${hart})" >&2
    west -d "$build_dir" build -p auto -b "$board" "$app_dir" -- "${cmake_extra[@]}" "${cmake_args[@]}"
    echo "Built $build_dir/zephyr/zephyr.elf" >&2
done
