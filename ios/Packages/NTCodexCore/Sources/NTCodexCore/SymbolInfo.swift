import Foundation

/// Explanation shown when a card symbol (attribute, level, spell/trap type) is tapped.
public struct SymbolInfo: Hashable, Sendable {
    public var label: String
    public var ja: String
    public var meaning: String

    public init(label: String, ja: String, meaning: String) {
        self.label = label; self.ja = ja; self.meaning = meaning
    }
}

public enum SymbolKind: Hashable, Sendable {
    case attribute(Attribute)
    case level(Int)
    case spell(String)
    case trap(String)
}

public enum Symbols {
    public static func info(for kind: SymbolKind) -> SymbolInfo? {
        switch kind {
        case .level(let n):
            return SymbolInfo(
                label: "Level \(n)", ja: "レベル\(n)",
                meaning: "Higher level = stronger, but harder to Summon (Levels 5–6 need 1 Tribute, 7+ need 2).")
        case .attribute(let a):
            return attributes[a]
        case .spell(let t):
            return spells[t]
        case .trap(let t):
            return traps[t]
        }
    }

    public static let attributes: [Attribute: SymbolInfo] = [
        .light: SymbolInfo(label: "LIGHT", ja: "光", meaning: "Light attribute — Fairy and other bright monsters; opposes DARK."),
        .dark: SymbolInfo(label: "DARK", ja: "闇", meaning: "Dark attribute — Fiend, undead and shadow monsters; opposes LIGHT."),
        .water: SymbolInfo(label: "WATER", ja: "水", meaning: "Water attribute — aquatic and ice monsters; opposes FIRE."),
        .fire: SymbolInfo(label: "FIRE", ja: "炎", meaning: "Fire attribute — flame monsters; opposes WATER."),
        .earth: SymbolInfo(label: "EARTH", ja: "地", meaning: "Earth attribute — ground-dwelling monsters; opposes WIND."),
        .wind: SymbolInfo(label: "WIND", ja: "風", meaning: "Wind attribute — flying and air monsters; opposes EARTH."),
        .divine: SymbolInfo(label: "DIVINE", ja: "神", meaning: "Divine attribute — the Egyptian God cards."),
    ]

    public static let spells: [String: SymbolInfo] = [
        "Normal": SymbolInfo(label: "Normal Spell", ja: "通常魔法", meaning: "Resolves once, then goes to the Graveyard."),
        "Quick-Play": SymbolInfo(label: "Quick-Play Spell", ja: "速攻魔法", meaning: "Can be played from the hand at fast timing, even on the opponent's turn."),
        "Continuous": SymbolInfo(label: "Continuous Spell", ja: "永続魔法", meaning: "Stays on the field and keeps its effect active."),
        "Equip": SymbolInfo(label: "Equip Spell", ja: "装備魔法", meaning: "Attaches to a monster to change its stats or grant an effect."),
        "Field": SymbolInfo(label: "Field Spell", ja: "フィールド魔法", meaning: "Fills the field zone and affects the whole board."),
        "Ritual": SymbolInfo(label: "Ritual Spell", ja: "儀式魔法", meaning: "Used to Ritual Summon a Ritual Monster."),
    ]

    public static let traps: [String: SymbolInfo] = [
        "Normal": SymbolInfo(label: "Normal Trap", ja: "通常罠", meaning: "Set first, then activated on a later turn."),
        "Continuous": SymbolInfo(label: "Continuous Trap", ja: "永続罠", meaning: "Stays on the field and keeps its effect active."),
        "Counter": SymbolInfo(label: "Counter Trap", ja: "カウンター罠", meaning: "A fast trap that negates or responds to other cards."),
    ]

    /// SF Symbol name approximating the sub-type icon printed inline in the type line.
    /// Normal spells/traps have no icon.
    public static func subtypeSFSymbol(_ spellTrapType: String?) -> String? {
        switch spellTrapType {
        case "Quick-Play": return "bolt.fill"
        case "Continuous": return "infinity"
        case "Equip": return "plus"
        case "Field": return "arrow.up.and.down.and.arrow.left.and.right"
        case "Ritual": return "flame.fill"
        case "Counter": return "arrow.uturn.backward"
        default: return nil
        }
    }
}
