import SwiftUI
import NTCodexCore

/// Dictionary tab: effect-text vocabulary and game terms. Port of dictionary.js.
struct DictionaryView: View {
    @Environment(AppModel.self) private var model
    @State private var mode: DictionaryMode = .words
    @State private var text = ""
    @State private var all: [DictionaryEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                content
            }
        }
        .navigationTitle("Dictionary")
        .codexScreen()
        .task(id: mode) {
            guard let db = model.db else { return }
            all = CardDictionary.entries(mode: mode, db: db)
        }
        .task(id: model.db?.cards.count) {
            guard let db = model.db else { return }
            all = CardDictionary.entries(mode: mode, db: db)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            modeSwitch
            searchField
            Text(CardDictionary.hint(mode: mode, count: all.count))
                .font(Theme.jp(11))
                .foregroundStyle(Theme.ink3)
        }
        .panel()
        .padding(16)
    }

    private var modeSwitch: some View {
        HStack(spacing: 0) {
            modeButton(.words, label: "Effect words")
            modeButton(.game, label: "Game terms")
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line2, lineWidth: 1))
        .fixedSize(horizontal: true, vertical: false)
    }

    private func modeButton(_ m: DictionaryMode, label: String) -> some View {
        let active = mode == m
        return Button {
            mode = m
            text = ""
        } label: {
            Text(label)
                .font(Theme.display(12, bold: active))
                .foregroundStyle(active ? Theme.gold : Theme.ink3)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(active ? Theme.gold.opacity(0.18) : Theme.panel2)
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            TextField("Search in Japanese or English…", text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(Theme.ink)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.ink3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(11)
        .background(Theme.panel2)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.frame, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    @ViewBuilder
    private var content: some View {
        let shown = CardDictionary.filter(all, query: text)
        let sections = CardDictionary.sections(shown)
        if sections.isEmpty {
            Text("No results")
                .font(Theme.display(16))
                .foregroundStyle(Theme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
        } else {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    Section {
                        ForEach(Array(section.entries.enumerated()), id: \.offset) { _, entry in
                            row(entry)
                        }
                    } header: {
                        sectionHeader(section.title)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.display(12, bold: true))
            .foregroundStyle(Theme.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Theme.panel2)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.line).frame(height: 1)
            }
    }

    private func row(_ entry: DictionaryEntry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.ja)
                .font(Theme.jp(14, weight: .medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
            Text(entry.displayReading)
                .font(Theme.jp(12))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
            Text(entry.en)
                .font(Theme.jp(12))
                .foregroundStyle(Theme.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line2).frame(height: 0.5)
        }
    }
}
