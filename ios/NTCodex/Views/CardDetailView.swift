import SwiftUI
import NTCodexCore

/// Wraps a `VocabWord` so it can be used with `.sheet(item:)` (VocabWord itself
/// isn't Identifiable, and two lookups of the same word should still be able
/// to re-open the sheet).
private struct VocabSheetItem: Identifiable {
    let id = UUID()
    let word: VocabWord
}

/// Full card detail screen — a native port of `detail.js` / the `.cardface`
/// card-shaped panel from the web app.
struct CardDetailView: View {
    let card: Card

    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    @State private var symbol: SymbolInfo?
    @State private var peeked: Set<Int> = []
    @State private var vocabWord: VocabSheetItem?

    init(card: Card) {
        self.card = card
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                toolbarRow
                artView
                cardFacePanel
                packsSection
                linksSection
                saveButton
            }
            .padding(16)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(card.en)
        .navigationBarTitleDisplayMode(.inline)
        .codexScreen()
        .sheet(isPresented: symbolSheetBinding) {
            if let symbol {
                SymbolPopover(info: symbol)
                    .presentationDetents([.height(180)])
            }
        }
        .sheet(item: $vocabWord) { item in
            vocabSheetContent(item.word)
        }
    }

    private var symbolSheetBinding: Binding<Bool> {
        Binding(get: { symbol != nil }, set: { if !$0 { symbol = nil } })
    }

    // MARK: Toolbar (language + furigana — app tools, not on the card face)

    private var hasEffectText: Bool { !card.jpEff.isEmpty || !card.enEff.isEmpty }

    @ViewBuilder
    private var toolbarRow: some View {
        if hasEffectText {
            HStack(spacing: 12) {
                if !card.jpEff.isEmpty, !card.enEff.isEmpty {
                    languagePicker
                }
                if !card.jpEff.isEmpty {
                    furiganaToggle
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var languagePicker: some View {
        Picker("Language", selection: languageBinding) {
            ForEach(EffectLanguage.allCases, id: \.self) { lang in
                Text(lang.label).tag(lang)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 180)
        .labelsHidden()
    }

    private var languageBinding: Binding<EffectLanguage> {
        Binding(get: { model.language }, set: { model.language = $0 })
    }

    private var furiganaToggle: some View {
        Button {
            model.furigana.toggle()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(model.furigana ? Theme.gold : Color.clear)
                    .overlay(Circle().stroke(model.furigana ? Theme.gold : Theme.ink3, lineWidth: 1))
                    .frame(width: 8, height: 8)
                Text("ふりがな")
                    .font(Theme.jp(12))
            }
            .foregroundStyle(model.furigana ? Theme.gold : Theme.ink3)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(model.furigana ? Theme.gold.opacity(0.14) : Theme.panel2))
            .overlay(Capsule().stroke(model.furigana ? Theme.frame2 : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Art

    private var artView: some View {
        RemoteImage(url: card.imageURL, contentMode: .fit) {
            ZStack {
                Theme.panel
                Text("No image")
                    .font(Theme.jp(12))
                    .foregroundStyle(Theme.ink3)
            }
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
        .frame(maxWidth: 300)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.frameColor(card), lineWidth: 2))
        .frame(maxWidth: .infinity)
    }

    // MARK: Card face

    private var cardFacePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
            if card.isMonster {
                monsterBody
            } else {
                spellTrapBody
            }
            if let passcode = card.passcode, !passcode.isEmpty {
                Text(passcode)
                    .font(Theme.display(10))
                    .foregroundStyle(Theme.ink3)
                    .padding(.top, 8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.frameColor(card), lineWidth: 3))
    }

    private var displayJa: String {
        if !card.ja.isEmpty { return card.ja }
        return card.en.isEmpty ? "—" : card.en
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                RubyNameView(ja: displayJa, reading: card.showsReading ? card.reading : nil, fontSize: 22)
                Text(card.en)
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink2)
            }
            Spacer(minLength: 8)
            badgeView
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        if card.isMonster {
            if let attribute = card.attribute {
                Button {
                    symbol = Symbols.info(for: .attribute(attribute))
                } label: {
                    AttributeBadge(attribute: attribute, size: 40)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button {
                let kind: SymbolKind = card.cardType == .spell
                    ? .spell(card.spellTrapType ?? "Normal")
                    : .trap(card.spellTrapType ?? "Normal")
                symbol = Symbols.info(for: kind)
            } label: {
                SpellTrapBadge(cardType: card.cardType, size: 40)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Monster layout

    @ViewBuilder
    private var monsterBody: some View {
        if let level = card.level {
            HStack {
                Spacer()
                Button {
                    symbol = Symbols.info(for: .level(level))
                } label: {
                    LevelStars(level: level, fontSize: 16)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
            .padding(.bottom, 2)
        }
        monsterTextBox
            .padding(.vertical, 8)
        if card.atk != nil || card.def != nil {
            VStack(spacing: 8) {
                Divider().overlay(Theme.line)
                HStack(spacing: 24) {
                    Spacer()
                    adText("ATK", card.atk)
                    adText("DEF", card.def)
                }
            }
            .font(Theme.display(14))
            .foregroundStyle(Theme.ink)
            .padding(.top, 4)
        }
    }

    private func adText(_ label: String, _ value: Int?) -> Text {
        Text(label)
            + Text("/").foregroundColor(Color(hex: "#8a1a1a"))
            + Text(" " + (value.map(String.init) ?? "?"))
    }

    private var monsterTypeLineBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            RubyTextView(
                segments: RubyHTML.parse(card.typeLineJaHtml ?? card.typeLineJa),
                showFurigana: model.furigana, fontSize: 14, onVocabTap: nil
            )
            .fontWeight(.semibold)
            Text(card.typeLineEn)
                .font(Theme.display(11))
                .foregroundStyle(Theme.ink2)
        }
    }

    private var monsterTextBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            monsterTypeLineBlock
            effectBody
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Spell/Trap layout

    @ViewBuilder
    private var spellTrapBody: some View {
        typeLineRow
            .padding(.top, 4)
        Text(card.spellTrapLabelEn)
            .font(Theme.display(11))
            .foregroundStyle(Theme.ink2)
            .frame(maxWidth: .infinity, alignment: .trailing)
        if hasEffectText {
            spellTrapTextBox
                .padding(.top, 8)
        }
    }

    private var typeLineRow: some View {
        HStack(spacing: 3) {
            Spacer(minLength: 0)
            Text("【")
                .font(Theme.jp(14, weight: .bold))
                .foregroundStyle(Theme.gold)
            RubyTextView(
                segments: RubyHTML.parse(card.typeLineJaHtml ?? card.typeLineJa),
                showFurigana: model.furigana, fontSize: 14, onVocabTap: nil
            )
            .fontWeight(.semibold)
            SubtypeIcon(spellTrapType: card.spellTrapType, size: 16)
            Text("】")
                .font(Theme.jp(14, weight: .bold))
                .foregroundStyle(Theme.gold)
        }
    }

    private var spellTrapTextBox: some View {
        effectBody
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Effect body (JP/EN, with sentence-level EN peek)

    @ViewBuilder
    private var effectBody: some View {
        if model.language == .en {
            if !card.enEff.isEmpty {
                Text(card.enEff)
                    .font(Theme.jp(14))
                    .foregroundStyle(Theme.ink)
            }
        } else if !card.jpEff.isEmpty {
            jpEffectBody
        }
    }

    @ViewBuilder
    private var jpEffectBody: some View {
        let segments = RubyHTML.parse(card.jpEffHtml ?? card.jpEff)
        let sentences = RubyHTML.sentences(segments)
        if let enParts = SentenceAligner.align(jpSentences: sentences, en: card.enEff) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentenceSegments in
                    sentenceRow(index: index, segments: sentenceSegments, enParts: enParts)
                }
            }
        } else {
            RubyTextView(segments: segments, showFurigana: model.furigana, fontSize: 14, onVocabTap: handleVocabTap)
        }
    }

    private func sentenceRow(index: Int, segments: [RubySegment], enParts: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RubyTextView(segments: segments, showFurigana: model.furigana, fontSize: 14, onVocabTap: handleVocabTap)
                .contentShape(Rectangle())
                .onTapGesture {
                    if peeked.contains(index) { peeked.remove(index) } else { peeked.insert(index) }
                }
            if peeked.contains(index), index < enParts.count {
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(Theme.gold).frame(width: 2)
                    Text(enParts[index])
                        .font(Theme.jp(13))
                        .foregroundStyle(Theme.ink2)
                }
            }
        }
    }

    private func handleVocabTap(_ word: String) {
        if let w = model.db?.vocab(for: word) {
            vocabWord = VocabSheetItem(word: w)
        }
    }

    private func vocabSheetContent(_ word: VocabWord) -> some View {
        VStack(spacing: 10) {
            Text(word.ja)
                .font(Theme.jp(28, weight: .bold))
                .foregroundStyle(Theme.ink)
            if let reading = word.reading, !reading.isEmpty, reading != word.ja {
                Text(reading)
                    .font(Theme.jp(15))
                    .foregroundStyle(Theme.gold)
            }
            Text(word.en ?? "—")
                .font(Theme.jp(15))
                .foregroundStyle(Theme.ink2)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(220)])
    }

    // MARK: Packs

    @ViewBuilder
    private var packsSection: some View {
        if !card.packs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("収録パック · In packs")
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(Array(card.packs.enumerated()), id: \.offset) { _, entry in
                        NavigationLink(value: Route.pack(entry.pack)) {
                            packChip(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func packChip(_ entry: PackEntry) -> some View {
        HStack(spacing: 4) {
            Text(entry.pack)
            if let ja = model.db?.pack(named: entry.pack)?.ja, !ja.isEmpty {
                Text(ja).fontWeight(.bold)
            }
            if let rarity = entry.rarity, !rarity.isEmpty {
                Text(rarity).italic().foregroundStyle(Theme.ink3)
            }
        }
        .font(Theme.jp(12))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Links

    private var externalLinks: [(label: String, url: URL)] {
        var out: [(label: String, url: URL)] = []
        if let u = card.ygoResourcesJaURL { out.append(("YGOResources 日本語", u)) }
        if let u = card.ygoResourcesEnURL { out.append(("YGOResources EN", u)) }
        if let u = card.yugipediaURL { out.append(("Yugipedia", u)) }
        return out
    }

    @ViewBuilder
    private var linksSection: some View {
        let links = externalLinks
        if !links.isEmpty {
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(Array(links.enumerated()), id: \.offset) { _, item in
                    Button(item.label) { openURL(item.url) }
                        .buttonStyle(OutlineButtonStyle())
                }
            }
        }
    }

    // MARK: Save

    private var saveButton: some View {
        Group {
            if model.myCards.isSaved(card) {
                Button("✓ In My Cards") {}
                    .buttonStyle(GoldButtonStyle())
                    .disabled(true)
            } else {
                Button("✦ Save to My Cards") {
                    model.myCards.save(card)
                }
                .buttonStyle(GoldButtonStyle())
            }
        }
    }
}
