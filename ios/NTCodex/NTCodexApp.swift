import SwiftUI
import CoreText
import UIKit
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
/// the fonts landing in a subfolder of the bundle. Skipped when the fonts are
/// already available so CoreText doesn't log a duplicate-registration error.
enum FontRegistrar {
    static func registerBundledFonts() {
        guard UIFont(name: "Cinzel-Medium", size: 12) == nil || UIFont(name: "Cinzel-Bold", size: 12) == nil else {
            return
        }
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
