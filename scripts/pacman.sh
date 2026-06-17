#!/bin/sh
# scripts/pacman.sh - GungnirOS package manager (tar.gz archive version)
set -e

repo=${PACMAN_REPO:-/var/lib/pacman/repo}
localdb=${PACMAN_LOCALDB:-/var/lib/pacman/local}

ensure_repo() {
  [ -d "$repo" ] || {
    echo "pacman: repository directory not found: $repo" >&2
    exit 1
  }
}

ensure_localdb() {
  mkdir -p "$localdb"
}

# Scan repo for package tarballs and list package names and versions
list_repo() {
  ensure_repo
  for pkg_path in "$repo"/*.pkg.tar.gz; do
    if [ -f "$pkg_path" ]; then
      basename "$pkg_path" | sed 's/\.pkg\.tar\.gz$//'
    fi
  done
}

search_repo() {
  pattern="$1"
  list_repo | grep -i "$pattern" || true
}

install_package_file() {
  pkg_archive="$1"
  if [ ! -f "$pkg_archive" ]; then
    echo "pacman: package file not found: $pkg_archive" >&2
    exit 1
  fi

  # Create a temp directory to extract metadata and verify
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  # Extract only .PKGINFO
  tar -zxf "$pkg_archive" .PKGINFO -C "$tmp_dir" 2>/dev/null || {
    echo "pacman: invalid package archive (missing .PKGINFO)" >&2
    exit 1
  }

  # Parse .PKGINFO
  pkgname=$(grep -E '^pkgname\s*=' "$tmp_dir/.PKGINFO" | cut -d'=' -f2- | xargs)
  pkgver=$(grep -E '^pkgver\s*=' "$tmp_dir/.PKGINFO" | cut -d'=' -f2- | xargs)

  if [ -z "$pkgname" ]; then
    echo "pacman: invalid .PKGINFO file" >&2
    exit 1
  fi

  # Check if already installed
  if [ -d "$localdb/$pkgname" ]; then
    echo "pacman: package $pkgname is already installed (reinstalling...)"
    remove_package "$pkgname" || true
  fi

  echo "Installing $pkgname ($pkgver)..."

  # Save files list
  mkdir -p "$localdb/$pkgname"
  # List files, excluding directories and .PKGINFO
  tar -ztf "$pkg_archive" | grep -v '^\.$' | grep -v '^\.PKGINFO$' | sed 's|^\./||' > "$localdb/$pkgname/files"

  # Extract payload to root
  tar -zxf "$pkg_archive" --exclude=".PKGINFO" -C /

  # Save metadata
  cp "$tmp_dir/.PKGINFO" "$localdb/$pkgname/metadata"

  echo "Package $pkgname-$pkgver installed successfully."
}

install_package_name() {
  pkgname="$1"
  ensure_repo
  
  # Find package archive matching pkgname
  found_archive=""
  for archive in "$repo"/"$pkgname"-*.pkg.tar.gz; do
    if [ -f "$archive" ]; then
      found_archive="$archive"
      break
    fi
  done

  if [ -z "$found_archive" ]; then
    echo "pacman: package not found in repository: $pkgname" >&2
    exit 1
  fi

  install_package_file "$found_archive"
}

remove_package() {
  pkgname="$1"
  pkg_dir="$localdb/$pkgname"

  if [ ! -d "$pkg_dir" ]; then
    echo "pacman: package not installed: $pkgname" >&2
    exit 1
  fi

  echo "Removing $pkgname..."

  # Read files list and remove files in reverse order
  # (reverse order ensures we delete files before their parent directories)
  files_file="$pkg_dir/files"
  if [ -f "$files_file" ]; then
    # Reverse lines
    if command -v tac >/dev/null 2>&1; then
      tac "$files_file"
    else
      # Fallback for systems without tac
      awk '{a[i++]=$0} END {for (j=i-1; j>=0; j--) print a[j]}' "$files_file"
    fi | while read -r file; do
      # Clean path
      file=$(echo "$file" | sed 's|^\./||')
      # Make sure path is absolute
      abs_path="/$file"
      if [ -L "$abs_path" ] || [ -f "$abs_path" ]; then
        rm -f "$abs_path"
      elif [ -d "$abs_path" ]; then
        # Try to remove directory, will only succeed if empty
        rmdir "$abs_path" 2>/dev/null || true
      fi
    done
  fi

  rm -rf "$pkg_dir"
  echo "Package $pkgname removed successfully."
}

query_installed() {
  pkgname="$1"
  pkg_dir="$localdb/$pkgname"
  if [ -d "$pkg_dir" ]; then
    if [ -f "$pkg_dir/metadata" ]; then
      cat "$pkg_dir/metadata"
    else
      echo "Name: $pkgname"
    fi
  else
    echo "pacman: package not installed: $pkgname" >&2
    exit 1
  fi
}

list_installed() {
  ensure_localdb
  for d in "$localdb"/*; do
    if [ -d "$d" ]; then
      basename "$d"
    fi
  done
}

list_package_files() {
  pkgname="$1"
  files_file="$localdb/$pkgname/files"
  if [ -f "$files_file" ]; then
    cat "$files_file"
  else
    echo "pacman: package $pkgname not installed or file list missing" >&2
    exit 1
  fi
}

case "$1" in
  -S|--sync)
    [ $# -eq 2 ] || { echo "Usage: pacman -S <pkg>" >&2; exit 1; }
    ensure_repo
    ensure_localdb
    install_package_name "$2"
    ;;
  -U|--upgrade)
    [ $# -eq 2 ] || { echo "Usage: pacman -U <path_to_pkg.tar.gz>" >&2; exit 1; }
    ensure_localdb
    install_package_file "$2"
    ;;
  -R|--remove)
    [ $# -eq 2 ] || { echo "Usage: pacman -R <pkg>" >&2; exit 1; }
    ensure_localdb
    remove_package "$2"
    ;;
  -Sy|--refresh)
    ensure_repo
    echo "pacman: refreshed local repository index from $repo"
    ;;
  -Ss|--search)
    [ $# -eq 2 ] || { echo "Usage: pacman -Ss <pattern>" >&2; exit 1; }
    ensure_repo
    search_repo "$2"
    ;;
  -Qi|--info)
    [ $# -eq 2 ] || { echo "Usage: pacman -Qi <pkg>" >&2; exit 1; }
    query_installed "$2"
    ;;
  -Ql|--list)
    [ $# -eq 2 ] || { echo "Usage: pacman -Ql <pkg>" >&2; exit 1; }
    list_package_files "$2"
    ;;
  -Q|--query)
    list_installed
    ;;
  --help|-h)
    cat <<EOF
Usage: pacman [options]
  -S, --sync <pkg>       Install a package from the repository
  -U, --upgrade <file>   Install/Upgrade from a local archive file
  -R, --remove <pkg>     Remove/Uninstall an installed package
  -Sy, --refresh         Refresh local repository metadata
  -Ss, --search <pat>    Search available packages in repository
  -Qi, --info <pkg>      Query installed package info
  -Ql, --list <pkg>      List files owned by an installed package
  -Q, --query            List all installed packages
EOF
    ;;
  *)
    echo "pacman: unsupported command. Try 'pacman --help'" >&2
    exit 1
    ;;
esac
