import Foundation

/// A card the user saved, with their note. Persisted as JSON.
public struct SavedCard: Codable, Hashable, Sendable, Identifiable {
    public var card: Card
    public var savedAt: Date
    public var userNote: String

    public var id: String { card.id }

    public init(card: Card, savedAt: Date = Date(), userNote: String = "") {
        self.card = card; self.savedAt = savedAt; self.userNote = userNote
    }
}

/// Persistence for "My Cards". Foundation-only so it can be unit tested on any
/// platform; the app wraps it in an observable model.
public final class MyCardsStore {
    public private(set) var cards: [SavedCard]
    private let fileURL: URL

    /// Default location: Application Support/NTCodex/my-cards.json.
    public static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("NTCodex", isDirectory: true).appendingPathComponent("my-cards.json")
    }

    public init(fileURL: URL = MyCardsStore.defaultFileURL()) {
        self.fileURL = fileURL
        self.cards = Self.read(from: fileURL)
    }

    private static func read(from url: URL) -> [SavedCard] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return (try? dec.decode([SavedCard].self, from: data)) ?? []
    }

    private func write() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(cards) else { return }
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    public func isSaved(_ card: Card) -> Bool {
        cards.contains { $0.card.id == card.id }
    }

    /// Adds to the front of the list. No-op if already saved.
    @discardableResult
    public func save(_ card: Card) -> Bool {
        guard !isSaved(card) else { return false }
        cards.insert(SavedCard(card: card), at: 0)
        write()
        return true
    }

    public func remove(_ card: Card) {
        cards.removeAll { $0.card.id == card.id }
        write()
    }

    public func remove(at index: Int) {
        guard cards.indices.contains(index) else { return }
        cards.remove(at: index)
        write()
    }

    public func updateNote(for card: Card, note: String) {
        guard let i = cards.firstIndex(where: { $0.card.id == card.id }) else { return }
        cards[i].userNote = note
        write()
    }

    /// Reloads from disk (for tests / external changes).
    public func reload() {
        cards = Self.read(from: fileURL)
    }
}
