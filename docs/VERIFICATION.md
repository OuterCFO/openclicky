# Verification status

## Evidence from the development setup

The modified application built successfully in Xcode 27 on Apple Silicon with macOS 26 or later.
The most recent adaptive prompt/history build completed at 15:58 on 6 October 2026 and the installed app passed deep strict code-signature verification.
Prior builds exercised ChatGPT sign-in, real image attachment, session continuity, pointer placement, and manual reply dismissal.

The newest multiline editor and unified history panel require further live user acceptance testing.
Compilation is not proof that dictation, layout, pointer placement, or cross-app behavior is correct.
Repository preparation adds fresh-install defaults, portable signing configuration, and reproducible runtime setup.
The publication source built in Xcode at 16:22 on 6 October 2026.
The pinned ARM64 runtime archive passed integrity verification, extraction, and a version check.
Python contract tests rejected a tampered archive without overwriting an existing runtime.
Swift parsing and provider, direct-answer routing, pointer placement, and manual dismissal contract checks passed.
Publication hygiene checks passed for the staged snapshot, including exclusion of local signing and runtime files.
These are self-review checks, not independent review or a fresh-user live acceptance test.

## Checks a contributor should run

- Run `scripts/run-source-checks.sh` for parsing, portable contract tests, and publication hygiene.
- Run `python3 scripts/prepare-codex-runtime.py` and verify both named binaries are present.
- Build the final source in Xcode with your local signing configuration.
- Perform the first-use checklist in [SETUP.md](SETUP.md) on a harmless public page.
- Check long dictation, history, follow-ups, manual dismissal, and display edge placement.

Intel hardware, alternate LLM providers, independent fresh-user setup, and notarized distribution are not yet certified.
No screenshots or transcripts from the maintainer's personal desktop are published as test fixtures.
