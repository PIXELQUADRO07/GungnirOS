#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rootfs_dir="$repo_root/rootfs"
busybox_path="${BUSYBOX_PATH:-}"

if [ -z "$busybox_path" ]; then
  if command -v busybox >/dev/null 2>&1; then
    busybox_path=$(command -v busybox)
  elif [ -x "$repo_root/packages/busybox/output/busybox" ]; then
    busybox_path="$repo_root/packages/busybox/output/busybox"
  fi
fi

if [ -z "$busybox_path" ]; then
  cat >&2 <<'EOF'
Error: busybox not found.

Install busybox on the host, build a local BusyBox package, or set BUSYBOX_PATH to a valid busybox binary before running this script.
Example:
  BUSYBOX_PATH=/usr/bin/busybox ./scripts/build.sh
  ./scripts/build-busybox.sh && ./scripts/build.sh
EOF
  exit 1
fi

rm -rf "$rootfs_dir"
mkdir -p "$rootfs_dir"/{bin,sbin,etc/init.d,proc,sys,dev,usr/bin,usr/sbin,run,tmp,root,var/lib/pacman/repo,var/lib/pacman/local,usr/share/pacman}

cp "$busybox_path" "$rootfs_dir/bin/busybox"
chmod 755 "$rootfs_dir/bin/busybox"

# Create symlinks for BusyBox applets in /bin/
for app in sh ash login mount umount mkdir ls cat echo ln sleep ps dmesg uname rm vi tar gzip gunzip hostname ifconfig udhcpc; do
  ln -sf busybox "$rootfs_dir/bin/$app"
done

# Create symlinks for BusyBox applets in /sbin/
for app in init mdev syslogd klogd getty reboot poweroff; do
  ln -sf ../bin/busybox "$rootfs_dir/sbin/$app"
done

# Set up /init as a symlink to /sbin/init
ln -sf sbin/init "$rootfs_dir/init"

# Copy pacman script
install -m 755 "$repo_root/scripts/pacman.sh" "$rootfs_dir/usr/bin/pacman"
ln -sf /usr/bin/pacman "$rootfs_dir/bin/pacman"

# Copy package archives (*.pkg.tar.gz) to local repo
cp -a "$repo_root/packages/pkgs"/*.pkg.tar.gz "$rootfs_dir/var/lib/pacman/repo/" 2>/dev/null || true

# Copy configuration files from templates
cp "$repo_root/init/inittab" "$rootfs_dir/etc/inittab"
cp "$repo_root/init/rcS" "$rootfs_dir/etc/init.d/rcS"
chmod 755 "$rootfs_dir/etc/init.d/rcS"
cp "$repo_root/init/profile" "$rootfs_dir/etc/profile"
cp "$repo_root/init/hostname" "$rootfs_dir/etc/hostname"
cp "$repo_root/init/fstab" "$rootfs_dir/etc/fstab"

# Create issue file
cat > "$rootfs_dir/etc/issue" <<'EOF'
GungnirOS (v0.0.1-alpha)
EOF

# Create passwd and group configurations
cat > "$rootfs_dir/etc/passwd" <<'EOF'
root::0:0:root:/root:/bin/sh
EOF

cat > "$rootfs_dir/etc/group" <<'EOF'
root:x:0:
wheel:x:1:root
EOF

# Preinstall zsh and oh-my-zsh into rootfs directly
zsh_archive=$(find "$repo_root/packages/pkgs" -name "zsh-*.pkg.tar.gz" | head -n 1)
if [ -n "$zsh_archive" ] && [ -f "$zsh_archive" ]; then
  echo "Pre-installing zsh..."
  tar -zxf "$zsh_archive" --exclude=".PKGINFO" -C "$rootfs_dir"
  mkdir -p "$rootfs_dir/var/lib/pacman/local/zsh"
  tar -ztf "$zsh_archive" | grep -v '^\.$' | grep -v '^\.PKGINFO$' | sed 's|^\./||' > "$rootfs_dir/var/lib/pacman/local/zsh/files"
  tar -zxf "$zsh_archive" .PKGINFO -O > "$rootfs_dir/var/lib/pacman/local/zsh/metadata"
  
  # Set default shell to /usr/bin/zsh in passwd
  sed -i 's|:/bin/sh|:/usr/bin/zsh|' "$rootfs_dir/etc/passwd"
fi

omz_archive=$(find "$repo_root/packages/pkgs" -name "oh-my-zsh-*.pkg.tar.gz" | head -n 1)
if [ -n "$omz_archive" ] && [ -f "$omz_archive" ]; then
  echo "Pre-installing oh-my-zsh..."
  tar -zxf "$omz_archive" --exclude=".PKGINFO" -C "$rootfs_dir"
  mkdir -p "$rootfs_dir/var/lib/pacman/local/oh-my-zsh"
  tar -ztf "$omz_archive" | grep -v '^\.$' | grep -v '^\.PKGINFO$' | sed 's|^\./||' > "$rootfs_dir/var/lib/pacman/local/oh-my-zsh/files"
  tar -zxf "$omz_archive" .PKGINFO -O > "$rootfs_dir/var/lib/pacman/local/oh-my-zsh/metadata"
fi

echo "Root filesystem prepared at $rootfs_dir"
echo "- busybox: $busybox_path"
echo "- init: $rootfs_dir/init"
