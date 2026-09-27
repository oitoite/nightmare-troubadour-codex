# NT Codex iOS

Native iOS port of the Nightmare Troubadour card codex web app.

## What is this?

This is a SwiftUI app for iOS that provides a native interface to browse, search, and collect Yu-Gi-Oh! cards from the Nightmare Troubadour card game. It's a port of the web app at the repo root.

## Requirements

- **Xcode 16 or later**
- **iOS 17 or later**
- **Swift 5.0+**

## Getting started

### Open the project

```bash
open ios/NTCodex.xcodeproj
```

### Run the core tests (any platform)

The core data structures and card database live in `ios/Packages/NTCodexCore`, which is a pure Swift package that compiles on Linux.

```bash
cd ios/Packages/NTCodexCore
swift test
```

## Data

The app loads card data from JSON files bundled in the core package:

- `cards.json` — all cards
- `packs.json` — pack information
- `vocabulary.json` — Japanese vocabulary
- `game-terms.json` — game terminology

These files are kept in sync with the repo root via `sync-data.sh`.

### Syncing data

After updating any of the four JSON files in the repo root, run:

```bash
./ios/sync-data.sh
```

This copies the files into `ios/Packages/NTCodexCore/Sources/NTCodexCore/Resources/`.

## Folder layout

```
ios/
├── NTCodex/
│   ├── Support/
│   │   ├── AppModel.swift           (app state)
│   │   ├── Routes.swift             (navigation)
│   │   ├── RemoteImage.swift        (image loading)
│   │   └── Theme.swift              (design system)
│   ├── Views/
│   │   └── [view files]             (SwiftUI views)
│   ├── Assets.xcassets/             (app icon, colors)
│   └── Info.plist                   (app configuration)
├── Packages/NTCodexCore/
│   ├── Package.swift                (Swift package manifest)
│   ├── Sources/NTCodexCore/
│   │   ├── Card.swift               (core data types)
│   │   ├── CardDatabase.swift       (search & query)
│   │   ├── Dictionary.swift         (vocabulary)
│   │   ├── MyCardsStore.swift       (user collection)
│   │   ├── Resources/
│   │   │   ├── cards.json
│   │   │   ├── packs.json
│   │   │   ├── vocabulary.json
│   │   │   └── game-terms.json
│   │   └── [other modules]
│   └── Tests/                       (Swift tests)
├── NTCodex.xcodeproj                (Xcode project)
└── sync-data.sh                     (data sync script)
```

## Design

The app uses a dark, aged-gold aesthetic with the Cinzel display font for headings and the system font for Japanese text. All colors and typography are defined in `Theme.swift`.
