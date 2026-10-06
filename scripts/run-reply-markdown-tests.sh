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
let preview = CursorReplyPresentation(full)
precondition(preview.full == full && preview.compact.contains("cd ~/Documents/project") && !preview.hasSummary)
let summarized = CursorReplyPresentation(full + "\n<cursor_reply>Run **cd** first.</cursor_reply>")
precondition(summarized.full == full && summarized.compact == "Run **cd** first." && summarized.hasSummary)
let streaming = CursorReplyPresentation(full + "\n<cursor_reply>Run **cd**")
precondition(!streaming.full.contains("<cursor_reply>") && streaming.compact == "Run **cd**")
print("PASS: native wrapped height grows, paragraph height, compact/full separation, commands, and streaming summary")
print("PASS: reply bold, italics, paragraphs, code, nested highlight, links, and partial Markdown")
SWIFT
swiftc "$ROOT/cursor-buddy/FormattedReplyText.swift" "$OUT/main.swift" -o "$OUT/check"
"$OUT/check"
