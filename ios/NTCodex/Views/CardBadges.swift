import SwiftUI
import NTCodexCore

/// Monster attribute medallion: the official icon when it loads, else a drawn
/// circular badge in the attribute's colour with its kanji.
struct AttributeBadge: View {
    let attribute: Attribute
    let size: CGFloat

    init(attribute: Attribute, size: CGFloat) {
        self.attribute = attribute
        self.size = size
    }

    var body: some View {
        RemoteImage(url: attribute.iconURL, contentMode: .fit) {
            drawnBadge
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var drawnBadge: some View {
        ZStack {
            Circle().fill(Theme.attributeColor(attribute))
            Circle().strokeBorder(Theme.gold, lineWidth: 1.5)
            Text(attribute.kanji)
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

/// Spell/Trap type medallion (魔/罠), drawn natively — the physical card always
/// shows this, there is no remote icon to fetch.
struct SpellTrapBadge: View {
    let cardType: CardType
    let size: CGFloat

    init(cardType: CardType, size: CGFloat) {
        self.cardType = cardType
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle().fill(cardType == .spell ? Color(hex: "#1d9e75") : Color(hex: "#c2185b"))
            Circle().strokeBorder(Color.white, lineWidth: 1.5)
            Text(cardType.kanji)
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Small inline icon for a spell/trap sub-type (Quick-Play, Continuous, …), or
/// nothing for a Normal spell/trap (which prints no icon on the real card).
struct SubtypeIcon: View {
    let spellTrapType: String?
    let size: CGFloat

    init(spellTrapType: String?, size: CGFloat) {
        self.spellTrapType = spellTrapType
        self.size = size
    }

    var body: some View {
        if let symbol = Symbols.subtypeSFSymbol(spellTrapType) {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Theme.ink3, lineWidth: 1)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.6))
                        .foregroundStyle(Theme.ink2)
                )
        } else {
            EmptyView()
        }
    }
}

/// Level stars (★★★…) plus a small "Lv.N" caption, as printed on a monster card.
struct LevelStars: View {
    let level: Int
    let fontSize: CGFloat

    init(level: Int, fontSize: CGFloat) {
        self.level = level
        self.fontSize = fontSize
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(level > 0 ? String(repeating: "★", count: level) : "0")
                .font(.system(size: fontSize))
                .foregroundStyle(Color(hex: "#e0a83a"))
            Text("Lv.\(level)")
                .font(Theme.jp(fontSize * 0.65))
                .foregroundStyle(Theme.ink2)
        }
    }
}

/// The tap-to-define popup content for a symbol (attribute, level, spell/trap
/// type). Presented from a sheet with a fixed detent by the caller.
struct SymbolPopover: View {
    let info: SymbolInfo

    init(info: SymbolInfo) {
        self.info = info
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(info.label)
                .font(Theme.display(13, bold: true))
                .foregroundStyle(Theme.gold)
            Text(info.ja)
                .font(Theme.jp(15))
                .foregroundStyle(Theme.ink)
            Text(info.meaning)
                .font(Theme.jp(13))
                .foregroundStyle(Theme.ink2)
        }
        .padding(14)
        .frame(maxWidth: 280, alignment: .leading)
        .background(Theme.panelGradient)
        .frame(maxWidth: .infinity)
    }
}
