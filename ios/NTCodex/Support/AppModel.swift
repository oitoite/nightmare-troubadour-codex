import Foundation
import Observation
import NTCodexCore

/// Which language the effect text is displayed in.
enum EffectLanguage: String, CaseIterable {
    case jp, en
    var label: String { self == .jp ? "日本語" : "English" }
}

/// Observable wrapper around the Foundation-only `MyCardsStore`.
@Observable @MainActor
final class MyCardsModel {
    private let store: MyCardsStore
    private(set) var savedCards: [SavedCard]

    init(store: MyCardsStore = MyCardsStore()) {
        self.store = store
        self.savedCards = store.cards
    }

    func isSaved(_ card: Card) -> Bool { savedCards.contains { $0.card.id == card.id } }

    func save(_ card: Card) {
        store.save(card)
        savedCards = store.cards
    }

    func remove(_ card: Card) {
        store.remove(card)
        savedCards = store.cards
    }

    func updateNote(for card: Card, note: String) {
        store.updateNote(for: card, note: note)
        savedCards = store.cards
    }
}

/// App-wide state: the loaded database, saved cards, and display preferences.
@Observable @MainActor
final class AppModel {
    private(set) var db: CardDatabase?
    private(set) var loadError: String?
    var isLoading = true

    let myCards = MyCardsModel()

    /// Show furigana above kanji in effect text. Persisted.
    var furigana: Bool {
        didSet { UserDefaults.standard.set(furigana, forKey: "nt-furigana") }
    }

    /// Effect-text language. Persisted.
    var language: EffectLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "nt-lang") }
    }

    init() {
        let d = UserDefaults.standard
        furigana = d.object(forKey: "nt-furigana") as? Bool ?? true
        language = EffectLanguage(rawValue: d.string(forKey: "nt-lang") ?? "") ?? .jp
    }

    /// Decodes the bundled JSON off the main thread.
    func load() async {
        guard db == nil else { return }
        isLoading = true
        do {
            let loaded = try await Task.detached(priority: .userInitiated) { try CardDatabase.loadBundled() }.value
            db = loaded
            loadError = nil
        } catch {
            loadError = String(describing: error)
        }
        isLoading = false
    }
}
