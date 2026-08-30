# Long Arc privacy boundary

Long Arc memory is local-first and user-owned.

## What initialization does

`longarc init` creates a new, empty Memory Lane vault on the user's Mac. Its encryption key is generated per user and protected by macOS Keychain. Long Arc Studios does not receive a recovery key, master key, or silent administrative capability.

## What a memory-enabled turn exposes

Before a turn, the local runtime returns a bounded projection of user-committed records that fit the turn's capability and record budget. The Harness may send that projection to the configured model provider as context. This is model-provider egress and requires the user's decision to run the turn; it is not sent to Long Arc Studios.

The entire vault is never handed to the model. Pending proposals, encryption keys, raw vault files, and omitted records are not part of the projection.

## What can become memory

After a completed turn, a model may propose a compact delta. It cannot accept or commit its own proposal. The user must accept, edit, or reject it.

Reasoning-pattern records are structured, evidence-bound lessons: trigger, failed assumption, breaker evidence, corrected rule, and evidence references. They are not private chain-of-thought, and they remain candidates until the required replay and disposition rules are satisfied.

Trigger Words such as ROAM, REASON, REFLECT, SWEEP, and DELTA are stored only as recognized protocol obligations. A Trigger Word defines work that is required; it never proves that work happened.

## What receipts contain

Local receipts contain hashes, classifications, consent status, bounded counts, and outcomes. They do not contain raw prompts, raw responses, credentials, encryption keys, or hidden model reasoning.

## User controls

The CLI provides local status, review, accept, edit, reject, recall, forget, export, and reset operations. Reset and uninstall do not require contact with Long Arc Studios.

Plaintext export is explicit and requires confirmation. Treat an exported file as sensitive user data.

## Support

Long Arc Studios has no standing access to a user's Memory Lane. Support access should use a diagnostic export created and reviewed by the user. Do not send a raw vault or Keychain material.

## Telemetry claim

The first prerelease does not add Long Arc telemetry. The configured model provider and the Codex CLI have their own data practices and account settings; review those separately before use.
