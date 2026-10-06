# Security and data boundaries

## What can leave your Mac

The selected model service receives the supplied prompt, screen images, recent context, and included local memory.
The default service is OpenAI through the user's ChatGPT-backed Codex login.
Choosing another backend changes the recipient and applicable service terms.
Wispr Flow handles dictation separately.
This project does not guarantee local-only processing or zero provider retention.

The ordinary screen-answer flow requests snapshots for questions, rather than continuously streaming a movie to the LLM.
Local prewarming and optional upstream observation or automation features exist.
Idle observation defaults to off in this fork.
Review feature settings before enabling background behavior.

## Local data and permissions

Conversation history, memory, logs, screenshot files, and Codex authentication state can contain sensitive information.
They are stored outside the source repository in user application-support or Codex locations.
Do not upload those folders when reporting a bug.
A saved history is not a encrypted vault.
Credentials must never be placed in issue bodies, screenshots, commits, or releases.

Screen Recording allows capture of visible information, including other apps.
Accessibility can permit interface inspection and control.
The screen-answer path's read-only execution policy does not revoke those macOS permissions from the application.
Explicit agent tasks may run tools with workspace-write or full-access policies.
Only launch tasks you trust, and treat web pages and captured text as untrusted input.

The upstream application includes a local control bridge.
Keep it bound to localhost and do not expose it through a tunnel or public network.
Local-only access is not the same as authentication against every process on your machine.
Optional MCP servers and external integrations have separate trust and data boundaries.

## Runtime and updates

The setup script downloads a pinned official Codex package and verifies its SHA-512 integrity before extracting named binaries.
Runtime binaries, signing overrides, authentication files, and build products are ignored by Git.
The fork does not start Sparkle automatic updates; inherited distribution scripts are not a supported release path for this fork.
A source download is not a notarized macOS application release.

## Reporting

Do not publish a working exploit or private data in a public issue.
Use GitHub's private vulnerability reporting when available on this repository.
If unavailable, first open a minimal issue asking for a private reporting channel without disclosing exploit details.
There is no promised security-response SLA for this community fork.
