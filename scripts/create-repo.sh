#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="${ROOT_DIR}/repo"

mkdir -p "${REPO_DIR}"
rm -f "${REPO_DIR}"/*

echo "Collecting packages into ${REPO_DIR}..."
find "${ROOT_DIR}/packages" -name "*.pkg.tar.zst" -exec cp -v {} "${REPO_DIR}/" \;

cd "${REPO_DIR}"
echo "Building pacman repository database nabu.db.tar.zst..."
repo-add nabu.db.tar.zst *.pkg.tar.zst

echo "Repository database generated successfully in ${REPO_DIR}."
