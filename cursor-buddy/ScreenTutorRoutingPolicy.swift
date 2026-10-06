import Foundation

nonisolated enum ScreenTutorRoutingPolicy {
    static func shouldStayInTutor(_ text: String) -> Bool {
        let normalized = text.lowercased()
        guard normalized.range(of: #"\b(screen|page|heading|button|menu|field)\b"#, options: .regularExpression) != nil else { return false }
        // Explicit agent work and actual interaction keep their existing routes.
        guard normalized.range(of: #"\b(agent|run|execute|delete|type|open)\b"#, options: .regularExpression) == nil else { return false }
        return normalized.range(of: #"\b(point (?:at|to)|highlight|draw (?:a |an )?(?:box|rectangle|circle))\b"#, options: .regularExpression) != nil
    }
}
