import SwiftUI
import NTCodexCore

/// My Cards tab: saved cards with personal notes. Port of mycards.js.
struct MyCardsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            if model.myCards.savedCards.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(model.myCards.savedCards) { saved in
                        SavedCardRow(saved: saved)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("My Cards")
        .codexScreen()
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No saved cards").font(Theme.display(16)).foregroundStyle(Theme.gold)
            Text("Save cards from Card Search to collect them here.")
                .font(Theme.jp(13))
                .foregroundStyle(Theme.ink2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct SavedCardRow: View {
    let saved: SavedCard
    @Environment(AppModel.self) private var model
    @State private var note: String

    init(saved: SavedCard) {
        self.saved = saved
        _note = State(initialValue: saved.userNote)
    }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(value: Route.card(saved.card)) {
                HStack(alignment: .top, spacing: 12) {
                    RemoteImage(url: saved.card.imageURL, contentMode: .fill) {
                        Theme.panel2
                    }
                    .aspectRatio(59.0 / 86.0, contentMode: .fit)
                    .frame(width: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Theme.frameColor(saved.card), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        RubyNameView(
                            ja: saved.card.ja,
                            reading: saved.card.showsReading ? saved.card.reading : nil,
                            fontSize: 18
                        )
                        Text(saved.card.en)
                            .font(Theme.display(12))
                            .foregroundStyle(Theme.ink2)
                        if saved.card.isMonster {
                            HStack(spacing: 8) {
                                if let attr = saved.card.attribute {
                                    AttributeBadge(attribute: attr, size: 22)
                                }
                                if let level = saved.card.level {
                                    LevelStars(level: level, fontSize: 12)
                                }
                                Text("ATK \(saved.card.atk.map { "\($0)" } ?? "?") / DEF \(saved.card.def.map { "\($0)" } ?? "?")")
                                    .font(Theme.display(11))
                                    .foregroundStyle(Theme.ink)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            if !saved.card.jpEff.isEmpty || !saved.card.enEff.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("効果テキスト · Card Text")
                    HStack {
                        if !saved.card.jpEff.isEmpty, !saved.card.enEff.isEmpty {
                            HStack(spacing: 0) {
                                Button {
                                    model.language = .jp
                                } label: {
                                    Text("日本語")
                                        .font(Theme.jp(11))
                                        .foregroundStyle(model.language == .jp ? Theme.gold : Theme.ink3)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    model.language = .en
                                } label: {
                                    Text("English")
                                        .font(Theme.jp(11))
                                        .foregroundStyle(model.language == .en ? Theme.gold : Theme.ink3)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        Spacer()
                        Toggle(isOn: $model.furigana) {
                            Text("Furigana").font(Theme.jp(11)).foregroundStyle(Theme.ink3)
                        }
                        .toggleStyle(.button)
                        .tint(Theme.gold)
                    }

                    if model.language == .jp, !saved.card.jpEff.isEmpty {
                        RubyTextView(
                            segments: RubyHTML.parse(saved.card.jpEffHtml ?? saved.card.jpEff),
                            showFurigana: model.furigana,
                            fontSize: 13,
                            onVocabTap: nil
                        )
                    } else if !saved.card.enEff.isEmpty {
                        Text(saved.card.enEff)
                            .font(Theme.jp(13))
                            .foregroundStyle(Theme.ink)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                SectionLabel("My note")
                TextField("Add your own note…", text: $note, axis: .vertical)
                    .lineLimit(2...6)
                    .font(Theme.jp(13))
                    .foregroundStyle(Theme.ink)
                    .padding(10)
                    .background(Theme.panel2)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            Button("Remove") {
                model.myCards.remove(saved.card)
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .panel()
        .onChange(of: note) { _, newValue in
            model.myCards.updateNote(for: saved.card, note: newValue)
        }
    }
}
