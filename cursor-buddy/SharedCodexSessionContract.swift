import Foundation

nonisolated enum SharedCodexSessionContract {
    static func isLive(_ status: String) -> Bool { status == "idle" || status == "active" }
    static func isValidScreenshotPoint(_ point: CGPoint, width: Int, height: Int) -> Bool {
        width > 0 && height > 0 && point.x.isFinite && point.y.isFinite
            && point.x >= 0 && point.y >= 0 && point.x <= CGFloat(width) && point.y <= CGFloat(height)
    }
    static func turnParameters(threadID: String, input: [[String: Any]]) -> [String: Any] {
        // Session settings belong to the original Codex client.
        ["threadId": threadID, "input": input]
    }
}
