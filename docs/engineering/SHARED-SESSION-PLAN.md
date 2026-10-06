# Cursor as a client of an existing Codex conversation

Status: terminal shared-server implementation built; desktop attachment and user live acceptance pending.
Source inspected: 5a8d53c, 6 October 2026.

## Outcome

The cursor is another interface to one existing Codex thread.
Its prompts, screenshots, replies, tool activity, and progress belong to that thread and appear when the user returns to the desktop or terminal client.
Do not create a second conversation and attempt to synchronize summaries.

## Confirmed problem

CodexVoiceSession creates an ephemeral thread in a separate app-server process.
It supplies voice-specific instructions and a read-only policy.
CodexAgentSession also currently creates its own thread.
A context brief cannot give either thread the identity, live state, or client-owned tools of the original session.
The screenshot shows a claimed agent launch without a matching execution.
Execution status must come from actual tool events, never from prose claiming work started.

## Smallest design

Keep the current compact input, Wispr Flow, screenshots, pointer, highlights, and manual dismissal.
Add a Connect to Codex session control to bind a cursor task to an explicit host thread ID and endpoint.
Show the connected conversation title visibly.
Use the existing shared app-server connection through a supported control socket/proxy where available.
Send text and screenshot inputs to that exact thread with turn/start when idle.
Read its transcript and stream its events into the current overlay.
Preserve the host model, effort, working directory, instructions, permissions, tools, and approvals.
Do not apply the separate voice thread’s read-only policy or system prompt to an attached session.
Use a small per-message cursor-rendering hint when needed; do not rewrite the session’s persistent instructions.
Keep source messages and tool events as the history of record; local overlay state is only a presentation cache.

## Invariants

- One connected task maps to one existing thread ID; no fork, copied transcript, or replacement thread.
- If a turn is active, show a waiting state and queue the prompt in the initial version rather than racing a second writer.
- Claim queued, submitted, running, and completed only after the corresponding real acknowledgement or event.
- Preserve original host ownership of client-executed tools and approval requests; prove these still work when input originates from the cursor.
- Keep screenshots available until the host consumes them and map pointer coordinates with explicit display metadata.
- Reconnect using thread and turn/item IDs without duplicating submissions or transcript entries.
- Disconnect removes only the cursor binding; it does not archive, delete, stop, or reset the original Codex chat.
- A failed attachment displays a disconnected error and does not silently create a standalone task.

## Delivery slices

1. Read-only attachment proof.
   Discover the supported daemon endpoint and initialize a client.
   Read the chosen thread ID and observe its real loaded/active state.
   Verify it is owned by the live desktop host rather than merely an old persisted transcript.
   Do not send an inference request yet.
2. One-message round trip.
   Attach a disposable desktop conversation, send one user-approved test prompt from the cursor, and stream its response.
   The user verifies the same exchange in the desktop conversation and confirms prior context remains available.
   Do not continue unless this is the same live thread.
3. Screens and actions.
   Attach a current screenshot to that thread and render the existing pointer/highlight output.
   Verify one harmless file read and one explicitly requested agent action through real tool events.
   Verify host-owned tools and approvals still have a responsible client.
4. Minimal product wiring and terminal verification.
   Persist the explicit binding, expose connected/disconnected state, and reuse Tasks for selection.
   Verify switching back, restart/reconnect, duplicate prevention, busy-thread queueing, and disconnect.
   Prove terminal visibility separately; an independent CLI process sharing a rollout file does not prove live multi-client coordination.

## Evidence and open gate

Official app-server documentation describes Unix-socket transport, thread/read, thread/resume, turn/start, event streaming, and approval/tool requests.
The installed runtime provides app-server proxy.
A managed local Codex daemon is running at version 0.160.1.
The packaged Python Unix WebSocket bridge passed initialization and a read-only live-thread lookup.
The current desktop chat is reported as active by the desktop host and notLoaded by the shared daemon.
The implementation refuses such stored-only copies and offers only threads already loaded in the shared daemon.
The user explicitly chose a terminal-session first version.
No prompts, screenshot inputs, or tool actions were submitted to an existing conversation during this investigation.
Do not restart the user’s daemon or alter authentication/permissions to work around this without resolving the cause.

First next action: user performs the terminal round-trip acceptance test in docs/SHARED-SESSIONS.md.
Desktop-session attachment is the initial target; terminal attachment follows only after a separately verified shared-owner path.

Documentation: https://learn.chatgpt.com/docs/app-server
