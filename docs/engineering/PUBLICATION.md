# Public fork delivery contract

## Intended result

A public repository that lets another Mac user reproduce the current screen-aware companion without the maintainer's credentials, private context, runtime installation, or signing identity.
The project is a general computer-use companion; tutoring is one use case.

## Scope

Preserve upstream Git history and MIT attribution.
Publish the modified native source, regression contracts, setup and architecture documentation, pinned runtime downloader, configuration examples, and a local interactive explainer.
Keep the existing remote and add a separate fork push remote.
Do not add an assistant co-author or contributor identity.
Do not include personal history, memory, screenshots, account credentials, or locally generated runtime binaries.

## Acceptance

A fresh source checkout has documented macOS/Xcode requirements and an explicit runtime preparation step.
Runtime downloads are version-pinned and integrity-checked, with the screenshot tool host included.
Signing configuration uses ignored local overrides rather than a committed personal team.
Source checks and relevant regression contracts pass.
The native final source builds in Xcode.
GitHub has the final source and documentation, with CI results reported honestly.
A source-only distribution is labeled as such, and remaining live user acceptance gaps are documented.
