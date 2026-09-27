import Foundation

/// One row of the Dictionary tab.
public struct DictionaryEntry: Hashable, Sendable, Identifiable {
    public var ja: String
    public var reading: String
    public var en: String
    public var group: String

    public var id: String { group + "|" + ja + "|" + reading + "|" + en }

    public init(ja: String, reading: String, en: String, group: String) {
        self.ja = ja; self.reading = reading; self.en = en; self.group = group
    }

    /// Reading shown in the table: hiragana, blank when it equals the headword.
    public var displayReading: String {
        guard !reading.isEmpty, reading != ja else { return "" }
        return JapaneseText.katakanaToHiragana(reading)
    }
}

/// A group of dictionary rows with a header (あ行 / a game-term category).
public struct DictionarySection: Hashable, Sendable, Identifiable {
    public var title: String
    public var entries: [DictionaryEntry]
    public var id: String { title }

    public init(title: String, entries: [DictionaryEntry]) {
        self.title = title; self.entries = entries
    }
}

public enum DictionaryMode: String, CaseIterable, Sendable {
    case words, game

    public var label: String { self == .words ? "Effect words" : "Game terms" }
}

/// Builds and filters dictionary rows. Mirrors dictionary.js.
public enum CardDictionary {
    public static func entries(mode: DictionaryMode, db: CardDatabase) -> [DictionaryEntry] {
        switch mode {
        case .game:
            return db.gameTerms.map {
                DictionaryEntry(ja: $0.ja, reading: $0.reading ?? "", en: $0.en ?? "", group: $0.cat ?? "—")
            }
        case .words:
            var src: [(entry: DictionaryEntry, key: String)] = []
            if !db.vocab.isEmpty {
                for w in db.vocab {
                    let e = DictionaryEntry(ja: w.ja, reading: w.reading ?? "", en: w.en ?? "", group: "")
                    src.append((e, w.reading ?? w.ja))
                }
            } else {
                var seen = Set<String>()
                for c in db.cards where !c.ja.isEmpty && !seen.contains(c.ja) {
                    seen.insert(c.ja)
                    let e = DictionaryEntry(ja: c.ja, reading: c.reading, en: c.en, group: "")
                    src.append((e, JapaneseText.katakanaToHiragana(c.reading.isEmpty ? c.ja : c.reading)))
                }
            }
            src.sort { $0.key.unicodeScalars.lexicographicallyPrecedes($1.key.unicodeScalars) }
            return src.map {
                var e = $0.entry
                e.group = JapaneseText.rowOf(e.reading.isEmpty ? e.ja : e.reading) + "行"
                return e
            }
        }
    }

    public static func filter(_ entries: [DictionaryEntry], query: String) -> [DictionaryEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return entries }
        let qL = q.lowercased()
        let qH = JapaneseText.katakanaToHiragana(q)
        return entries.filter {
            $0.ja.contains(q) || JapaneseText.katakanaToHiragana($0.ja).contains(qH)
                || $0.reading.contains(q) || JapaneseText.katakanaToHiragana($0.reading).contains(qH)
                || $0.en.lowercased().contains(qL)
        }
    }

    /// Groups consecutive entries sharing a group title (order preserved).
    public static func sections(_ entries: [DictionaryEntry]) -> [DictionarySection] {
        var out: [DictionarySection] = []
        for e in entries {
            if let last = out.last, last.title == e.group {
                out[out.count - 1].entries.append(e)
            } else {
                out.append(DictionarySection(title: e.group, entries: [e]))
            }
        }
        return out
    }

    public static func hint(mode: DictionaryMode, count: Int) -> String {
        switch mode {
        case .game: return "\(count) common game & menu terms — grouped by where you'll see them"
        case .words: return "\(count) words from card effect text — sorted by reading (あいうえお)"
        }
    }
}
