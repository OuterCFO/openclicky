import Foundation

nonisolated struct CompanionConversationStore: Codable {
    struct Conversation: Codable, Identifiable {
        var id: UUID
        var entries: [CodexTranscriptEntry]
        var summary: String?
        var archived = false
        var title: String { entries.first(where: { $0.role == .user }).map { String($0.text.prefix(42)) } ?? "New task" }
    }
    static let defaultsKey = "openclicky.companionConversations"
    var conversations: [Conversation]
    var activeID: UUID
    var active: Conversation { conversations.first(where: { $0.id == activeID })! }
    init(legacyEntries: [CodexTranscriptEntry] = [], summary: String? = nil) {
        let id = UUID(uuidString: "039BB5B3-6D99-481C-80E4-FC4B5AF86A43")!
        conversations = [Conversation(id: id, entries: legacyEntries, summary: summary)]
        activeID = id
    }
    static func load(from defaults: UserDefaults = .standard, legacyEntries: [CodexTranscriptEntry] = [], summary: String? = nil) -> Self {
        if let data = defaults.data(forKey: defaultsKey), let value = try? JSONDecoder().decode(Self.self, from: data),
           value.conversations.contains(where: { $0.id == value.activeID && !$0.archived }) { return value }
        return Self(legacyEntries: legacyEntries, summary: summary)
    }
    mutating func update(entries: [CodexTranscriptEntry], summary: String?) {
        guard let index = conversations.firstIndex(where: { $0.id == activeID }) else { return }
        conversations[index].entries = entries
        conversations[index].summary = summary
    }
    mutating func startNew() {
        let task = Conversation(id: UUID(), entries: [], summary: nil)
        conversations.append(task)
        activeID = task.id
    }
    @discardableResult mutating func select(_ id: UUID) -> Bool {
        guard conversations.contains(where: { $0.id == id && !$0.archived }) else { return false }
        activeID = id
        return true
    }
    mutating func removeActive() {
        if let index = conversations.firstIndex(where: { $0.id == activeID }) { conversations[index].archived = true }
        if let next = conversations.last(where: { !$0.archived }) { activeID = next.id } else { startNew() }
    }
    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Self.defaultsKey) }
    }
}
