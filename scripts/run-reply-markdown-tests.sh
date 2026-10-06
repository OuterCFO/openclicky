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
print("PASS: reply bold, italics, paragraphs, code, nested highlight, links, and partial Markdown")
SWIFT
swiftc "$ROOT/cursor-buddy/FormattedReplyText.swift" "$OUT/main.swift" -o "$OUT/check"
"$OUT/check"
