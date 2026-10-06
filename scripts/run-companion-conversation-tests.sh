#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
python3 - "$ROOT" "$OUT" <<'PYTEST'
from pathlib import Path
import sys
s=(Path(sys.argv[1])/'cursor-buddy/CodexAgentSession.swift').read_text()
a=s.index('struct CodexTranscriptEntry:')
b=s.index('struct CodexAgentScreenContextAttachment:', a)
(Path(sys.argv[2])/'Transcript.swift').write_text('import Foundation\n'+s[a:b])
PYTEST
cat > "$OUT/main.swift" <<'SWIFT'
import Foundation
let defaults = UserDefaults(suiteName: "openclicky-tests-" + UUID().uuidString)!
let first = CodexTranscriptEntry(role: .user, text: "Keep the first task context")
var store = CompanionConversationStore(legacyEntries: [first], summary: "first summary")
let firstID = store.activeID
store.startNew()
let secondID = store.activeID
precondition(firstID != secondID && store.active.entries.isEmpty && store.active.summary == nil)
store.update(entries: [CodexTranscriptEntry(role: .assistant, text: "Second task only")], summary: "second summary")
store.save(to: defaults)
store = CompanionConversationStore.load(from: defaults)
precondition(store.activeID == secondID && store.active.entries.first?.text == "Second task only")
precondition(store.select(firstID) && store.active.entries == [first] && store.active.summary == "first summary")
store.removeActive()
precondition(store.activeID == secondID && !store.select(firstID))
precondition(store.conversations.first(where: { $0.id == firstID })?.entries == [first])
store.removeActive()
precondition(store.active.entries.isEmpty && store.activeID != secondID)
store.save(to: defaults)
precondition(CompanionConversationStore.load(from: defaults).activeID == store.activeID)
defaults.set(Data("invalid".utf8), forKey: CompanionConversationStore.defaultsKey)
precondition(CompanionConversationStore.load(from: defaults, legacyEntries: [first]).active.entries == [first])
print("PASS: independent tasks, selection, persistence, archive, final-task removal, and legacy fallback")
SWIFT
swiftc "$OUT/Transcript.swift" "$ROOT/cursor-buddy/CompanionConversationStore.swift" "$OUT/main.swift" -o "$OUT/check"
"$OUT/check"
