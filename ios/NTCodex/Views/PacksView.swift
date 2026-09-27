import SwiftUI
import NTCodexCore

/// Packs tab: the booster-pack gallery. Port of packs.js renderPacks().
struct PacksView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("The game's 23 booster packs. Tap one to see its cards by rarity.")
                    .font(Theme.jp(13))
                    .foregroundStyle(Theme.ink2)

                if let db = model.db {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(db.packs.filter { !$0.name.isEmpty }) { pack in
                            NavigationLink(value: Route.pack(pack.name)) {
                                PackTile(pack: pack, count: db.cards(inPack: pack.name).count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Packs")
        .navigationBarTitleDisplayMode(.inline)
        .codexScreen()
    }
}

private struct PackTile: View {
    let pack: Pack
    let count: Int

    var body: some View {
        HStack(spacing: 13) {
            RemoteImage(url: pack.imageURL, contentMode: .fit) {
                ZStack {
                    Theme.panel2
                    Text("❖")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.gold2)
                        .opacity(0.6)
                }
            }
            .frame(width: 48, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 3) {
                Text(pack.displayJa)
                    .font(Theme.jp(13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(pack.name)
                    .font(Theme.display(10))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)
                Text("\(count) cards")
                    .font(Theme.jp(11))
                    .foregroundStyle(Theme.ink3)
            }
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
        .background(Theme.panelGradient)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
    }
}

/// A single rarity group within a pack, made Identifiable for `ForEach`.
private struct RarityGroup: Identifiable {
    let rarity: String
    let cards: [Card]
    var id: String { rarity }
}

/// A pack's cards grouped by rarity. Port of packs.js renderPackCards().
struct PackDetailView: View {
    let packName: String
    @Environment(AppModel.self) private var model

    init(packName: String) {
        self.packName = packName
    }

    var body: some View {
        let pack = model.db?.pack(named: packName)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(pack: pack)

                if let db = model.db {
                    let groups = db.cardsByRarity(inPack: packName).map {
                        RarityGroup(rarity: $0.rarity, cards: $0.cards)
                    }
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            rarityHeader(group.rarity, count: group.cards.count)
                            LazyVGrid(columns: CardGrid.columns, spacing: 10) {
                                ForEach(group.cards) { card in
                                    NavigationLink(value: Route.card(card)) {
                                        CardTile(card: card)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(pack?.displayJa ?? packName)
        .navigationBarTitleDisplayMode(.inline)
        .codexScreen()
    }

    @ViewBuilder
    private func header(pack: Pack?) -> some View {
        let count = model.db?.cards(inPack: packName).count ?? 0
        HStack(alignment: .top, spacing: 16) {
            if let pack, pack.imageURL != nil {
                RemoteImage(url: pack.imageURL, contentMode: .fit) {
                    Color.clear
                }
                .frame(maxHeight: 120)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(pack?.displayJa ?? packName)
                    .font(Theme.jp(20, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(packName) · \(count) cards")
                    .font(Theme.display(11))
                    .foregroundStyle(Theme.ink2)
            }
        }
    }

    private func rarityHeader(_ rarity: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(rarity)
                .font(Theme.display(12, bold: true))
                .foregroundStyle(Theme.gold)
            Text("\(count)")
                .font(Theme.jp(11))
                .foregroundStyle(Theme.ink3)
            Spacer()
        }
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }
}
