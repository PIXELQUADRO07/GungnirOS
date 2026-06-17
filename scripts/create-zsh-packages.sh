#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
pkg_repo="$repo_root/packages/pkgs"
zsh_pkg="$pkg_repo/zsh"
ohmyzsh_pkg="$pkg_repo/oh-my-zsh"

echo "=== Creating zsh Package ==="

# Create zsh stub (minimal shell wrapper until we have real binary)
mkdir -p "$zsh_pkg/payload/usr/bin"
mkdir -p "$zsh_pkg/payload/etc"

# Create minimal zsh stub that references busybox ash
cat > "$zsh_pkg/payload/usr/bin/zsh" <<'ZSH_STUB'
#!/bin/sh
# Zsh compatibility wrapper - uses busybox ash as fallback
exec /bin/ash "$@"
ZSH_STUB
chmod 755 "$zsh_pkg/payload/usr/bin/zsh"

# Create zshrc stub
mkdir -p "$zsh_pkg/payload/etc"
cat > "$zsh_pkg/payload/etc/zsh.conf" <<'ZSHCONF'
# GungnirOS zsh configuration
export HISTFILE=~/.zsh_history
export HISTSIZE=1000
export SAVEHIST=1000

# Aliases
alias ls='ls -la'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'

setopt SHARE_HISTORY
ZSHCONF

cat > "$zsh_pkg/metadata" <<'ZSHM'
name: zsh
version: 5.9-stub
description: Z Shell (wrapped for GungnirOS minimal system)
repository: local
installed_size: 64K
ZSHM

echo "✓ Created zsh package"

echo "=== Creating oh-my-zsh Package ==="

# Create oh-my-zsh stub
mkdir -p "$ohmyzsh_pkg/payload/root/.oh-my-zsh/themes"
mkdir -p "$ohmyzsh_pkg/payload/root/.oh-my-zsh/plugins"
mkdir -p "$ohmyzsh_pkg/payload/root/.oh-my-zsh/lib"

# Create minimal oh-my-zsh initialization
cat > "$ohmyzsh_pkg/payload/root/.zshrc" <<'ZSHRC'
# GungnirOS Oh-My-Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="robbyrussell"

# Plugins (stub)
plugins=(git debian systemd)

# Minimal source
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Aliases
alias ys='pacman -Ss'
alias yi='pacman -S'
alias yq='pacman -Q'
alias yii='pacman -Qi'
ZSHRC

# Create oh-my-zsh stub initialization
cat > "$ohmyzsh_pkg/payload/root/.oh-my-zsh/oh-my-zsh.sh" <<'OHMYZSH'
#!/bin/sh
# Oh-My-Zsh compatibility stub for GungnirOS
# Minimal initialization

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_THEME="${ZSH_THEME:-robbyrussell}"

# Load plugins from lib if available
if [ -d "$ZSH/lib" ]; then
  for plugin in "$ZSH/lib"/*.zsh; do
    [ -f "$plugin" ] && source "$plugin"
  done
fi

# Welcome message
cat <<'WELCOME'
 ╔════════════════════════════════════════╗
 ║      GungnirOS - Oh-My-Zsh Shell       ║
 ║      Built to understand computers    ║
 ╚════════════════════════════════════════╝
WELCOME
OHMYZSH
chmod 755 "$ohmyzsh_pkg/payload/root/.oh-my-zsh/oh-my-zsh.sh"

# Create minimal robbyrussell theme
cat > "$ohmyzsh_pkg/payload/root/.oh-my-zsh/themes/robbyrussell.zsh-theme" <<'THEME'
# Minimal robbyrussell theme stub
PS1='%n@%m:%~$ '
THEME

cat > "$ohmyzsh_pkg/metadata" <<'OHMM'
name: oh-my-zsh
version: 1.0-stub
description: Oh-My-Zsh framework for GungnirOS (stub implementation)
repository: local
installed_size: 128K
depends: zsh
OHMM

echo "✓ Created oh-my-zsh package"

# Build package archives using makepkg.sh
./scripts/makepkg.sh "$zsh_pkg" "$pkg_repo"
./scripts/makepkg.sh "$ohmyzsh_pkg" "$pkg_repo"

# Clean up raw folders so only the package tarballs remain
rm -rf "$zsh_pkg" "$ohmyzsh_pkg"

echo ""
echo "=== Package Creation Summary ==="
echo "zsh package archive created."
echo "oh-my-zsh package archive created."
echo ""
echo "To install:"
echo "  pacman -S zsh"
echo "  pacman -S oh-my-zsh"

