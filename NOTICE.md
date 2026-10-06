# Attribution and third-party components

OpenClicky originates from [Jason Kneen's MIT-licensed project](https://github.com/jasonkneen/openclicky).
This repository preserves the original license and Git history.
The source was based on commit `e9eb06a29ff5cd82033d032238f51a936168b05a` before the fork changes.
OuterCFO maintains this fork.

Codex is an [OpenAI open-source project](https://github.com/openai/codex), licensed under Apache-2.0.
The setup script downloads the official `@openai/codex` 0.160.0 platform package rather than committing binaries.
Its license is included in `THIRD_PARTY_LICENSES/Codex-APACHE-2.0.txt` and copied into the generated runtime.

Swift package dependencies and bundled skills retain their respective licenses and attribution.
Review `Package.resolved`, package manifests, and `AppResources/OpenClicky/ATTRIBUTION.md` for inherited components.
Wispr Flow is an independent external product, not included or relicensed by this repository.
This fork is not affiliated with the commercial Clicky product, OpenAI, or Wispr.
