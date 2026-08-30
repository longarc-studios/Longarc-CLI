# External prerelease runbook

This runbook is for Long Arc maintainers. It does not authorize a release; every gate must already be approved.

## Alpha 1 source identity

- Harness source commit: `910d5119d72df022062a1b57d21584fe44c62324`
- Memory Lane source commit: `7af1c29bb2d4622ce4eef29ffa632792842b4fdb`
- Reproducible unsigned-candidate archive SHA-256: `4d2aa8b974caa346211eaedb1faf902533d1ffe21e6525153e69441747f10cfd`

The unsigned hash is local reproducibility evidence only. Developer ID signing changes the final archive bytes, so it is not the checksum to publish.

## 1. Qualify clean private sources

Check out the two exact commits in separate clean worktrees. Do not build from a dirty branch.

In Memory Lane:

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/memory_lane/runtime_contracts.py
python3 scripts/memory_lane/verify_private_surface.py
cargo fmt --manifest-path runtime/Cargo.toml --all -- --check
cargo test --manifest-path runtime/Cargo.toml --release --locked
cargo clippy --manifest-path runtime/Cargo.toml --release --locked --all-targets -- -D warnings
node runtime/scripts/build-release.mjs
```

In the Harness:

```sh
npm ci --ignore-scripts
npm run typecheck
npm test
npm run verify:boundaries
npm run verify:hygiene
node scripts/verify-cli-v0-boundary.mjs
node scripts/verify-codex-app-server-0.147.0-compatibility.mjs --live
```

Run the Node-to-Rust integration verifier with an isolated test vault, exact runtime digest, and explicit export path. It must finish with reset `true` and leave no test Keychain item.

## 2. Establish Apple release authority

The release Mac must have:

- an unexpired `Developer ID Application` identity owned by Long Arc Studios;
- a `notarytool` Keychain profile authorized for the same Apple team;
- human confirmation that the identity and profile are release credentials, not personal or development credentials.

Verify before building:

```sh
security find-identity -v -p codesigning
xcrun notarytool history --keychain-profile longarc-notary --output-format json
```

Never put the certificate, private key, Apple password, or notarization credential in this repository or a command transcript.

## 3. Build the signed archive

From the clean Harness commit, supply the clean Memory Lane runtime and notice paths:

```sh
LONGARC_CODESIGN_IDENTITY='Developer ID Application: Long Arc Studios (TEAM_ID)' \
LONGARC_NOTARY_PROFILE='longarc-notary' \
node scripts/package-closed-core.mjs \
  --memory-runtime /absolute/private/memory-lane/runtime/target/release/longarc-memory-runtime \
  --memory-notices /absolute/private/memory-lane/runtime/THIRD_PARTY_NOTICES.md \
  --out /absolute/private/release-output \
  --version v0.1.0-alpha.1
```

The build must report `signed_notarized_external_prerelease_candidate`. Verify both executables with `codesign` and `spctl`, run `longarc-core verify`, inspect the manifest source commits, and repeat the source-leak scan. The final `.sha256` file produced by this build is the checksum to publish.

## 4. Publish the public source commit

Authenticate GitHub CLI as an account with write access to `longarc-studios/Longarc-CLI`, verify the repository is public, and push `main`. Do not use an unrelated personal SSH identity.

Provider readback must confirm the exact commit, visibility, default branch, workflow, and absence of private source or release assets before tagging.

## 5. Create the prerelease

Only after legal approval and signed artifact verification:

```sh
gh release create v0.1.0-alpha.1 \
  --repo longarc-studios/Longarc-CLI \
  --target main \
  --prerelease \
  --title 'Long Arc v0.1.0-alpha.1' \
  --notes-file /absolute/private/release-notes.md \
  /absolute/private/release-output/longarc-v0.1.0-alpha.1-darwin-arm64.tar.gz \
  /absolute/private/release-output/longarc-v0.1.0-alpha.1-darwin-arm64.tar.gz.sha256
```

Read the release back with GitHub CLI and compare both uploaded asset digests. A command returning success is not sufficient provider evidence.

## 6. Clean-machine and first-user qualification

Use a clean Apple silicon Mac with no organization or private repository access. Install through the public tagged `install.sh`, initialize an empty lane, run the two-session consent flow in [FIRST_USER_ACCEPTANCE.md](FIRST_USER_ACCEPTANCE.md), then test default uninstall and explicit reset.

Jeff is the first qualified external regular user only after that second session succeeds with his explicit memory-projection egress decision. Before then, the release remains a prerelease candidate.
