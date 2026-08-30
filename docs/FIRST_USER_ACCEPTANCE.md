# First regular-user acceptance

Jeff becomes Long Arc's first external regular user only after every release gate and both user sessions below are evidenced. Repository access or an organization invitation does not count.

## Release gates

- [ ] Private Harness and Memory Lane commits are immutable and reviewed.
- [ ] Rust tests, clippy, locked release build, dependency inventory, and source-leak scan pass.
- [ ] Harness tests, current Codex app-server compatibility, schema admission, and runtime manifest checks pass.
- [ ] The release archive is reproducible or its remaining nondeterminism is identified and bounded.
- [ ] Both binaries are Developer ID signed and Apple notarization is accepted.
- [ ] The public repository contains no private source, vault data, keys, credentials, or user identifiers.
- [ ] The founder-approved MIT/public-bootstrap and proprietary/closed-core license notices are present and verified.
- [ ] A public GitHub prerelease and checksum exist on the exact tag.
- [ ] A clean Apple silicon Mac installs without organization access, private repository access, `sudo`, or a Gatekeeper bypass.
- [ ] Uninstall preserves memory by default; explicit reset removes the vault and key without contacting Long Arc.

## Jeff session one

1. Jeff downloads the public installer and verifies the repository and exact release tag.
2. The installer completes all trust checks.
3. `longarc init` reports a fresh, empty lane.
4. Jeff runs one ordinary governed turn containing a durable preference and, if desired, a Trigger Word.
5. `longarc memory review` shows a pending proposal. Committed record count remains zero.
6. Jeff accepts or edits the proposal himself.
7. A local receipt records consent and hashes without raw conversation or hidden reasoning.

## Jeff session two

1. Jeff closes Long Arc and starts a separate process or later session.
2. Jeff reviews the bounded recall projection before provider egress.
3. Jeff explicitly chooses to run a memory-enabled model turn.
4. The model uses the accepted record correctly without receiving the full vault.
5. No pending proposal is silently promoted.
6. Forget, export, and reset controls work locally.

Only after step two completes should the first-user record say: `first external regular user qualified`. Before then, Jeff is an invited prerelease candidate, not a qualified user.
