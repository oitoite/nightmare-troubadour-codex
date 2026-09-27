import SwiftUI
import CoreText
import NTCodexCore

@main
struct NTCodexApp: App {
    @State private var model = AppModel()

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .preferredColorScheme(.dark)
                .task { await model.load() }
        }
    }
}

/// Registers the bundled Cinzel fonts at launch. `UIAppFonts` in Info.plist
/// normally handles this; registering here as well makes the app resilient to
/// the fonts landing in a subfolder of the bundle.
enum FontRegistrar {
    static func registerBundledFonts() {
        var urls: [URL] = []
        for sub in [nil, "Fonts", "Resources/Fonts"] {
            urls += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: sub) ?? []
        }
        for url in urls {
            // Errors here are expected when UIAppFonts already registered the font.
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
