import Foundation

nonisolated enum SharedCodexSessionContract {
    static func isLive(_ status: String) -> Bool { status == "idle" || status == "active" }
    static func turnParameters(threadID: String, input: [[String: Any]]) -> [String: Any] {
        // Session settings belong to the original Codex client.
        ["threadId": threadID, "input": input]
    }
}
