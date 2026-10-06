# OpenClicky

**A screen-aware AI companion for your Mac.**
Ask about what you are working on, get an answer beside an AI pointer, and keep using your app.
Use it for navigation, troubleshooting, learning software, understanding unfamiliar interfaces, and ongoing computer work.

This public fork of [Jason Kneen's OpenClicky](https://github.com/jasonkneen/openclicky) adds a compact, no-notch workflow with Wispr Flow dictation and ChatGPT-backed Codex sessions.
It is independent of the commercial Clicky product and of OpenAI.

## What this fork changes

- **Command + Option** opens a focused input and starts Wispr Flow.
- Multiline prompts wrap and grow; longer drafts scroll.
- A task's menu bar icon opens its conversation history in the same panel.
- Follow-ups stay with the selected session; separate tasks have separate transcripts.
- Answers appear beside the moving AI pointer, with optional screen highlights.
- **Escape or ×** dismisses answers and highlights without deleting history.
- No persistent fake-notch pill or side cursor dock.
- The default response model is `gpt-6-luna` with medium reasoning effort through Codex, playback is muted, and idle observation is off.

The interface runs locally; AI inference on the default route runs remotely through your ChatGPT-backed Codex account.
No local LLM is required.
The code is free under the MIT license, but provider access, subscription limits, and Wispr's own service terms still apply.

## Planned work

[Bidirectional session connection](docs/ROADMAP.md): connect an active Codex session with its Cursor Task Manager conversation, preserving context and progress in both directions.
This connection is not implemented yet.

## Get started

This is a **source distribution**, not a notarized one-click installer.
The current project targets **macOS 26 or later** and was built with **Xcode 27** on Apple Silicon.
The runtime preparation script also supports Intel macOS archives; that hardware has not been validated for this fork.

```sh
git clone https://github.com/OuterCFO/openclicky.git
cd openclicky
python3 scripts/prepare-codex-runtime.py
cp Config/Local.xcconfig.example Config/Local.xcconfig
open cursor-buddy.xcodeproj
```

1. Put your own Apple development team ID in `Config/Local.xcconfig`.
2. In Xcode, choose the `cursor-buddy` scheme and **My Mac**, then build.
3. Copy the signed `OpenClicky.app` build product to `/Applications` and launch that copy.
4. Sign in to Codex with your own ChatGPT account, or let OpenClicky's sign-in flow complete.
5. Grant Screen Recording and Accessibility to the installed OpenClicky app.
6. Install and sign in to [Wispr Flow](https://wisprflow.ai/) if you want the dictation shortcut.

See [the complete setup guide](docs/SETUP.md), including sign-in, permissions, signing, and a first-use checklist.
You can type instead of using Wispr.

## Everyday use

| Action | Result |
| --- | --- |
| Press and release Command + Option | Open input and start Wispr dictation |
| Return or Send | Submit and close the input |
| Shift + Return | Insert a newline |
| History or a task menu bar icon | Review that conversation in the compact panel |
| Escape or × | Close the input, or dismiss the current answer and highlights |
| Tools → New OpenAI Task | Start a separate task with its own session |

Try: “Explain this page and point at the settings button.”
For a separate task, use the explicit new-task command rather than expecting every screen question to become background work.

## How it works

Your prompt + requested screen snapshots + the current session's recent exchanges + OpenClicky's local instructions/memory are sent to the selected backend.
OpenClicky renders the returned answer and pointing/highlight instructions on your desktop.

**Sharing your ChatGPT login does not import your other ChatGPT or Codex chats.**
OpenClicky has its own context and sessions.
Its account, provider, context, and execution boundaries are explained in [the architecture guide](docs/ARCHITECTURE.md).
An [interactive visual explainer](docs/interactive/OpenClicky-explained.html) is included; download it and open it locally.
That explainer describes the inspected development setup, not every future user's configuration.

The app includes OpenAI/Codex, Claude, Apple, and other upstream adapters.
This fork's verified setup uses ChatGPT-backed Codex.
Other providers need their own access and are not covered by a ChatGPT subscription.
Screen guidance requires a backend capable of understanding the supplied images.

## Privacy and authority

Screen content and prompts are sent to the selected model service.
Wispr handles dictation separately.
Local conversation, memory, logs, and screenshot files can contain private information.
Explicit agent tasks can have broader tool access than the screen-answer path.
Read [SECURITY.md](SECURITY.md) before enabling optional automation or exposing the local control bridge.
No personal credentials, history, screen captures, or development runtime binaries belong in this repository.

## Development and project structure

| Location | Purpose |
| --- | --- |
| `cursor-buddy/` | Native macOS application |
| `Packages/` | Local Swift modules |
| `cursor-buddyTests/` | App regression tests |
| `AppResources/OpenClicky/` | Bundled instructions, skills, and upstream resources |
| `scripts/prepare-codex-runtime.py` | Download and verify the pinned official Codex runtime |
| `scripts/run-source-checks.sh` | Non-invasive source and regression checks |
| `Config/` | Shared configuration and ignored local signing overrides |
| `docs/` | Setup, architecture, troubleshooting, and project evidence |

```sh
scripts/run-source-checks.sh
```

Build and run the native application in Xcode.
See [CONTRIBUTING.md](CONTRIBUTING.md) for checks and review requirements.
The repository retains the legacy `cursor-buddy` target/folder names for compatibility.

## Status and attribution

The app has compiled and run in the maintainer's setup.
The newest adaptive prompt/history UI still requires live user acceptance testing; successful compilation is not a visual sign-off.
Provider alternatives, Intel hardware, and a fresh independent user's full setup have not yet been certified.
Known limitations and test steps are recorded in [docs/VERIFICATION.md](docs/VERIFICATION.md).

Original OpenClicky is by **Jason Kneen**, under the [MIT license](LICENSE).
This fork is maintained by **OuterCFO**.
Third-party components retain their own licenses; see [NOTICE.md](NOTICE.md).
