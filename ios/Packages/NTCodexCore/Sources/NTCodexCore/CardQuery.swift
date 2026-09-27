import Foundation

/// Search + filter + sort criteria for the Cards tab. Mirrors browse.js apply().
public struct CardQuery: Hashable, Sendable {
    public enum Mode: String, CaseIterable, Sendable {
        case name, text
        public var label: String { self == .name ? "By name" : "By card text" }
    }

    public enum Sort: String, CaseIterable, Sendable {
        case reading, atk, def, level, en
        public var label: String {
            switch self {
            case .reading: return "あいうえお"
            case .atk: return "ATK ↓"
            case .def: return "DEF ↓"
            case .level: return "Level ↓"
            case .en: return "A–Z"
            }
        }
    }

    public var text: String = ""
    public var mode: Mode = .name
    public var cardType: CardType? = nil
    public var attributes: Set<Attribute> = []
    public var races: Set<String> = []
    public var categories: Set<String> = []
    public var levels: Set<Int> = []
    public var atkMin: Int? = nil
    public var atkMax: Int? = nil
    public var defMin: Int? = nil
    public var defMax: Int? = nil
    public var pack: String? = nil
    public var sort: Sort = .reading

    public init() {}

    /// True when any filter (not the search text or sort) is active.
    public var hasActiveFilters: Bool {
        cardType != nil || !attributes.isEmpty || !races.isEmpty || !categories.isEmpty || !levels.isEmpty
            || atkMin != nil || atkMax != nil || defMin != nil || defMax != nil || pack != nil
    }

    public var activeFilterCount: Int {
        var n = 0
        if cardType != nil { n += 1 }
        n += attributes.count + races.count + categories.count + levels.count
        if atkMin != nil || atkMax != nil { n += 1 }
        if defMin != nil || defMax != nil { n += 1 }
        if pack != nil { n += 1 }
        return n
    }

    public mutating func clearFilters() {
        cardType = nil; attributes = []; races = []; categories = []; levels = []
        atkMin = nil; atkMax = nil; defMin = nil; defMax = nil; pack = nil
    }

    // MARK: Evaluation

    /// Pack names whose EN / JA / romaji name contains the query (name mode only).
    static func matchingPacks(_ query: String, in packs: [Pack]) -> Set<String> {
        let qL = query.lowercased()
        var out = Set<String>()
        for p in packs {
            if p.name.lowercased().contains(qL)
                || (p.ja?.contains(query) ?? false)
                || (p.romaji?.lowercased().contains(qL) ?? false) {
                out.insert(p.name)
            }
        }
        return out
    }

    /// Kana-insensitive name match with `*` wildcards; substring otherwise.
    public static func nameMatches(_ c: Card, query q: String) -> Bool {
        let qH = JapaneseText.katakanaToHiragana(q)
        let qL = q.lowercased()
        let jaH = JapaneseText.katakanaToHiragana(c.ja)
        let rdH = JapaneseText.katakanaToHiragana(c.reading)
        let en = c.en.lowercased()
        if q.contains("*") {
            return JapaneseText.wildcardMatch(qH, jaH) || JapaneseText.wildcardMatch(qH, rdH)
                || JapaneseText.wildcardMatch(qL, en)
        }
        return jaH.contains(qH) || rdH.contains(qH) || en.contains(qL)
    }

    public static func textMatches(_ c: Card, query q: String) -> Bool {
        let qH = JapaneseText.katakanaToHiragana(q)
        if JapaneseText.katakanaToHiragana(c.jpEff).contains(qH) { return true }
        return !c.enEff.isEmpty && c.enEff.lowercased().contains(q.lowercased())
    }

    public func matches(_ c: Card, packMatch: Set<String>) -> Bool {
        if let cardType, c.cardType != cardType { return false }
        if let pack, !c.packs.contains(where: { $0.pack == pack }) { return false }
        if !races.isEmpty { guard let r = c.race, races.contains(r) else { return false } }
        if !categories.isEmpty { guard let k = c.category, categories.contains(k) else { return false } }
        if !attributes.isEmpty { guard let a = c.attribute, attributes.contains(a) else { return false } }
        if !levels.isEmpty { guard let l = c.level, levels.contains(l) else { return false } }
        if let atkMin { guard let a = c.atk, a >= atkMin else { return false } }
        if let atkMax { guard let a = c.atk, a <= atkMax else { return false } }
        if let defMin { guard let d = c.def, d >= defMin else { return false } }
        if let defMax { guard let d = c.def, d <= defMax else { return false } }
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            switch mode {
            case .text:
                if !Self.textMatches(c, query: q) { return false }
            case .name:
                let inCard = Self.nameMatches(c, query: q)
                let inPack = c.packs.contains { packMatch.contains($0.pack) }
                if !inCard && !inPack { return false }
            }
        }
        return true
    }

    /// Filters and sorts the database's cards.
    public func apply(to db: CardDatabase) -> [Card] {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let packMatch = (!q.isEmpty && mode == .name) ? Self.matchingPacks(q, in: db.packs) : []
        let res = db.cards.filter { matches($0, packMatch: packMatch) }
        return Self.sorted(res, by: sort)
    }

    public static func sorted(_ list: [Card], by sort: Sort) -> [Card] {
        switch sort {
        case .atk:
            return list.sorted { ($0.atk ?? -1) > ($1.atk ?? -1) }
        case .def:
            return list.sorted { ($0.def ?? -1) > ($1.def ?? -1) }
        case .level:
            return list.sorted { ($0.level ?? -1) > ($1.level ?? -1) }
        case .en:
            return list.sorted { $0.en.localizedCaseInsensitiveCompare($1.en) == .orderedAscending }
        case .reading:
            return list.sorted {
                let ka = JapaneseText.katakanaToHiragana($0.reading.isEmpty ? $0.ja : $0.reading)
                let kb = JapaneseText.katakanaToHiragana($1.reading.isEmpty ? $1.ja : $1.reading)
                return ka.unicodeScalars.lexicographicallyPrecedes(kb.unicodeScalars)
            }
        }
    }
}
