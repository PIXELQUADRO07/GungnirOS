#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rootfs_dir="$repo_root/rootfs"
output="$repo_root/boot/initramfs.cpio.gz"

if [ ! -d "$rootfs_dir" ]; then
  echo "Root filesystem directory does not exist: $rootfs_dir" >&2
  echo "Run ./scripts/build-rootfs.sh first." >&2
  exit 1
fi

cd "$rootfs_dir"
find . | cpio -H newc -ov --owner root:root 2>/dev/null | gzip -9 > "$output"

chmod 644 "$output"
echo "Created initramfs image: $output"
