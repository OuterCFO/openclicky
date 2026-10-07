import Foundation

/// A top-level pointing directive can precede the concise summary, not only end the answer.
nonisolated enum CursorPointDirective {
    struct Parsed {
        let spokenText: String
        let coordinate: CGPoint?
        let label: String?
        let screenNumber: Int?
    }

    static func extract(_ source: String) -> Parsed? {
        let lines = source.components(separatedBy: "\n")
        let pattern = #"^\[POINT:(?:none|(\d+)\s*,\s*(\d+)(?::([^\]:\s][^\]:]*?))?(?::screen(\d+))?)\]$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        var fence: String?
        var inSummary = false
        var selected: (index: Int, line: String, match: NSTextCheckingResult)?
        for (index, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                let marker = String(line.prefix(3))
                if fence == marker { fence = nil } else if fence == nil { fence = marker }
                continue
            }
            guard fence == nil else { continue }
            if line.hasPrefix("<cursor_reply>") { inSummary = !line.contains("</cursor_reply>"); continue }
            if inSummary {
                if line.contains("</cursor_reply>") { inSummary = false }
                continue
            }
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) {
                selected = (index, line, match)
            }
        }
        guard let selected else { return nil }
        func field(_ index: Int) -> String? {
            let range = selected.match.range(at: index)
            return range.location == NSNotFound ? nil : (selected.line as NSString).substring(with: range)
        }
        let coordinate: CGPoint?
        if let x = field(1).flatMap(Double.init), let y = field(2).flatMap(Double.init) {
            coordinate = CGPoint(x: x, y: y)
        } else { coordinate = nil }
        let spoken = lines.enumerated().filter { $0.offset != selected.index }.map(\.element).joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Parsed(spokenText: spoken, coordinate: coordinate,
                      label: field(3)?.trimmingCharacters(in: .whitespaces) ?? (coordinate == nil ? "none" : nil),
                      screenNumber: field(4).flatMap(Int.init))
    }
}
