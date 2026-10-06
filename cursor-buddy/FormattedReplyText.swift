import AppKit
import SwiftUI

/// Native rich text keeps emphasis and highlights while wrapping at the bubble width.
struct FormattedReplyText: NSViewRepresentable {
    let text: String
    let width: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        let view = NSTextView()
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = true
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        view.autoresizingMask = [.width]
        scroll.documentView = view
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? NSTextView else { return }
        view.textStorage?.setAttributedString(ReplyMarkdown.render(text))
        let width = max(1, width - 15)
        view.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        view.frame.size = NSSize(width: width, height: ReplyMarkdown.height(text, width: width))
    }

}

nonisolated enum ReplyMarkdown {
    /// Use the same TextKit wrapping as the visible text, independent of host fittingSize.
    static func height(_ text: String, width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: render(text))
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: max(1, width), height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        layout.ensureLayout(for: container)
        return max(18, ceil(layout.usedRect(for: container).height) + 2)
    }

    static func render(_ source: String) -> NSAttributedString {
        let parsed = (try? AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(source)
        let output = NSMutableAttributedString()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        for run in parsed.runs {
            let value = String(parsed[run.range].characters)
            let intent = run.inlinePresentationIntent ?? []
            var font = NSFont.systemFont(ofSize: 13)
            var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.labelColor, .paragraphStyle: paragraph]
            if intent.contains(.code) {
                font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                attributes[.backgroundColor] = NSColor.secondaryLabelColor.withAlphaComponent(0.15)
                attributes[NSAttributedString.Key("OpenClickyInlineCode")] = true
            } else {
                if intent.contains(.stronglyEmphasized) { font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask) }
                if intent.contains(.emphasized) { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
            }
            attributes[.font] = font
            if intent.contains(.strikethrough) { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
            if let link = run.link { attributes[.link] = link }
            let segment = NSAttributedString(string: value, attributes: attributes)
            output.append(segment)
        }
        // Process highlights after Markdown so nested bold/italic formatting survives.
        if let regex = try? NSRegularExpression(pattern: #"==([^=\n]+)=="#) {
            let value = output.string
            for match in regex.matches(in: value, range: NSRange(location: 0, length: output.length)).reversed() {
                var containsCode = false
                output.enumerateAttribute(NSAttributedString.Key("OpenClickyInlineCode"), in: match.range) { value, _, _ in
                    if value as? Bool == true { containsCode = true }
                }
                guard !containsCode else { continue }
                output.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.30), range: match.range(at: 1))
                output.deleteCharacters(in: NSRange(location: NSMaxRange(match.range) - 2, length: 2))
                output.deleteCharacters(in: NSRange(location: match.range.location, length: 2))
            }
        }
        return output
    }
}

/// Presentation only: the session's canonical response is never shortened or rewritten.
nonisolated struct CursorReplyPresentation {
    let full: String
    let compact: String
    let hasSummary: Bool

    init(_ source: String) {
        let opening = "<cursor_reply>"
        let closing = "</cursor_reply>"
        if let start = source.range(of: opening) {
            let tail = source[start.upperBound...]
            let end = tail.range(of: closing)
            let summary = String(tail[..<(end?.lowerBound ?? tail.endIndex)]).trimmingCharacters(in: .whitespacesAndNewlines)
            let before = String(source[..<start.lowerBound])
            let after = end.map { String(source[$0.upperBound...]) } ?? ""
            full = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
            compact = summary.isEmpty ? Self.preview(full) : summary
            hasSummary = !summary.isEmpty
        } else {
            full = source
            compact = Self.preview(source)
            hasSummary = false
        }
    }

    private static func preview(_ source: String) -> String {
        // Whole paragraphs preserve Markdown; include the first command when present.
        let blocks = source.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard let first = blocks.first else { return source }
        if let command = blocks.dropFirst().first(where: { $0.contains("```") }), first.count < 400 {
            return first + "\n\n" + command
        }
        return first
    }
}
