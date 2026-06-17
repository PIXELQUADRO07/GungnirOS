#!/usr/bin/env bash
# scripts/build-quick.sh - GungnirOS quick build system
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
boot_dir="$repo_root/boot"

echo "=== GungnirOS Quick Build System ==="
echo "Repository root: $repo_root"

# Step 1: Check for required tools
echo ""
echo "[1/3] Checking for required tools..."
for tool in cpio gzip find; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Required tool '$tool' not found" >&2
    exit 1
  fi
done
echo "✓ Required tools found"

# Step 2: Verify kernel exists
echo ""
echo "[2/3] Verifying kernel boot image..."
if [ ! -f "$boot_dir/vmlinuz" ]; then
  echo "ERROR: Kernel image not found at $boot_dir/vmlinuz" >&2
  exit 1
fi
echo "✓ Kernel found"

# Step 3: Create rootfs and initramfs
echo ""
echo "[3/3] Generating root filesystem and initramfs..."
./scripts/build-rootfs.sh
./scripts/build-initramfs.sh

echo ""
echo "=== Build Complete ==="
echo "Kernel:    $boot_dir/vmlinuz"
echo "Initramfs: $boot_dir/initramfs.cpio.gz"
echo ""
echo "To boot in QEMU: ./scripts/boot-qemu.sh"
