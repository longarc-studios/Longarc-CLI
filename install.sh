#!/bin/sh

set -eu
umask 077

repository='longarc-studios/Longarc-CLI'
required_codex_version='codex-cli 0.147.0'
download_root=''
stage_root=''

die() {
  printf '%s\n' "longarc install: $1" >&2
  exit 1
}

cleanup() {
  if [ -n "$stage_root" ] && [ -d "$stage_root" ]; then
    /bin/rm -rf "$stage_root"
  fi
  if [ -n "$download_root" ] && [ -d "$download_root" ]; then
    /bin/rm -rf "$download_root"
  fi
}

trap cleanup EXIT HUP INT TERM

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command is unavailable: $1"
}

validate_version() {
  printf '%s\n' "$1" | /usr/bin/grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+$' \
    || die 'release tag must look like v0.1.0-alpha.1'
}

validate_install_root() {
  case "$1" in
    /*/longarc) ;;
    *) die 'install root must be an absolute path ending in /longarc' ;;
  esac
  [ "$1" != '/longarc' ] || die 'install root is too broad'
}

validate_bin_dir() {
  case "$1" in
    /*) ;;
    *) die 'binary directory must be absolute' ;;
  esac
  [ "$1" != '/' ] || die 'binary directory is too broad'
}

require_safe_directory() {
  target=$1
  if [ -L "$target" ]; then
    die "directory may not be a symbolic link: $target"
  fi
  if [ -e "$target" ] && [ ! -d "$target" ]; then
    die "path is not a directory: $target"
  fi
  /bin/mkdir -p "$target"
  /bin/chmod 700 "$target"
}

expected_archive_sha256() {
  checksum_file=$1
  asset_name=$2
  [ "$(/usr/bin/wc -l < "$checksum_file" | /usr/bin/tr -d ' ')" = '1' ] \
    || die 'checksum file must contain exactly one line'
  checksum_line=$(/usr/bin/sed -n '1p' "$checksum_file")
  printf '%s\n' "$checksum_line" \
    | /usr/bin/grep -Eq "^[0-9a-f]{64}  ${asset_name}$" \
    || die 'checksum file has an invalid shape'
  printf '%s\n' "$checksum_line" | /usr/bin/awk '{print $1}'
}

validate_archive_listing() {
  archive=$1
  package_name=$2
  listing=$3
  verbose_listing=$4

  /usr/bin/tar -tzf "$archive" > "$listing" \
    || die 'release archive cannot be listed'
  /usr/bin/tar -tvzf "$archive" > "$verbose_listing" \
    || die 'release archive types cannot be inspected'

  entry_count=$(/usr/bin/wc -l < "$listing" | /usr/bin/tr -d ' ')
  [ "$entry_count" -ge 3 ] && [ "$entry_count" -le 20 ] \
    || die 'release archive file count is outside the admitted range'
  unique_entry_count=$(/usr/bin/sort -u "$listing" | /usr/bin/wc -l | /usr/bin/tr -d ' ')
  [ "$entry_count" = "$unique_entry_count" ] \
    || die 'release archive contains duplicate paths'

  while IFS= read -r entry; do
    case "$entry" in
      "$package_name"/) ;;
      "$package_name"/*)
        leaf=${entry#"$package_name"/}
        printf '%s\n' "$leaf" \
          | /usr/bin/grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' \
          || die 'release archive contains an unsafe path'
        ;;
      *) die 'release archive escapes its single package root' ;;
    esac
  done < "$listing"

  /usr/bin/grep -Fxq "$package_name/longarc-core" "$listing" \
    || die 'release archive is missing the CLI core'
  /usr/bin/grep -Fxq "$package_name/longarc-memory-runtime" "$listing" \
    || die 'release archive is missing the Memory Lane runtime'
  /usr/bin/grep -Fxq "$package_name/longarc-release-manifest.json" "$listing" \
    || die 'release archive is missing its manifest'
  [ "$(/usr/bin/grep -Fxc "$package_name/" "$listing")" = '1' ] \
    || die 'release archive must contain exactly one package root entry'

  while IFS= read -r verbose_entry; do
    entry_type=$(printf '%s' "$verbose_entry" | /usr/bin/cut -c 1)
    case "$entry_type" in
      d|-) ;;
      *) die 'release archive contains a link or special file' ;;
    esac
  done < "$verbose_listing"
}

manifest_value() {
  manifest=$1
  key=$2
  /usr/bin/plutil -extract "$key" raw -o - "$manifest" 2>/dev/null \
    || die "release manifest field is unavailable: $key"
}

verify_release_directory() {
  release_root=$1
  version=$2
  manifest="$release_root/longarc-release-manifest.json"
  core="$release_root/longarc-core"
  runtime="$release_root/longarc-memory-runtime"

  for required_file in "$manifest" "$core" "$runtime"; do
    [ -f "$required_file" ] && [ ! -L "$required_file" ] \
      || die 'release contains a missing, linked, or non-regular required file'
  done

  [ "$(manifest_value "$manifest" version)" = "$version" ] \
    || die 'release manifest version does not match the requested tag'
  [ "$(manifest_value "$manifest" platform)" = 'darwin' ] \
    || die 'release manifest platform is not admitted'
  [ "$(manifest_value "$manifest" arch)" = 'arm64' ] \
    || die 'release manifest architecture is not admitted'
  [ "$(manifest_value "$manifest" signing)" = 'developer_id' ] \
    || die 'release is not Developer ID signed'
  [ "$(manifest_value "$manifest" notarization)" = 'accepted' ] \
    || die 'release is not Apple-notarized'
  [ "$(manifest_value "$manifest" claimCeiling)" = 'signed_notarized_external_prerelease' ] \
    || die 'release claim ceiling is not external prerelease'

  [ "$(manifest_value "$manifest" boundaries.repositorySourceFilesIncluded)" = 'false' ] \
    || die 'release source boundary is invalid'
  [ "$(manifest_value "$manifest" boundaries.memoryLocalFirst)" = 'true' ] \
    || die 'release memory boundary is invalid'
  [ "$(manifest_value "$manifest" boundaries.studioSilentMemoryAccess)" = 'false' ] \
    || die 'release studio-access boundary is invalid'
  [ "$(manifest_value "$manifest" boundaries.rawTranscriptRecorded)" = 'false' ] \
    || die 'release transcript boundary is invalid'
  [ "$(manifest_value "$manifest" boundaries.hiddenReasoningRecorded)" = 'false' ] \
    || die 'release reasoning boundary is invalid'
  [ "$(manifest_value "$manifest" boundaries.modelMayCommitMemory)" = 'false' ] \
    || die 'release consent boundary is invalid'

  /usr/bin/codesign --verify --strict --verbose=2 "$core" >/dev/null 2>&1 \
    || die 'CLI core signature verification failed'
  /usr/bin/codesign --verify --strict --verbose=2 "$runtime" >/dev/null 2>&1 \
    || die 'Memory Lane runtime signature verification failed'
  /usr/sbin/spctl --assess --type execute --verbose=2 "$core" >/dev/null 2>&1 \
    || die 'CLI core failed Apple assessment'
  /usr/sbin/spctl --assess --type execute --verbose=2 "$runtime" >/dev/null 2>&1 \
    || die 'Memory Lane runtime failed Apple assessment'

  verification=$($core verify 2>/dev/null) \
    || die 'compiled release integrity verification failed'
  printf '%s\n' "$verification" | /usr/bin/grep -Fq '"verification":"passed"' \
    || die 'compiled release did not report passed verification'
  printf '%s\n' "$verification" | /usr/bin/grep -Fq '"signing":"developer_id"' \
    || die 'compiled release did not confirm Developer ID signing'
  printf '%s\n' "$verification" | /usr/bin/grep -Fq '"notarization":"accepted"' \
    || die 'compiled release did not confirm notarization'
  printf '%s\n' "$verification" | /usr/bin/grep -Fq '"sourceBound":true' \
    || die 'compiled release is not bound to immutable source commits'
}

require_codex() {
  codex_path=$(command -v codex 2>/dev/null || true)
  [ -n "$codex_path" ] || die "Codex CLI is required: $required_codex_version"
  observed_version=$($codex_path --version 2>/dev/null | /usr/bin/tail -n 1)
  [ "$observed_version" = "$required_codex_version" ] \
    || die "Codex CLI version mismatch: expected $required_codex_version"
}

update_current_link() {
  install_root=$1
  version=$2
  link_path="$install_root/current"
  if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
    die 'current release pointer is not a symbolic link'
  fi
  temporary_link="$install_root/.current.$$"
  [ ! -e "$temporary_link" ] && [ ! -L "$temporary_link" ] \
    || die 'temporary release pointer already exists'
  /bin/ln -s "releases/$version" "$temporary_link"
  /bin/mv -f "$temporary_link" "$link_path"
}

update_binary_link() {
  install_root=$1
  bin_dir=$2
  link_path="$bin_dir/longarc"
  expected_target="$install_root/current/longarc-core"
  if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
    die 'longarc command already exists and is not owned by this installer'
  fi
  if [ -L "$link_path" ]; then
    existing_target=$(/usr/bin/readlink "$link_path")
    case "$existing_target" in
      "$install_root"/*) ;;
      *) die 'existing longarc link is not owned by this installer' ;;
    esac
  fi
  temporary_link="$bin_dir/.longarc.$$"
  [ ! -e "$temporary_link" ] && [ ! -L "$temporary_link" ] \
    || die 'temporary command link already exists'
  /bin/ln -s "$expected_target" "$temporary_link"
  /bin/mv -f "$temporary_link" "$link_path"
}

main() {
  [ "$#" -eq 1 ] || die 'usage: install.sh v0.1.0-alpha.1'
  version=$1
  validate_version "$version"

  [ "$(/usr/bin/uname -s)" = 'Darwin' ] \
    || die 'the first Long Arc prerelease supports macOS only'
  [ "$(/usr/bin/uname -m)" = 'arm64' ] \
    || die 'the first Long Arc prerelease supports Apple silicon only'
  [ "$(/usr/bin/id -u)" -ne 0 ] || die 'do not run this installer with sudo'

  require_command /usr/bin/curl
  require_command /usr/bin/tar
  require_command /usr/bin/shasum
  require_command /usr/bin/plutil
  require_command /usr/bin/codesign
  require_command /usr/sbin/spctl
  require_codex

  : "${HOME:?HOME is required}"
  install_root=${LONGARC_INSTALL_ROOT:-"$HOME/.local/share/longarc"}
  bin_dir=${LONGARC_BIN_DIR:-"$HOME/.local/bin"}
  validate_install_root "$install_root"
  validate_bin_dir "$bin_dir"
  require_safe_directory "$install_root"
  require_safe_directory "$install_root/releases"
  require_safe_directory "$bin_dir"

  package_name="longarc-${version}-darwin-arm64"
  asset_name="${package_name}.tar.gz"
  checksum_name="${asset_name}.sha256"
  release_url="https://github.com/${repository}/releases/download/${version}"

  download_root=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/longarc-download.XXXXXX")
  archive="$download_root/$asset_name"
  checksum="$download_root/$checksum_name"
  listing="$download_root/archive.list"
  verbose_listing="$download_root/archive.verbose"

  /usr/bin/curl --proto '=https' --tlsv1.2 -fL --retry 3 \
    -o "$archive" "$release_url/$asset_name" \
    || die 'release archive download failed'
  /usr/bin/curl --proto '=https' --tlsv1.2 -fL --retry 3 \
    -o "$checksum" "$release_url/$checksum_name" \
    || die 'release checksum download failed'

  expected_sha=$(expected_archive_sha256 "$checksum" "$asset_name")
  observed_sha=$(/usr/bin/shasum -a 256 "$archive" | /usr/bin/awk '{print $1}')
  [ "$observed_sha" = "$expected_sha" ] || die 'release checksum mismatch'
  validate_archive_listing "$archive" "$package_name" "$listing" "$verbose_listing"

  release_target="$install_root/releases/$version"
  if [ -e "$release_target" ] || [ -L "$release_target" ]; then
    [ -d "$release_target" ] && [ ! -L "$release_target" ] \
      || die 'existing release target is unsafe'
    verify_release_directory "$release_target" "$version"
  else
    stage_root=$(/usr/bin/mktemp -d "$install_root/.stage.XXXXXX")
    /usr/bin/tar -xzf "$archive" -C "$stage_root" \
      || die 'release extraction failed'
    extracted="$stage_root/$package_name"
    [ -d "$extracted" ] && [ ! -L "$extracted" ] \
      || die 'release extraction root is invalid'
    verify_release_directory "$extracted" "$version"
    /bin/mv "$extracted" "$release_target"
    /bin/rmdir "$stage_root"
    stage_root=''
  fi

  update_current_link "$install_root" "$version"
  update_binary_link "$install_root" "$bin_dir"
  "$bin_dir/longarc" verify >/dev/null \
    || die 'installed command failed final verification'

  printf '%s\n' "Long Arc $version installed and verified."
  printf '%s\n' "Run: $bin_dir/longarc init"
  case ":${PATH}:" in
    *":$bin_dir:"*) ;;
    *) printf '%s\n' "Add $bin_dir to PATH to invoke longarc directly." ;;
  esac
}

if [ "${LONGARC_INSTALL_LIBRARY_ONLY:-0}" != '1' ]; then
  main "$@"
fi
