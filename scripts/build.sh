#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)

cd "$repo_root"

if [ -z "${BUSYBOX_PATH:-}" ] && ! command -v busybox >/dev/null 2>&1 && [ ! -x "$repo_root/packages/busybox/output/busybox" ]; then
  echo "BusyBox not found on host; building local BusyBox package."
  ./scripts/build-busybox.sh
fi

if [ -z "${BUSYBOX_PATH:-}" ] && [ -x "$repo_root/packages/busybox/output/busybox" ]; then
  export BUSYBOX_PATH="$repo_root/packages/busybox/output/busybox"
fi

if [ ! -d "$repo_root/packages/pkgs" ] || [ -z "$(ls -A "$repo_root/packages/pkgs" 2>/dev/null)" ]; then
  echo "Local package repository is empty; building sample packages."
  ./scripts/build-pkg-repo.sh
fi

./scripts/build-kernel.sh
./scripts/build-rootfs.sh
./scripts/build-initramfs.sh

cat <<'EOF'
Build complete.

Boot files are ready in the boot/ directory:
  - boot/vmlinuz
  - boot/initramfs.cpio.gz

To boot with QEMU:
  qemu-system-x86_64 -kernel boot/vmlinuz -initrd boot/initramfs.cpio.gz \
    -append "console=ttyS0 root=/dev/ram0" -nographic
EOF
