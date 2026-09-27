# 遊戯王 Card Codex — Nightmare Troubadour

A card lookup tool for *Yu-Gi-Oh! Duel Monsters: Nightmare Troubadour* (DS, 2005).
Search and filter every card in the game using the authentic Japanese OCG card art.

## Features

- Search by card name in Japanese or English
- Search by pack name in Japanese or English
- Filter by card type, monster type, attribute, level, and ATK/DEF
- View the real Japanese card scan with full stats and effect text
- Save cards to a personal collection with notes
- Add cards by hand if anything is missing

## iOS app

A native SwiftUI port lives in [`ios/`](ios/README.md). Open `ios/NTCodex.xcodeproj` in Xcode 16+
(iOS 17+). The search, filter, dictionary and saved-cards logic is a standalone Swift package
(`ios/Packages/NTCodexCore`) with unit tests that run anywhere Swift does (`swift test`).

## Credits

Card data and images from [Yugipedia](https://yugipedia.com) and [YGOResources](https://db.ygoresources.com).
Card game © Konami. Fan project, not affiliated with Konami.
