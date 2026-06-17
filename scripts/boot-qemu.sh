#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

if [ ! -f boot/vmlinuz ] || [ ! -f boot/initramfs.cpio.gz ]; then
  echo "Boot artifacts are missing. Run ./scripts/build.sh first." >&2
  exit 1
fi

exec qemu-system-x86_64 \
  -kernel boot/vmlinuz \
  -initrd boot/initramfs.cpio.gz \
  -append "console=ttyS0 root=/dev/ram0 rw" \
  -nographic
