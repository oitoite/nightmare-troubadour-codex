import SwiftUI
import NTCodexCore

/// Navigation destinations shared by every tab's NavigationStack.
enum Route: Hashable {
    case card(Card)
    case pack(String)
}

extension View {
    /// Registers the app's navigation destinations on a NavigationStack.
    func codexDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .card(let card): CardDetailView(card: card)
            case .pack(let name): PackDetailView(packName: name)
            }
        }
    }
}
