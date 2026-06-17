#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
pkg_repo="$repo_root/packages/pkgs"

mkdir -p "$pkg_repo/hello/payload/usr/bin"

cat > "$pkg_repo/hello/payload/usr/bin/hello" <<'EOF'
#!/bin/sh
echo "Hello from GungnirOS package hello!"
EOF
chmod 755 "$pkg_repo/hello/payload/usr/bin/hello"

cat > "$pkg_repo/hello/metadata" <<'EOF'
name: hello
version: 1.0
description: Simple demo package for GungnirOS
EOF

# Compile hello package using makepkg.sh
./scripts/makepkg.sh "$pkg_repo/hello" "$pkg_repo"

# Clean up raw folders so only the package tarball is left in packages/pkgs
rm -rf "$pkg_repo/hello"

# Compile other packages from source recipes
./scripts/makepkg.sh "$repo_root/packages/apache" "$pkg_repo"
./scripts/makepkg.sh "$repo_root/packages/ufw" "$pkg_repo"
./scripts/makepkg.sh "$repo_root/packages/kali-tools" "$pkg_repo"

echo "Created local package repository: hello, apache, ufw, kali-tools"
