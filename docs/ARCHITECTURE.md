# Distribution architecture

Long Arc uses an open inspection surface around a closed implementation core.

```text
public Longarc-CLI repository
  installer + uninstaller + privacy/security documentation
                    |
                    | exact tag, checksum, signature, notarization
                    v
proprietary longarc-core process
  governed Harness + Codex app-server adapter + consent controls
                    |
                    | authenticated local process boundary
                    v
proprietary longarc-memory-runtime
  encrypted vault + capability broker + checkpoint chain
                    |
                    v
macOS Keychain and user-owned local files
```

The release contains compiled implementation. It does not contain the private Git repositories or repository source files. Compilation, symbol stripping, and obfuscation create friction, not perfect secrecy; determined reverse engineering cannot be eliminated.

Memory Lane remains part of the Long Arc product rather than a publicly reusable internal primitive. Each installation has separate user, lane, vault, and key roots. There is no studio master key.

The Rust sidecar owns memory mutation and enforces one writer, authenticated capabilities, bounded projections, entry/work/exit checkpoints, delta disposition, trigger obligations, reasoning-pattern candidate rules, tamper rejection, and local reset. The Harness owns the user interaction and model-provider boundary. The model cannot call the vault directly or promote a proposal.

If Long Arc later moves any memory algorithm server-side, that is a new privacy and availability architecture and requires a separate decision. It is not part of the first prerelease.
