#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rootfs_dir="$repo_root/rootfs"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <package-file>" >&2
  exit 1
fi

pkg_file="$1"
if [ ! -f "$pkg_file" ]; then
  echo "Package file not found: $pkg_file" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tar -xzf "$pkg_file" -C "$tmpdir"
cp -a "$tmpdir"/* "$rootfs_dir/"

echo "Installed package $(basename "$pkg_file") into rootfs"
