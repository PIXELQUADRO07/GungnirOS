# GungnirOS

> Minimal. Transparent. Built to understand computers.

GungnirOS is an experimental operating system project created to explore how Linux distributions and operating systems work internally.

The project starts from a Linux-based environment and may progressively evolve into a more custom system.

## Goals

- Learn operating system architecture
- Understand Linux internals
- Build custom boot and startup flows
- Experiment with package management
- Create a reproducible build system
- Explore kernel and userspace interaction

## Current Status

Stage: **Alpha (Buildable)**

Progress:
- [x] Repository created
- [x] Define architecture
- [x] Create build system
- [x] Boot first image
- [ ] Launch first shell
- [ ] Create installer
- [ ] Package system
- [ ] Full distribution

## Quick Start

### Build the System

```bash
cd /home/gaetal/github/GungnirOS
./scripts/build-quick.sh
```

This creates a minimal bootable Linux system (~1-2 MB).

### Boot with QEMU

```bash
./scripts/boot-qemu.sh
```

For detailed build and boot instructions, see [BOOT_AND_BUILD.md](BOOT_AND_BUILD.md).

## Planned Structure


GungnirOS/
├── boot/
├── kernel/
├── init/
├── packages/
├── rootfs/
├── scripts/
├── iso/
└── docs/


## Development Environment

Architecture:
- x86_64

Tools:
- QEMU
- GCC
- Make
- GRUB
- Linux

## Build

From repository root:

```sh
./scripts/build.sh
```

If the host does not provide BusyBox, the build script will automatically build a local BusyBox package.

The system also includes a minimal package management prototype based on a local pacman-style repository.
Current package manager status:
- `pacman -S <pkg>` installs a package from `/var/lib/pacman/repo`
- `pacman -Ss <pattern>` searches available packages
- `pacman -Qi <pkg>` shows package metadata
- `pacman -Q` lists installed packages

What is still missing for an operational system:
- a real package build system and package format
- repository indexing and remote package downloading
- a persistent root filesystem on disk rather than only initramfs
- GRUB/bootloader installation for real disks
- better init and service startup logic
- proper device node creation and runtime configuration

To boot the generated image:

```sh
./scripts/boot-qemu.sh
```

## Roadmap

Version 0.0.1-alpha
- Boot
- Init
- Shell

Version 0.1
- Filesystem
- Package system

Version 1.0
- First usable release

## License

MIT
