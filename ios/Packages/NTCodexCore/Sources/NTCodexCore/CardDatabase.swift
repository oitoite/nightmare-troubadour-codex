import Foundation

/// Errors raised while loading the bundled JSON data.
public enum DatabaseError: Error, CustomStringConvertible {
    case missingResource(String)

    public var description: String {
        switch self {
        case .missingResource(let name): return "Missing bundled resource: \(name)"
        }
    }
}

/// The full in-memory dataset plus the derived indexes the UI needs.
public struct CardDatabase: Sendable {
    public let cards: [Card]
    public let packs: [Pack]
    public let vocab: [VocabWord]
    public let gameTerms: [GameTerm]

    /// Monster types present in the data, sorted.
    public let races: [String]
    /// Monster categories present, in the web app's canonical order.
    public let categories: [String]

    public let packByName: [String: Pack]
    public let cardsByPack: [String: [Card]]
    public let vocabByWord: [String: VocabWord]
    public let cardById: [String: Card]

    public static let categoryOrder = [
        "Normal", "Effect", "Ritual", "Fusion", "Synchro", "Xyz", "Pendulum", "Link",
        "Toon", "Spirit", "Union", "Gemini", "Tuner", "Flip",
    ]

    public init(cards: [Card], packs: [Pack], vocab: [VocabWord], gameTerms: [GameTerm]) {
        self.cards = cards
        self.vocab = vocab
        self.gameTerms = gameTerms

        var raceSet = Set<String>()
        var catSet = Set<String>()
        var byPack: [String: [Card]] = [:]
        var byId: [String: Card] = [:]
        for c in cards {
            if let r = c.race, !r.isEmpty { raceSet.insert(r) }
            if let k = c.category, !k.isEmpty { catSet.insert(k) }
            for p in c.packs { byPack[p.pack, default: []].append(c) }
            if byId[c.id] == nil { byId[c.id] = c }
        }
        races = raceSet.sorted()
        categories = Self.categoryOrder.filter { catSet.contains($0) }
            + catSet.subtracting(Self.categoryOrder).sorted()

        // Fall back to pack names derived from the cards if packs.json is empty.
        let resolvedPacks = packs.isEmpty ? byPack.keys.sorted().map { Pack(name: $0) } : packs
        self.packs = resolvedPacks
        var pbn: [String: Pack] = [:]
        for p in resolvedPacks { pbn[p.name] = p }
        packByName = pbn
        cardsByPack = byPack
        cardById = byId

        var vmap: [String: VocabWord] = [:]
        for w in vocab where vmap[w.ja] == nil { vmap[w.ja] = w }
        vocabByWord = vmap
    }

    // MARK: Loading

    struct CardsFile: Decodable { var cards: [Card] }
    struct PacksFile: Decodable { var packs: [Pack] }
    struct VocabFile: Decodable { var words: [VocabWord] }
    struct TermsFile: Decodable { var terms: [GameTerm] }

    /// Decodes the four JSON documents. Only cards.json is required.
    public static func load(cardsData: Data, packsData: Data?, vocabData: Data?, gameTermsData: Data?) throws -> CardDatabase {
        let dec = JSONDecoder()
        let cards = try dec.decode(CardsFile.self, from: cardsData).cards
        let packs = (try? packsData.map { try dec.decode(PacksFile.self, from: $0).packs }) ?? []
        let vocab = (try? vocabData.map { try dec.decode(VocabFile.self, from: $0).words }) ?? []
        let terms = (try? gameTermsData.map { try dec.decode(TermsFile.self, from: $0).terms }) ?? []
        return CardDatabase(cards: cards, packs: packs, vocab: vocab, gameTerms: terms)
    }

    /// Loads from this package's bundled `Resources/` directory.
    public static func loadBundled() throws -> CardDatabase {
        func data(_ name: String) -> Data? {
            guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Resources") else {
                return nil
            }
            return try? Data(contentsOf: url)
        }
        guard let cards = data("cards") else { throw DatabaseError.missingResource("cards.json") }
        return try load(cardsData: cards, packsData: data("packs"), vocabData: data("vocabulary"), gameTermsData: data("game-terms"))
    }

    // MARK: Lookups

    public func pack(named name: String) -> Pack? { packByName[name] }

    public func cards(inPack name: String) -> [Card] { cardsByPack[name] ?? [] }

    /// A pack's cards grouped by rarity, Ultra → Common, then any others.
    public func cardsByRarity(inPack name: String) -> [(rarity: String, cards: [Card])] {
        var groups: [String: [Card]] = [:]
        for c in cards(inPack: name) {
            groups[c.rarity(in: name) ?? "Common", default: []].append(c)
        }
        return groups.keys
            .sorted { (Rarity.rank($0), $0) < (Rarity.rank($1), $1) }
            .map { (rarity: $0, cards: groups[$0]!) }
    }

    public func vocab(for word: String) -> VocabWord? { vocabByWord[word] }
}
