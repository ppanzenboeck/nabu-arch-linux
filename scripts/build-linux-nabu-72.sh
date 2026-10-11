#!/usr/bin/env bash
# ==============================================================================
# build-linux-nabu-72.sh
# Automated build script for Linux 7.2.9 on Xiaomi Pad 5 (nabu)
# Author: Panz Dev <panz.development@gmail.com>
# Upstream Linux 7.2 port: Kumar-Jy <https://github.com/Kumar-Jy/linux-nabu#7.2>
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="${ROOT_DIR}/packages/linux-nabu-72"
NUM_JOBS="$(nproc)"

echo "======================================================================"
echo "  Building Linux 7.2.9 for Xiaomi Pad 5 (nabu)"
echo "  Using ${NUM_JOBS} parallel threads (-j${NUM_JOBS})"
echo "  Upstream tree: https://github.com/Kumar-Jy/linux-nabu (branch 7.2)"
echo "======================================================================"

# Verify required tools
for tool in makepkg git bc dtc aarch64-linux-gnu-gcc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Required tool '$tool' is not installed or not in PATH."
    exit 1
  fi
done

cd "${PKG_DIR}"

echo "Starting package build with MAKEFLAGS=\"-j${NUM_JOBS}\"..."
export MAKEFLAGS="-j${NUM_JOBS}"
CARCH=aarch64 makepkg -s -f -d --skipinteg "$@"

echo "Package build complete!"
echo "Updating pacman repository database in repo/..."
"${ROOT_DIR}/scripts/create-repo.sh"

echo "======================================================================"
echo "  Done! The package has been built and added to repo/."
echo "======================================================================"
