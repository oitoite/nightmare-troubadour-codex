import SwiftUI
import NTCodexCore

/// The app's root: a loading/error gate in front of the four-tab shell.
struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if model.isLoading {
                loadingView
            } else if let message = model.loadError {
                errorView(message)
            } else {
                tabs
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.gold)
            Text("Opening the database…")
                .font(Theme.display(13))
                .foregroundStyle(Theme.gold2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.pageBackground)
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView(
            "Card data unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.pageBackground)
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                BrowseView()
                    .codexDestinations()
            }
            .tabItem { Label("Cards", systemImage: "magnifyingglass") }

            NavigationStack {
                PacksView()
                    .codexDestinations()
            }
            .tabItem { Label("Packs", systemImage: "square.grid.2x2") }

            NavigationStack {
                MyCardsView()
                    .codexDestinations()
            }
            .tabItem { Label("My Cards", systemImage: "star") }

            NavigationStack {
                DictionaryView()
                    .codexDestinations()
            }
            .tabItem { Label("Dictionary", systemImage: "character.book.closed") }
        }
        .tint(Theme.gold)
        .toolbarBackground(Theme.panel2, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

/// Compact banner used as the Browse tab's navigation-title content.
struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Text("遊戯王")
                    .font(Theme.jp(13, weight: .bold))
                    .foregroundStyle(Theme.gold)
                Text("NIGHTMARE TROUBADOUR")
                    .font(Theme.display(13, bold: true))
                    .foregroundStyle(.white)
            }
            Text("ナイトメア・トラバドール · Japanese OCG Card Database")
                .font(Theme.jp(10))
                .foregroundStyle(Theme.ink2)
        }
    }
}
