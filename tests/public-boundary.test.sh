#!/bin/sh

set -eu

test_root=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/longarc-public-test.XXXXXX")
cleanup() {
  /bin/rm -rf "$test_root"
}
trap cleanup EXIT HUP INT TERM

LONGARC_INSTALL_LIBRARY_ONLY=1
export LONGARC_INSTALL_LIBRARY_ONLY
. "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/install.sh"

validate_version 'v0.1.0-alpha.1'
if (validate_version 'latest') >/dev/null 2>&1; then
  printf '%s\n' 'FAIL: mutable release label was accepted' >&2
  exit 1
fi
if (validate_install_root '/') >/dev/null 2>&1; then
  printf '%s\n' 'FAIL: broad install root was accepted' >&2
  exit 1
fi
validate_install_root "$test_root/share/longarc"
validate_bin_dir "$test_root/bin"

package='longarc-v0.1.0-alpha.1-darwin-arm64'
safe_source="$test_root/safe/$package"
/bin/mkdir -p "$safe_source"
/usr/bin/touch "$safe_source/longarc-core"
/usr/bin/touch "$safe_source/longarc-memory-runtime"
/usr/bin/touch "$safe_source/longarc-release-manifest.json"
safe_archive="$test_root/safe.tar.gz"
COPYFILE_DISABLE=1 /usr/bin/tar -czf "$safe_archive" -C "$test_root/safe" "$package"
validate_archive_listing \
  "$safe_archive" \
  "$package" \
  "$test_root/safe.list" \
  "$test_root/safe.verbose"

unsafe_source="$test_root/unsafe/$package"
/bin/mkdir -p "$unsafe_source"
/bin/ln -s /tmp "$unsafe_source/longarc-core"
/usr/bin/touch "$unsafe_source/longarc-memory-runtime"
/usr/bin/touch "$unsafe_source/longarc-release-manifest.json"
unsafe_archive="$test_root/unsafe.tar.gz"
COPYFILE_DISABLE=1 /usr/bin/tar -czf "$unsafe_archive" -C "$test_root/unsafe" "$package"
if (validate_archive_listing \
  "$unsafe_archive" \
  "$package" \
  "$test_root/unsafe.list" \
  "$test_root/unsafe.verbose") >/dev/null 2>&1; then
  printf '%s\n' 'FAIL: linked archive entry was accepted' >&2
  exit 1
fi

asset='longarc-v0.1.0-alpha.1-darwin-arm64.tar.gz'
checksum='0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
printf '%s  %s\n' "$checksum" "$asset" > "$test_root/valid.sha256"
[ "$(expected_archive_sha256 "$test_root/valid.sha256" "$asset")" = "$checksum" ]
printf '%s  %s\nextra\n' "$checksum" "$asset" > "$test_root/invalid.sha256"
if (expected_archive_sha256 "$test_root/invalid.sha256" "$asset") >/dev/null 2>&1; then
  printf '%s\n' 'FAIL: multi-line checksum was accepted' >&2
  exit 1
fi

uninstall_root="$test_root/uninstall/share/longarc"
uninstall_bin="$test_root/uninstall/bin"
/bin/mkdir -p "$uninstall_root/current" "$uninstall_bin"
/usr/bin/touch "$uninstall_root/current/longarc-core"
/bin/ln -s "$uninstall_root/current/longarc-core" "$uninstall_bin/longarc"
LONGARC_INSTALL_ROOT="$uninstall_root" LONGARC_BIN_DIR="$uninstall_bin" \
  /bin/sh "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/uninstall.sh" \
  >/dev/null
[ ! -e "$uninstall_root" ] && [ ! -L "$uninstall_bin/longarc" ]

conflict_root="$test_root/conflict/share/longarc"
conflict_bin="$test_root/conflict/bin"
/bin/mkdir -p "$conflict_root" "$conflict_bin"
/usr/bin/touch "$conflict_bin/longarc"
if LONGARC_INSTALL_ROOT="$conflict_root" LONGARC_BIN_DIR="$conflict_bin" \
  /bin/sh "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/uninstall.sh" \
  >/dev/null 2>&1; then
  printf '%s\n' 'FAIL: uninstaller removed around an unowned command' >&2
  exit 1
fi
[ -d "$conflict_root" ] && [ -f "$conflict_bin/longarc" ]

/usr/bin/grep -Fq "repository='longarc-studios/Longarc-CLI'" \
  "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/install.sh"
if /usr/bin/grep -Eq 'bypass|disable.*Gatekeeper|xattr[[:space:]]+-d' \
  "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/install.sh"; then
  printf '%s\n' 'FAIL: installer contains a security bypass path' >&2
  exit 1
fi

printf '%s\n' 'PASS: public installer boundary tests'
