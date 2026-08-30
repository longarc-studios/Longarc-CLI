# Security policy

## Supported release

Only assets attached to this repository's GitHub Releases page and accepted by `install.sh` are supported. The first target is Apple silicon macOS.

Never disable Gatekeeper, remove quarantine attributes, bypass checksum verification, or install an ad hoc signed candidate as an official release.

## Report a vulnerability

Do not open a public issue containing credentials, private memory, vault files, diagnostic exports, or exploit details. Use GitHub's private vulnerability reporting for this repository once enabled by the maintainers.

Until that provider control is visibly enabled, do not transmit sensitive material. Open a minimal public issue that asks the maintainers for a private reporting channel without including the vulnerability details.

## Release trust chain

The installer requires:

1. HTTPS download from this repository's exact release tag.
2. An exact SHA-256 checksum file.
3. A flat, single-root archive with no links or special files.
4. Developer ID signatures on the CLI core and Memory Lane runtime.
5. Successful Apple security assessment.
6. A signed/notarized external-prerelease claim in the release manifest.
7. Runtime verification of every packaged file hash and executable bit.

The private source repositories, signing credentials, notarization credentials, and encryption keys must never be placed in this public repository or its release assets.
