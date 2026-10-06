import AppKit
import SwiftUI

/// Native rich text keeps emphasis and highlights while wrapping at the bubble width.
struct FormattedReplyText: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.isEditable = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = true
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        view.textStorage?.setAttributedString(ReplyMarkdown.render(text))
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        let width = max(1, proposal.width ?? 280)
        nsView.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        guard let container = nsView.textContainer, let layout = nsView.layoutManager else { return nil }
        layout.ensureLayout(for: container)
        return CGSize(width: width, height: ceil(layout.usedRect(for: container).height))
    }
}

nonisolated enum ReplyMarkdown {
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
