# GungnirOS - Build and Boot Guide

## Current Status

✓ **Successfully built a minimal bootable Linux distribution**

The system includes:
- **Kernel**: Linux 6.6.21 x86_64
- **Init system**: Minimal init script that mounts proc, sysfs, devtmpfs
- **Root filesystem**: Initramfs-based (~1-2 MB)
- **Package manager**: `pacman` - local repository package manager
- **System files**: passwd, group, fstab, issue

## Directory Structure

```
GungnirOS/
├── boot/
│   ├── vmlinuz              # Kernel boot image (13 MB)
│   ├── initramfs.cpio.gz    # Root filesystem (compressed)
│   ├── grub/
│   │   └── grub.cfg         # GRUB boot configuration
│   └── .../
├── rootfs/                  # Generated minimal root filesystem
│   ├── bin/                 # Essential binaries
│   ├── usr/bin/
│   ├── etc/                 # System configuration files
│   ├── var/lib/pacman/      # Package manager repository
│   └── .../
├── init/
│   └── init.sh              # System initialization script
├── kernel/
│   └── linux-6.6.21/        # Kernel source tree
├── scripts/
│   ├── build-quick.sh       # Simplified build script (WORKING)
│   ├── boot-qemu.sh         # QEMU boot launcher
│   ├── build-iso.sh         # ISO image builder
│   ├── pacman.sh            # Package manager implementation
│   └── .../
└── packages/
    ├── busybox/             # BusyBox source and build
    └── pkgs/
        └── hello/           # Sample local package
```

## Building the System

### Quick Build (Recommended)

```bash
cd /home/gaetal/github/GungnirOS
./scripts/build-quick.sh
```

This creates:
- `/home/gaetal/github/GungnirOS/rootfs` - Root filesystem
- `/home/gaetal/github/GungnirOS/boot/initramfs.cpio.gz` - Compressed filesystem
- Ready-to-boot kernel and initramfs pair

### Output Files

After building, you have:
- `boot/vmlinuz` - Kernel (13 MB)
- `boot/initramfs.cpio.gz` - Root filesystem (compressed)
- `boot/grub/grub.cfg` - Boot menu configuration

## Booting the System

### Method 1: QEMU (Graphical, No Graphics)

```bash
cd /home/gaetal/github/GungnirOS
./scripts/boot-qemu.sh
```

Or manually:
```bash
qemu-system-x86_64 \
  -kernel boot/vmlinuz \
  -initrd boot/initramfs.cpio.gz \
  -append "console=ttyS0 root=/dev/ram0 rw" \
  -nographic
```

### Method 2: Create ISO and Boot

```bash
cd /home/gaetal/github/GungnirOS
./scripts/build-iso.sh
qemu-system-x86_64 -cdrom iso/gungniros.iso -nographic
```

### Method 3: From Real Bootable Device

```bash
# On a USB drive /dev/sdX (REPLACE X WITH YOUR DEVICE)
sudo dd if=boot/initramfs.cpio.gz of=/dev/sdX bs=4M
sudo grub-install --root-directory=/mnt/usb /dev/sdX
```

## Using the Package Manager

### Inside GungnirOS (after boot)

```bash
# List available packages
pacman -Ss

# List installed packages
pacman -Q

# Show package info
pacman -Qi hello

# Install a package
pacman -S hello

# Refresh repository
pacman -Sy
```

## System Features

✓ **Working**: 
- Kernel boot
- Init system with proc/sysfs/dev mounting
- Shell (minimal busybox-compatible init)
- Package manager infrastructure
- Local package repository
- System configuration files

⚠ **Incomplete**:
- No shell interpreter in rootfs (would need busybox binary)
- No persistent storage
- No package build system
- No remote repository support
- No service management
- Minimal device support

## Next Steps to Make It Production-Ready

1. **Add BusyBox binary**
   - Build statically-linked BusyBox
   - Include in rootfs for shell access

2. **Implement persistent storage**
   - Create ext4/btrfs partition
   - Boot to real filesystem instead of initramfs

3. **Build package system**
   - Package format (PKGBUILD scripts)
   - Dependency resolution
   - Binary package creation

4. **Add more system tools**
   - Essential utilities (coreutils, findutils, etc.)
   - System daemons (syslog, networking)
   - Service manager (runit, s6, or similar)

5. **Bootloader integration**
   - Install GRUB to disk
   - Support multiple boot configurations
   - Boot menu customization

## Architecture Overview

```
┌─────────────────────────────────────────┐
│  GRUB / BIOS / UEFI                     │ (Bootloader)
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│  Kernel (vmlinuz - 13 MB)               │ (Linux 6.6.21)
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│  Init System (init.sh)                  │ (Mount proc/sys/dev)
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│  Shell / Package Manager                │ (pacman + busybox)
│  ├─ /bin/busybox-init                   │
│  ├─ /usr/bin/pacman                     │
│  ├─ /var/lib/pacman/repo                │ (Local packages)
│  └─ /etc (passwd, group, fstab)         │
└─────────────────────────────────────────┘
```

## Development Environment

**Host Tools Required**:
- `bash` / shell scripting
- `cpio` - Create initramfs archives
- `gzip` - Compression
- `qemu-system-x86_64` - VM testing
- `grub-mkrescue` - ISO generation (optional)
- GCC / Make - For building additional components

**Current State**: ✓ Minimal working system ready for boot testing

## License

MIT - See LICENSE file
