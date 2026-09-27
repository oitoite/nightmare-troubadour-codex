import Foundation

/// A card's broad kind. Mirrors `cardType` in cards.json.
public enum CardType: String, Codable, Hashable, Sendable, CaseIterable {
    case monster, spell, trap

    public var labelEn: String {
        switch self {
        case .monster: return "Monster"
        case .spell: return "Spell"
        case .trap: return "Trap"
        }
    }

    /// 魔法 / 罠 — the kanji used on the physical card's type medallion.
    public var kanji: String {
        switch self {
        case .monster: return ""
        case .spell: return "魔"
        case .trap: return "罠"
        }
    }

    public var labelJa: String {
        switch self {
        case .monster: return "モンスター"
        case .spell: return "魔法"
        case .trap: return "罠"
        }
    }
}

/// Card frame (drives the accent colour). Unknown values decode as `.unknown`.
public enum CardFrame: String, Codable, Hashable, Sendable, CaseIterable {
    case normal, effect, ritual, fusion, synchro, xyz, link, spell, trap, unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CardFrame(rawValue: raw) ?? .unknown
    }

    /// Hex colour from the web app's `--f-*` CSS variables.
    public var hex: String {
        switch self {
        case .normal: return "#c9a44b"
        case .effect: return "#c07a3a"
        case .ritual: return "#4a74b0"
        case .fusion: return "#8a5aa8"
        case .synchro: return "#c0bfbe"
        case .xyz: return "#555555"
        case .link: return "#3a7a9a"
        case .spell: return "#1d9e75"
        case .trap: return "#c2185b"
        case .unknown: return "#c9a44b"
        }
    }
}

/// Monster attribute. Order matches the web app's filter strip.
public enum Attribute: String, Codable, Hashable, Sendable, CaseIterable {
    case dark, light, earth, water, fire, wind, divine

    public var labelEn: String { rawValue.uppercased() }

    public var kanji: String {
        switch self {
        case .light: return "光"
        case .dark: return "闇"
        case .water: return "水"
        case .fire: return "炎"
        case .earth: return "地"
        case .wind: return "風"
        case .divine: return "神"
        }
    }

    /// Official attribute icon (PNG) from the Konami card database.
    public var iconURL: URL? {
        URL(string: "https://www.db.yugioh-card.com/yugiohdb/external/image/parts/attribute/attribute_icon_\(rawValue).png")
    }

    /// Approximate medallion colour used when drawing the badge natively.
    public var hex: String {
        switch self {
        case .light: return "#d9b23c"
        case .dark: return "#5b2d8e"
        case .water: return "#2a6fbf"
        case .fire: return "#c9352b"
        case .earth: return "#6b4b2a"
        case .wind: return "#3e9a5a"
        case .divine: return "#c9a44b"
        }
    }
}

/// A pack the card appears in, with its rarity in that pack.
public struct PackEntry: Codable, Hashable, Sendable {
    public var pack: String
    public var rarity: String?

    public init(pack: String, rarity: String?) {
        self.pack = pack
        self.rarity = rarity
    }
}

/// One card from cards.json.
public struct Card: Codable, Identifiable, Hashable, Sendable {
    /// YGOResources database id. Missing for a handful of cards.
    public var dbId: Int?
    public var en: String
    public var ja: String
    public var reading: String
    public var jpEff: String
    public var enEff: String
    public var cardType: CardType
    public var race: String?
    public var raceJa: String?
    public var category: String?
    public var categoryJa: String?
    public var frame: CardFrame
    public var attribute: Attribute?
    public var level: Int?
    public var atk: Int?
    public var def: Int?
    public var spellTrapType: String?
    public var spellTrapTypeJa: String?
    public var img: String?
    public var passcode: String?
    public var packs: [PackEntry]
    public var jpEffHtml: String?
    public var typeLineJaHtml: String?

    enum CodingKeys: String, CodingKey {
        case dbId = "id"
        case en, ja, reading, jpEff, enEff, cardType, race, raceJa, category, categoryJa
        case frame, attribute, level, atk, def, spellTrapType, spellTrapTypeJa, img, passcode
        case packs, jpEffHtml, typeLineJaHtml
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dbId = try c.decodeIfPresent(Int.self, forKey: .dbId)
        en = try c.decodeIfPresent(String.self, forKey: .en) ?? ""
        ja = try c.decodeIfPresent(String.self, forKey: .ja) ?? ""
        reading = try c.decodeIfPresent(String.self, forKey: .reading) ?? ""
        jpEff = try c.decodeIfPresent(String.self, forKey: .jpEff) ?? ""
        enEff = try c.decodeIfPresent(String.self, forKey: .enEff) ?? ""
        cardType = try c.decode(CardType.self, forKey: .cardType)
        race = try c.decodeIfPresent(String.self, forKey: .race)
        raceJa = try c.decodeIfPresent(String.self, forKey: .raceJa)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        categoryJa = try c.decodeIfPresent(String.self, forKey: .categoryJa)
        frame = try c.decodeIfPresent(CardFrame.self, forKey: .frame) ?? .unknown
        if let a = try c.decodeIfPresent(String.self, forKey: .attribute) {
            attribute = Attribute(rawValue: a.lowercased())
        } else {
            attribute = nil
        }
        level = try c.decodeIfPresent(Int.self, forKey: .level)
        atk = try c.decodeIfPresent(Int.self, forKey: .atk)
        def = try c.decodeIfPresent(Int.self, forKey: .def)
        spellTrapType = try c.decodeIfPresent(String.self, forKey: .spellTrapType)
        spellTrapTypeJa = try c.decodeIfPresent(String.self, forKey: .spellTrapTypeJa)
        img = try c.decodeIfPresent(String.self, forKey: .img)
        // passcode may be a string or (defensively) a number
        if let s = try? c.decodeIfPresent(String.self, forKey: .passcode) {
            passcode = s
        } else if let n = try? c.decodeIfPresent(Int.self, forKey: .passcode) {
            passcode = String(n)
        } else {
            passcode = nil
        }
        packs = try c.decodeIfPresent([PackEntry].self, forKey: .packs) ?? []
        jpEffHtml = try c.decodeIfPresent(String.self, forKey: .jpEffHtml)
        typeLineJaHtml = try c.decodeIfPresent(String.self, forKey: .typeLineJaHtml)
    }

    public init(
        dbId: Int? = nil, en: String, ja: String, reading: String = "", jpEff: String = "", enEff: String = "",
        cardType: CardType, race: String? = nil, raceJa: String? = nil, category: String? = nil, categoryJa: String? = nil,
        frame: CardFrame = .unknown, attribute: Attribute? = nil, level: Int? = nil, atk: Int? = nil, def: Int? = nil,
        spellTrapType: String? = nil, spellTrapTypeJa: String? = nil, img: String? = nil, passcode: String? = nil,
        packs: [PackEntry] = [], jpEffHtml: String? = nil, typeLineJaHtml: String? = nil
    ) {
        self.dbId = dbId; self.en = en; self.ja = ja; self.reading = reading; self.jpEff = jpEff; self.enEff = enEff
        self.cardType = cardType; self.race = race; self.raceJa = raceJa; self.category = category; self.categoryJa = categoryJa
        self.frame = frame; self.attribute = attribute; self.level = level; self.atk = atk; self.def = def
        self.spellTrapType = spellTrapType; self.spellTrapTypeJa = spellTrapTypeJa; self.img = img; self.passcode = passcode
        self.packs = packs; self.jpEffHtml = jpEffHtml; self.typeLineJaHtml = typeLineJaHtml
    }

    // MARK: Derived

    /// Stable identity: database id, else passcode, else English name.
    public var id: String {
        if let dbId { return "id:\(dbId)" }
        if let passcode, !passcode.isEmpty { return "pass:\(passcode)" }
        return "en:\(en)"
    }

    public var isMonster: Bool { cardType == .monster }

    public var imageURL: URL? {
        guard let img, !img.isEmpty else { return nil }
        return URL(string: img)
    }

    /// Accent colour for this card (frame colour, falling back on card type).
    public var frameHex: String {
        switch frame {
        case .unknown:
            switch cardType {
            case .spell: return CardFrame.spell.hex
            case .trap: return CardFrame.trap.hex
            case .monster: return CardFrame.normal.hex
            }
        default:
            return frame.hex
        }
    }

    /// True when the reading differs from the name and is worth showing as ruby.
    public var showsReading: Bool {
        !reading.isEmpty && reading != ja && !ja.isEmpty
    }

    /// 【種族／カテゴリ】 for monsters; 魔法カード / 罠カード otherwise.
    public var typeLineJa: String {
        guard isMonster else { return cardType.labelJa + "カード" }
        let r = raceJa ?? race ?? ""
        let cat = categoryJa ?? category ?? ""
        return "【" + r + (cat.isEmpty ? "" : "／" + cat) + "】"
    }

    public var typeLineEn: String {
        guard isMonster else { return cardType.labelEn + " Card" }
        let parts = [race, category].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " / ") + " Monster"
    }

    /// e.g. "永続魔法" / "罠カード" — the sub-type label in Japanese.
    public var spellTrapLabelJa: String {
        if let ja = spellTrapTypeJa, !ja.isEmpty { return ja + cardType.labelJa }
        return cardType.labelJa + "カード"
    }

    /// e.g. "Continuous Spell" / "Trap Card".
    public var spellTrapLabelEn: String {
        if let t = spellTrapType, !t.isEmpty { return t + " " + cardType.labelEn }
        return cardType.labelEn + " Card"
    }

    /// Level stars as a string (★×level), "0" for level 0.
    public var levelStars: String? {
        guard let level else { return nil }
        return level > 0 ? String(repeating: "★", count: level) : "0"
    }

    public var ygoResourcesJaURL: URL? {
        guard let dbId else { return nil }
        return URL(string: "https://db.ygoresources.com/card#\(dbId):ja")
    }

    public var ygoResourcesEnURL: URL? {
        guard let dbId else { return nil }
        return URL(string: "https://db.ygoresources.com/card#\(dbId)")
    }

    public var yugipediaURL: URL? {
        guard !en.isEmpty else { return nil }
        let title = en.replacingOccurrences(of: " ", with: "_")
        guard let enc = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "https://yugipedia.com/wiki/\(enc)")
    }

    /// Rarity of this card in the given pack, if it appears there.
    public func rarity(in packName: String) -> String? {
        packs.first { $0.pack == packName }?.rarity
    }
}
