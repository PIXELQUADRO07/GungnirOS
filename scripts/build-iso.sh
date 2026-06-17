#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
iso_dir="$repo_root/iso"
boot_dir="$repo_root/boot"

if [ ! -f "$boot_dir/vmlinuz" ] || [ ! -f "$boot_dir/initramfs.cpio.gz" ]; then
  echo "Boot artifacts missing. Run ./scripts/build.sh first." >&2
  exit 1
fi

mkdir -p "$iso_dir/boot/grub"
rm -rf "$iso_dir/boot/grub/*"
cp "$boot_dir/vmlinuz" "$iso_dir/boot/vmlinuz"
cp "$boot_dir/initramfs.cpio.gz" "$iso_dir/boot/initramfs.cpio.gz"
cp "$repo_root/boot/grub/grub.cfg" "$iso_dir/boot/grub/grub.cfg"

if command -v grub-mkrescue >/dev/null 2>&1; then
  grub-mkrescue -o "$repo_root/iso/gungniros.iso" "$iso_dir" >/dev/null
  echo "ISO image created: $repo_root/iso/gungniros.iso"
else
  echo "Error: grub-mkrescue is required to create the ISO." >&2
  exit 1
fi
