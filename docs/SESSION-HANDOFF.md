# Session handoff: read this first

OpenClicky is a general screen-aware Mac companion, not a tutor-only tool.
Its interface runs locally and its default inference uses Codex with ChatGPT sign-in.
Shared authentication does not import the active Codex chat, ChatGPT chats, or other cursor conversations.
Bidirectional automatic session sync is planned, not implemented.

## Current controls

Command + Option opens the compact input, focuses it, and invokes external Wispr Flow dictation.
Return submits and hides input; Shift + Return inserts a newline.
The AI pointer shows the answer beside the relevant screen area.
Escape or × dismisses the reply and highlights without deleting history.
A task’s menu bar icon opens its history in the same compact panel.
Select the intended task before continuing; do not assume a different task has its context.
Saved companion history survives restart, but the selected explicit task is held in memory and must be reselected after restart.
There is no persistent notch or side dock and no separate Workflow Coach chat window.
These are implemented behaviors; live visual acceptance is user-led.

## Codex → cursor today

When the user says they will use the cursor, prepare one short, self-contained transfer message from the current conversation.
Include the objective, current state, decisions and constraints, what is on screen if actually known, next action, and a unique checkpoint label.
Include only relevant context the user wants carried to this tool; omit credentials and unrelated private history.
Save a local handoff file when useful, but do not claim that writing a file transfers it into OpenClicky.
Give the user the message to paste into the selected cursor task’s compact input and submit.
The normal screen-answer route is read-only; it is not guaranteed to read arbitrary project files.
Do not rely on a file path alone: put the needed facts directly into the message.
Ask the cursor to repeat the checkpoint and objective before continuing, so the user can confirm receipt.
Do not send prompts to other Codex chats without explicit authorization.

## Cursor → Codex today

Ask the cursor for a compact return summary: checkpoint, actions actually performed by the user, observations, decisions, unresolved issues, and next action.
The user copies it from that task’s history into the original Codex chat.
Reconcile the summary with current files and evidence before acting on it.
Do not present cursor claims as verified changes or invent unseen outcomes.
Keep the same task selected for follow-ups; start a new task only when requested.

## Model and limits

New source builds default to GPT-6 Luna (`gpt-6-luna`) and medium effort.
Existing installs preserve saved choices; inspect only model preferences when troubleshooting.
OpenClicky’s model selection is independent of the Codex desktop chat’s model.
Wispr is a separate dictation service.
Other provider adapters exist, but neither arbitrary provider compatibility nor all alternate routes have been verified.
Screenshots and prompts can be sent to the selected remote provider; this is not a local LLM setup.

## Engineering boundaries

Do not redesign controls while fixing a model or context issue.
Use Xcode for builds; never terminal xcodebuild.
The user performs live shortcut, dictation, pointer, and visual tests.
Do not run synthetic demos or inject test conversations into their active task.
See ROADMAP.md only when implementing automatic synchronization.
