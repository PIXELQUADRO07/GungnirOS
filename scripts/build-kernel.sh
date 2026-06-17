#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
kernel_src="$repo_root/kernel/linux-6.6.21"
boot_dir="$repo_root/boot"

mkdir -p "$boot_dir"

if [ ! -f "$kernel_src/arch/x86/boot/bzImage" ]; then
  echo "Kernel image not found: $kernel_src/arch/x86/boot/bzImage" >&2
  echo "Build the kernel first in $kernel_src" >&2
  exit 1
fi

cp "$kernel_src/arch/x86/boot/bzImage" "$boot_dir/vmlinuz-6.6.21"
ln -sf vmlinuz-6.6.21 "$boot_dir/vmlinuz"
chmod 644 "$boot_dir/vmlinuz-6.6.21"

echo "Kernel copied to $boot_dir/vmlinuz-6.6.21"
