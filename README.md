# Long Arc CLI

Long Arc is a local-first, governed interface for working with Codex while keeping durable user memory under explicit user control.

This public repository is the installation and verification surface. The compiled Harness and Memory Lane runtime are proprietary release artifacts; their private source is not published here. Public does not mean that a private repository, organization invitation, or Long Arc Studios account is required to install a release.

## Promotion status

The first external prerelease is not published yet. The installer intentionally fails closed until a Developer ID signed and Apple-notarized release exists on this repository. Do not work around Gatekeeper or install an unsigned candidate.

No public repository software license is granted yet. Public visibility is an inspection boundary, not an open-source declaration; the license posture and proprietary end-user terms remain held at the documented legal review gate.

The first supported target is Apple silicon macOS. A user also needs the authenticated Codex CLI version named by the release notes. The first build train is pinned to `codex-cli 0.147.0`.

## Official install path

Once the first release is published, download and inspect the installer, then run it with the exact release tag:

```sh
curl --proto '=https' --tlsv1.2 -fSLo longarc-install.sh \
  https://raw.githubusercontent.com/longarc-studios/Longarc-CLI/v0.1.0-alpha.1/install.sh
less longarc-install.sh
/bin/sh longarc-install.sh v0.1.0-alpha.1
```

The installer uses no `sudo`. It installs versioned files under `~/.local/share/longarc` and links `longarc` into `~/.local/bin`.

Then initialize a completely empty private lane:

```sh
longarc init
longarc memory status
```

Initialization creates an encrypted local vault and a per-user key protected by macOS Keychain. It does not seed Long Arc or studio memory.

## Memory consent

For a memory-enabled turn, the Harness may send a bounded projection of user-committed memory to the configured model provider. It does not send the entire vault. After the turn, the model may propose a compact delta, but it cannot commit it.

```sh
longarc memory review
longarc memory accept proposal_ID
longarc memory edit proposal_ID 'Corrected memory text'
longarc memory reject proposal_ID
longarc memory recall
longarc memory forget memory_ID --yes
longarc memory export ./memory-export.json --plaintext --yes
longarc memory reset --yes
```

Review [PRIVACY.md](PRIVACY.md) before using durable memory.

## Uninstall

The default uninstall preserves the encrypted memory vault and local receipts:

```sh
/bin/sh uninstall.sh
```

To reset Memory Lane before removing the app:

```sh
/bin/sh uninstall.sh --reset-memory
```

No uninstall or reset operation contacts Long Arc Studios.

## What is verifiable here

- The exact download URL and release tag are visible.
- The published SHA-256 file is checked before extraction.
- Unsafe archive paths and link entries are rejected.
- Developer ID signing and Apple notarization are required.
- The compiled CLI verifies every packaged file against its release manifest on launch.
- The manifest binds the artifact to clean, immutable Harness and Memory Lane commits.
- The release manifest states the privacy and IP boundaries in machine-readable form.

These checks establish release integrity. They do not make the closed implementation open source or make reverse engineering impossible.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [SECURITY.md](SECURITY.md), [docs/RELEASE_RUNBOOK.md](docs/RELEASE_RUNBOOK.md), and [docs/FIRST_USER_ACCEPTANCE.md](docs/FIRST_USER_ACCEPTANCE.md). The current machine-readable gate state is [promotion-status.json](promotion-status.json).
