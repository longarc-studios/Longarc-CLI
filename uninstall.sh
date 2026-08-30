#!/bin/sh

set -eu
umask 077

die() {
  printf '%s\n' "longarc uninstall: $1" >&2
  exit 1
}

main() {
  reset_memory='false'
  if [ "$#" -eq 1 ] && [ "$1" = '--reset-memory' ]; then
    reset_memory='true'
  elif [ "$#" -ne 0 ]; then
    die 'usage: uninstall.sh [--reset-memory]'
  fi

  [ "$(/usr/bin/id -u)" -ne 0 ] || die 'do not run this uninstaller with sudo'
  : "${HOME:?HOME is required}"
  install_root=${LONGARC_INSTALL_ROOT:-"$HOME/.local/share/longarc"}
  bin_dir=${LONGARC_BIN_DIR:-"$HOME/.local/bin"}

  case "$install_root" in
    /*/longarc) ;;
    *) die 'install root must be an absolute path ending in /longarc' ;;
  esac
  [ "$install_root" != '/longarc' ] || die 'install root is too broad'
  case "$bin_dir" in
    /*) ;;
    *) die 'binary directory must be absolute' ;;
  esac
  [ "$bin_dir" != '/' ] || die 'binary directory is too broad'

  command_path="$bin_dir/longarc"
  expected_target="$install_root/current/longarc-core"
  if [ -e "$command_path" ] && [ ! -L "$command_path" ]; then
    die 'longarc command is not an installer-owned symbolic link'
  fi
  if [ -L "$command_path" ]; then
    observed_target=$(/usr/bin/readlink "$command_path")
    [ "$observed_target" = "$expected_target" ] \
      || die 'longarc command link is not owned by this installer'
  fi
  if [ -L "$install_root" ]; then
    die 'install root may not be a symbolic link'
  fi
  if [ -e "$install_root" ] && [ ! -d "$install_root" ]; then
    die 'install root is not a directory'
  fi

  if [ "$reset_memory" = 'true' ]; then
    [ -x "$command_path" ] || die 'installed command is required to reset memory safely'
    "$command_path" memory reset --yes \
      || die 'memory reset failed; nothing was uninstalled'
  fi

  if [ -L "$command_path" ]; then
    /bin/rm "$command_path"
  fi
  if [ -d "$install_root" ]; then
    /bin/rm -rf "$install_root"
  fi

  printf '%s\n' 'Long Arc application files were removed.'
  if [ "$reset_memory" = 'true' ]; then
    printf '%s\n' 'The Memory Lane vault and key were reset before uninstall.'
  else
    printf '%s\n' 'The encrypted Memory Lane vault and local receipts were preserved.'
  fi
}

main "$@"
