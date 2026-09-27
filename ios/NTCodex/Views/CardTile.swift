import SwiftUI
import NTCodexCore

/// Grid columns shared by every screen that lays out `CardTile`s.
enum CardGrid {
    static let columns: [GridItem] = [GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 10)]
}

/// A single card's grid tile: art with an English-name strip, reading and
/// Japanese name below. Port of `makeTile()` in app/browse.js.
struct CardTile: View {
    let card: Card

    init(card: Card) {
        self.card = card
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                RemoteImage(url: card.imageURL, contentMode: .fill) {
                    ZStack {
                        Theme.panel2
                        Text("No image")
                            .font(Theme.display(8))
                            .foregroundStyle(Theme.ink3)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .aspectRatio(59.0 / 86.0, contentMode: .fit)
                .clipped()

                Text(card.en)
                    .font(Theme.display(9))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.65))
            }

            VStack(alignment: .leading, spacing: 1) {
                if card.showsReading {
                    Text(card.reading)
                        .font(Theme.jp(9))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Text(card.ja.isEmpty ? (card.en.isEmpty ? "—" : card.en) : card.ja)
                    .font(Theme.jp(12, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 32, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 6, leading: 8, bottom: 8, trailing: 8))
            .background(Theme.panel2)
        }
        .background(Theme.panelGradient)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.frameColor(card), lineWidth: 2)
        )
    }
}
