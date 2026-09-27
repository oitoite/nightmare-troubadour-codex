import SwiftUI
import NTCodexCore

/// Cards tab: search, filters, sort and the results grid. Port of browse.js.
struct BrowseView: View {
    @Environment(AppModel.self) private var model
    @State private var query = CardQuery()
    @State private var showFilters = false
    @State private var results: [Card] = []
    @State private var hasComputed = false

    @State private var atkMin = ""
    @State private var atkMax = ""
    @State private var defMin = ""
    @State private var defMax = ""

    private struct RecomputeKey: Hashable {
        var query: CardQuery
        var loaded: Bool
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchPanel
                toolbarRow
                resultsGrid
            }
            .padding(16)
        }
        .codexScreen()
        .toolbar {
            ToolbarItem(placement: .principal) { BrandHeader() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: RecomputeKey(query: query, loaded: model.db != nil)) {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            guard let db = model.db else {
                results = []
                return
            }
            let q = query
            let computed = await Task.detached(priority: .userInitiated) {
                q.apply(to: db)
            }.value
            guard !Task.isCancelled else { return }
            results = computed
            hasComputed = true
        }
    }

    // MARK: Search panel

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                searchField
                modeMenu
                filtersButton
            }
            if showFilters {
                Rectangle().fill(Theme.line).frame(height: 1)
                filterPanel
            }
        }
        .panel()
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            TextField("Search cards — 日本語 or English", text: $query.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(Theme.ink)
            if !query.text.isEmpty {
                Button {
                    query.text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.ink3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(11)
        .background(Theme.panel2)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.frame, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .frame(maxWidth: .infinity)
    }

    private var modeMenu: some View {
        Menu {
            ForEach(CardQuery.Mode.allCases, id: \.self) { m in
                Button(m.label) { query.mode = m }
            }
        } label: {
            Text(query.mode.label)
                .font(Theme.display(12))
                .foregroundStyle(Theme.gold)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .background(Theme.panel2)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.frame, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }

    private var filtersButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { showFilters.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text("Filters")
                if query.activeFilterCount > 0 {
                    Text("\(query.activeFilterCount)")
                        .font(Theme.display(9, bold: true))
                        .foregroundStyle(Theme.panel)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Theme.gold))
                }
                Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
            }
        }
        .buttonStyle(OutlineButtonStyle())
    }

    // MARK: Filter panel

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            typeStrip
            attributeRow
            if query.cardType != .spell && query.cardType != .trap {
                raceRow
                categoryRow
            }
            levelRow
            statRow
            packRow
            if query.hasActiveFilters {
                HStack {
                    Spacer()
                    Button("Clear all filters") {
                        query.clearFilters()
                        atkMin = ""; atkMax = ""; defMin = ""; defMax = ""
                    }
                    .buttonStyle(OutlineButtonStyle())
                    Spacer()
                }
            }
        }
    }

    private var typeStrip: some View {
        HStack(spacing: 0) {
            typeButton(nil, label: "All")
            typeButton(.monster, label: "Monster")
            typeButton(.spell, label: "Spell")
            typeButton(.trap, label: "Trap")
        }
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line2, lineWidth: 1))
    }

    private func typeButton(_ type: CardType?, label: String) -> some View {
        let active = query.cardType == type
        return Button {
            query.cardType = type
        } label: {
            Text(label)
                .font(Theme.display(12, bold: active))
                .foregroundStyle(active ? Theme.gold : Theme.ink2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(active ? Theme.gold : Color.clear)
                        .frame(height: 2)
                }
        }
        .buttonStyle(.plain)
    }

    private var attributeRow: some View {
        filterRow(label: "Attribute", isActive: !query.attributes.isEmpty, clear: { query.attributes = [] }) {
            chipsGrid {
                ForEach(Attribute.allCases, id: \.self) { attr in
                    attributeChip(attr)
                }
            }
        }
    }

    private func attributeChip(_ attr: Attribute) -> some View {
        let isOn = query.attributes.contains(attr)
        return Button {
            if isOn { query.attributes.remove(attr) } else { query.attributes.insert(attr) }
        } label: {
            HStack(spacing: 6) {
                AttributeBadge(attribute: attr, size: 14)
                Text(attr.labelEn)
                    .lineLimit(1)
            }
            .font(Theme.jp(12))
            .foregroundStyle(isOn ? Theme.gold : Theme.ink2)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isOn ? Theme.gold.opacity(0.14) : Theme.panel2)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(isOn ? Theme.gold : Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private var raceRow: some View {
        filterRow(label: "Monster Type", isActive: !query.races.isEmpty, clear: { query.races = [] }) {
            chipsGrid {
                ForEach(model.db?.races ?? [], id: \.self) { race in
                    FilterChip(race, isOn: query.races.contains(race)) {
                        if query.races.contains(race) { query.races.remove(race) } else { query.races.insert(race) }
                    }
                }
            }
        }
    }

    private var categoryRow: some View {
        filterRow(label: "Card Type", isActive: !query.categories.isEmpty, clear: { query.categories = [] }) {
            chipsGrid {
                ForEach(model.db?.categories ?? [], id: \.self) { cat in
                    FilterChip(cat, isOn: query.categories.contains(cat)) {
                        if query.categories.contains(cat) { query.categories.remove(cat) } else { query.categories.insert(cat) }
                    }
                }
            }
        }
    }

    private var levelRow: some View {
        filterRow(label: "Level / Rank", isActive: !query.levels.isEmpty, clear: { query.levels = [] }) {
            chipsGrid(minWidth: 44) {
                ForEach(Array(0...12), id: \.self) { lvl in
                    FilterChip("\(lvl)", isOn: query.levels.contains(lvl)) {
                        if query.levels.contains(lvl) { query.levels.remove(lvl) } else { query.levels.insert(lvl) }
                    }
                }
            }
        }
    }

    private var statRow: some View {
        let isActive = query.atkMin != nil || query.atkMax != nil || query.defMin != nil || query.defMax != nil
        return filterRow(label: "ATK / DEF", isActive: isActive, clear: {
            atkMin = ""; atkMax = ""; defMin = ""; defMax = ""
            query.atkMin = nil; query.atkMax = nil; query.defMin = nil; query.defMax = nil
        }) {
            HStack(spacing: 8) {
                Text("ATK").font(Theme.jp(12)).foregroundStyle(Theme.ink2)
                numField(placeholder: "min", text: $atkMin) { query.atkMin = Int($0) }
                Text("–").foregroundStyle(Theme.ink2)
                numField(placeholder: "max", text: $atkMax) { query.atkMax = Int($0) }
                Text("DEF").font(Theme.jp(12)).foregroundStyle(Theme.ink2).padding(.leading, 8)
                numField(placeholder: "min", text: $defMin) { query.defMin = Int($0) }
                Text("–").foregroundStyle(Theme.ink2)
                numField(placeholder: "max", text: $defMax) { query.defMax = Int($0) }
            }
        }
    }

    private func numField(placeholder: String, text: Binding<String>, onChange: @escaping (String) -> Void) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .font(Theme.jp(12))
            .foregroundStyle(Theme.ink)
            .padding(8)
            .frame(width: 56)
            .background(Theme.panel2)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.frame, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .onChange(of: text.wrappedValue) { _, newValue in
                onChange(newValue)
            }
    }

    private var packRow: some View {
        filterRow(label: "Pack · パック", isActive: query.pack != nil, clear: { query.pack = nil }) {
            Menu {
                Button("All packs") { query.pack = nil }
                ForEach(model.db?.packs ?? []) { p in
                    Button(p.pickerLabel) { query.pack = p.name }
                }
            } label: {
                HStack {
                    Text(query.pack.flatMap { model.db?.pack(named: $0)?.pickerLabel } ?? "All packs")
                        .font(Theme.jp(12))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.ink3)
                }
                .padding(10)
                .background(Theme.panel2)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.frame, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }

    // MARK: Small helpers

    private func filterRow<Content: View>(
        label: String,
        isActive: Bool,
        clear: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionLabel(label)
                if isActive {
                    Button(action: clear) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.ink3)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            content()
        }
    }

    private func chipsGrid<Content: View>(minWidth: CGFloat = 100, @ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth), spacing: 6)], alignment: .leading, spacing: 6) {
            content()
        }
    }

    // MARK: Toolbar + results

    private var toolbarRow: some View {
        HStack {
            countText
            Spacer()
            sortMenu
        }
    }

    private var countText: some View {
        let total = model.db?.cards.count ?? 0
        return (
            Text("\(results.count)").fontWeight(.bold).foregroundStyle(Theme.ink)
            + Text(" of \(total) cards").foregroundStyle(Theme.ink2)
        )
        .font(Theme.jp(12))
    }

    private var sortMenu: some View {
        Menu {
            ForEach(CardQuery.Sort.allCases, id: \.self) { s in
                Button(s.label) { query.sort = s }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Sort").font(Theme.jp(12)).foregroundStyle(Theme.ink2)
                Text(query.sort.label).font(Theme.jp(12, weight: .medium)).foregroundStyle(Theme.gold)
                Image(systemName: "chevron.down").font(.system(size: 9)).foregroundStyle(Theme.ink3)
            }
        }
    }

    private var resultsGrid: some View {
        Group {
            if results.isEmpty {
                if hasComputed { emptyState }
            } else {
                LazyVGrid(columns: CardGrid.columns, spacing: 10) {
                    ForEach(results) { card in
                        NavigationLink(value: Route.card(card)) {
                            CardTile(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No cards found").font(Theme.display(16)).foregroundStyle(Theme.gold)
            Text("Try fewer filters or a shorter search.").font(Theme.jp(13)).foregroundStyle(Theme.ink2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
