# Troubleshooting

## Shortcut opens input but dictation does not arrive

Confirm Wispr Flow is installed, signed in, and able to dictate into another native text editor.
The shortcut invokes `wispr-flow://start-hands-free`; OpenClicky does not use a Wispr transcription API.
Try typing into the compact editor to distinguish a focus problem from a Wispr problem.
Report the macOS version, final build commit, and whether the insertion caret appears.
Do not send private dictation or account credentials.

## Screen image is unavailable

Enable Screen Recording for the same signed app installed in `/Applications`.
Restart that copy if macOS requests it.
Confirm the runtime preparation step included `codex-code-mode-host`, not just `codex`.
Check that `codex login status` reports a usable account.
A fresh screenshot is requested; visible content may have changed since capture.

## Permission keeps returning

Avoid switching between differently signed build products or different installation locations.
Keep bundle identifiers and signing identity consistent.
If you intentionally change signing identifiers, macOS may treat the build as another application.
Do not reset every application's permissions to fix one app.

## Wrong conversation or incomplete history

Click the desired task's menu bar icon before continuing it.
The standard companion history is bounded to 24 transcript entries.
The history view is refreshed when opened, rather than live-updating while it remains open.
Other ChatGPT and Codex desktop chats are not imported by sign-in.

## Provider or model fails

Check the model selected inside OpenClicky, not just the model selected in another app.
A model must be supported by the configured backend and available to the signed-in account.
An API key can introduce separate usage billing.
Other provider paths are inherited implementations, not all end-to-end validated in this fork.
