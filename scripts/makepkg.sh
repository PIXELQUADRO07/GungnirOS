#!/usr/bin/env bash
# scripts/makepkg.sh - GungnirOS package builder
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <package_directory> [output_directory]" >&2
  exit 1
fi

pkg_dir=$(cd "$1" && pwd)
out_dir=${2:-$(dirname "$pkg_dir")}

metadata_file="$pkg_dir/metadata"
if [ ! -f "$metadata_file" ]; then
  echo "Error: metadata file not found in $pkg_dir" >&2
  exit 1
fi

payload_dir="$pkg_dir/payload"
if [ ! -d "$payload_dir" ]; then
  echo "Error: payload directory not found in $pkg_dir" >&2
  exit 1
fi

# Parse metadata
pkgname=$(grep -E '^name:' "$metadata_file" | cut -d':' -f2- | xargs)
pkgver=$(grep -E '^version:' "$metadata_file" | cut -d':' -f2- | xargs)
pkgdesc=$(grep -E '^description:' "$metadata_file" | cut -d':' -f2- | xargs)

if [ -z "$pkgname" ] || [ -z "$pkgver" ]; then
  echo "Error: Invalid metadata. 'name' and 'version' are required." >&2
  exit 1
fi

echo "Building package $pkgname-$pkgver..."

# Create temp build directory
tmp_build=$(mktemp -d)
trap 'rm -rf "$tmp_build"' EXIT

# Copy payload to temp directory
cp -a "$payload_dir"/* "$tmp_build/" 2>/dev/null || true

# Generate .PKGINFO inside package
cat > "$tmp_build/.PKGINFO" <<EOF
pkgname = $pkgname
pkgver = $pkgver
pkgdesc = $pkgdesc
builddate = $(date +%s)
EOF

# Create package tarball
out_pkg="$out_dir/$pkgname-$pkgver.pkg.tar.gz"
mkdir -p "$out_dir"
cd "$tmp_build"
shopt -s dotglob
tar -czf "$out_pkg" *
cd - >/dev/null

echo "Package successfully built: $out_pkg"
