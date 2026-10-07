#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
cat > "$OUT/main.swift" <<'SWIFT'
import AppKit
let result = ReplyMarkdown.render("Press **Control+F**, then *Return*.\n\nUse `cat` and ==**important**==.")
precondition(result.string == "Press Control+F, then Return.\n\nUse cat and important.")
let value = result.string as NSString
let bold = result.attribute(.font, at: value.range(of: "Control+F").location, effectiveRange: nil) as! NSFont
precondition(NSFontManager.shared.traits(of: bold).contains(.boldFontMask))
let italic = result.attribute(.font, at: value.range(of: "Return").location, effectiveRange: nil) as! NSFont
precondition(NSFontManager.shared.traits(of: italic).contains(.italicFontMask))
precondition(result.attribute(.backgroundColor, at: value.range(of: "important").location, effectiveRange: nil) != nil)
let code = result.attribute(.font, at: value.range(of: "cat").location, effectiveRange: nil) as! NSFont
precondition(code.isFixedPitch)
precondition(ReplyMarkdown.render("`==literal==`").string == "==literal==")
let link = ReplyMarkdown.render("[docs](https://example.com)")
precondition(link.string == "docs" && link.attribute(.link, at: 0, effectiveRange: nil) != nil)
precondition(ReplyMarkdown.render("**unfinished").string.contains("unfinished"))
precondition(ReplyMarkdown.render("plain text").string == "plain text")
let shortHeight = ReplyMarkdown.height("Short reply", width: 240)
let longHeight = ReplyMarkdown.height(String(repeating: "This wraps across several lines. ", count: 20), width: 240)
precondition(longHeight > shortHeight * 4)
precondition(ReplyMarkdown.height("line one\n\nline two", width: 240) > shortHeight)
let full = "Detailed explanation.\n\n```sh\ncd ~/Documents/project\n```\n\nMore details."
let quoted = "The `<cursor_reply>` and [POINT:...] strings are conversation text.\n\nOur next practice is deliberately lengthy.\n\n<cursor_reply>\nType **help** in the right pane.\n</cursor_reply>"
let isolated = CursorReplyPresentation(quoted)
precondition(isolated.compact == "Type **help** in the right pane." && isolated.hasSummary)
precondition(!isolated.compact.contains("conversation text") && !isolated.compact.contains("cursor_reply"))
let fenced = "```xml\n<cursor_reply>\nNot a reply.\n</cursor_reply>\n```\n<cursor_reply>Real answer.</cursor_reply>"
precondition(CursorReplyPresentation(fenced).compact == "Real answer.")
precondition(CursorReplyPresentation(full).compact == CursorReplyPresentation.unavailable)
let unfinished = CursorReplyPresentation(full + "\n<cursor_reply>Run **cd**")
precondition(!unfinished.hasSummary && !unfinished.compact.contains("Detailed"))
let huge = CursorReplyPresentation("<cursor_reply>" + String(repeating: "word ", count: 100) + "</cursor_reply>")
precondition(huge.compact.split(whereSeparator: { $0.isWhitespace }).count <= 60 && huge.compact.count <= 600)
precondition(CursorReplyPresentation("<cursor_reply>Click here. [POINT:1,2:target]</cursor_reply>").compact == "Click here.")
precondition(CursorReplyPresentation("Short standalone answer.", requiresSummary: false).compact == "Short standalone answer.")
print("PASS: screenshot regression, dedicated summary isolation, code examples, absent/partial summary, hard length limits, and control metadata")
print("PASS: reply bold, italics, paragraphs, code, nested highlight, links, and partial Markdown")
SWIFT
swiftc "$ROOT/cursor-buddy/FormattedReplyText.swift" "$OUT/main.swift" -o "$OUT/check"
"$OUT/check"
