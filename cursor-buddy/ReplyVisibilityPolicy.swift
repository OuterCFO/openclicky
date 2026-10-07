/// Manual dismissal stays in effect for the current reply, including late chunks.
/// A new question explicitly resets it; elapsed time never changes visibility.
nonisolated struct ReplyVisibilityPolicy: Equatable, Sendable {
    private(set) var isDismissed = false
    var canPresent: Bool { !isDismissed }

    /// Holding a reply prevents timeout dismissal, not the user's mouse movement.
    static func shouldResumeFollowing(isPinned: Bool, mouseTravel: Double) -> Bool {
        isPinned && mouseTravel.isFinite && mouseTravel > 24
    }

    mutating func dismiss() { isDismissed = true }
    mutating func beginNewReply() { isDismissed = false }
}
