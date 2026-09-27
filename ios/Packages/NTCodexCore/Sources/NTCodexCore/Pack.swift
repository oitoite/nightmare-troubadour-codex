import Foundation

/// A booster pack from packs.json.
public struct Pack: Codable, Identifiable, Hashable, Sendable {
    public var name: String
    public var ja: String?
    public var romaji: String?
    public var count: Int?
    public var img: String?

    public var id: String { name }

    public init(name: String, ja: String? = nil, romaji: String? = nil, count: Int? = nil, img: String? = nil) {
        self.name = name; self.ja = ja; self.romaji = romaji; self.count = count; self.img = img
    }

    public var imageURL: URL? {
        guard let img, !img.isEmpty else { return nil }
        return URL(string: img)
    }

    /// Japanese name when present, else the English name.
    public var displayJa: String {
        if let ja, !ja.isEmpty { return ja }
        return name
    }

    /// "Name — 日本語" as used in the pack picker.
    public var pickerLabel: String {
        if let ja, !ja.isEmpty { return name + " — " + ja }
        return name
    }
}

/// Rarity ordering used when grouping a pack's cards.
public enum Rarity {
    public static let order = ["Ultra Rare", "Super Rare", "Rare", "Common"]

    public static func rank(_ r: String) -> Int {
        order.firstIndex(of: r) ?? 99
    }
}

/// A word from vocabulary.json (card effect vocabulary).
public struct VocabWord: Codable, Hashable, Sendable {
    public var ja: String
    public var reading: String?
    public var en: String?

    public init(ja: String, reading: String? = nil, en: String? = nil) {
        self.ja = ja; self.reading = reading; self.en = en
    }
}

/// A term from game-terms.json (menus, duel flow, etc.).
public struct GameTerm: Codable, Hashable, Sendable {
    public var ja: String
    public var reading: String?
    public var en: String?
    public var cat: String?

    public init(ja: String, reading: String? = nil, en: String? = nil, cat: String? = nil) {
        self.ja = ja; self.reading = reading; self.en = en; self.cat = cat
    }
}
