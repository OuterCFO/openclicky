/// Manual dismissal stays in effect for the current reply, including late chunks.
/// A new question explicitly resets it; elapsed time never changes visibility.
nonisolated struct ReplyVisibilityPolicy: Equatable, Sendable {
    private(set) var isDismissed = false
    var canPresent: Bool { !isDismissed }

    mutating func dismiss() { isDismissed = true }
    mutating func beginNewReply() { isDismissed = false }
}
