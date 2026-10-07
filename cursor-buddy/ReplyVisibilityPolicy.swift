/// Manual dismissal stays in effect for the current reply, including late chunks.
/// A new question explicitly resets it; elapsed time never changes visibility.
nonisolated struct ReplyVisibilityPolicy: Equatable, Sendable {
    private(set) var isDismissed = false
    var canPresent: Bool { !isDismissed }

    static let minimumPointingHold: Double = 3

    /// Mouse movement cannot interrupt a pointing flight or the first three seconds at its target.
    static func shouldResumeFollowing(isPinned: Bool, mouseTravel: Double, timeSinceArrival: Double) -> Bool {
        isPinned && mouseTravel.isFinite && mouseTravel > 24
            && timeSinceArrival.isFinite && timeSinceArrival >= minimumPointingHold
    }

    mutating func dismiss() { isDismissed = true }
    mutating func beginNewReply() { isDismissed = false }
}
