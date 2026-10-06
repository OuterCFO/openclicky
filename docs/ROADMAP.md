# OpenClicky roadmap

## Next: bidirectional Codex session connection

Status: shared-server terminal attachment implemented; desktop attachment and user live acceptance remain pending.

The intended design is now a cursor client attached to the same Codex thread, rather than synchronization between separate chats.
See [the pragmatic shared-session plan](engineering/SHARED-SESSION-PLAN.md).

Connect an active Codex session with the corresponding Cursor Task Manager session.
When the user invokes the cursor, it should continue from the Codex session’s latest context and progress.
When the user returns to Codex, that session should receive the questions, answers, observations, and progress produced through the cursor.

### Acceptance criteria

- Explicitly pair a Codex session with a cursor task, keeping unrelated tasks isolated.
- Transfer recent conversation, current objective, consequential decisions, and next action in both directions.
- Preserve the pairing across app restarts and provide an explicit disconnect action.
- Show sync state and failures; prevent duplicate messages and feedback loops.
- Synchronize at safe turn boundaries without interrupting active work.
- Transfer screenshots or sensitive context only within the user’s chosen scope.
- Verify a Codex → cursor → Codex round trip with a unique checkpoint and a real follow-up.

Shared ChatGPT authentication does not currently share conversation context.
Implementation still requires choosing a supported session interface and a conflict policy for simultaneous turns.

## Default model

New builds default to GPT-6 Luna (`gpt-6-luna`) with medium reasoning effort.
Existing saved model choices are preserved; select the model in OpenClicky settings after installing the updated build.
