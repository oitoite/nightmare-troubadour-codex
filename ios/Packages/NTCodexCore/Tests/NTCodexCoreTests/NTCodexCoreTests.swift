import XCTest
@testable import NTCodexCore

final class DatabaseTests: XCTestCase {
    static let db: CardDatabase = {
        do { return try CardDatabase.loadBundled() } catch { fatalError("load failed: \(error)") }
    }()

    func testBundledDataLoads() {
        let db = Self.db
        XCTAssertEqual(db.cards.count, 1045)
        XCTAssertEqual(db.packs.count, 23)
        XCTAssertEqual(db.vocab.count, 973)
        XCTAssertFalse(db.gameTerms.isEmpty)
        XCTAssertFalse(db.races.isEmpty)
        XCTAssertEqual(db.categories.first, "Normal")
        XCTAssertEqual(db.categories, ["Normal", "Effect", "Ritual", "Fusion"])
    }

    func testCardFieldsDecode() throws {
        let db = Self.db
        let seven = try XCTUnwrap(db.cards.first { $0.en == "7" })
        XCTAssertEqual(seven.dbId, 6053)
        XCTAssertEqual(seven.cardType, .spell)
        XCTAssertEqual(seven.frame, .spell)
        XCTAssertEqual(seven.spellTrapType, "Continuous")
        XCTAssertEqual(seven.spellTrapTypeJa, "永続")
        XCTAssertEqual(seven.passcode, "67048711")
        XCTAssertEqual(seven.packs.first?.pack, "Visitor from Beyond")
        XCTAssertNotNil(seven.imageURL)
        XCTAssertEqual(seven.spellTrapLabelJa, "永続魔法")
        XCTAssertEqual(seven.spellTrapLabelEn, "Continuous Spell")
        XCTAssertEqual(seven.typeLineJa, "魔法カード")
        XCTAssertEqual(seven.typeLineEn, "Spell Card")
        XCTAssertEqual(seven.frameHex, "#1d9e75")
        XCTAssertEqual(seven.id, "id:6053")
    }

    func testMonsterDerivedFields() throws {
        let db = Self.db
        let m = try XCTUnwrap(db.cards.first { $0.en == "Dark Magician" })
        XCTAssertEqual(m.cardType, .monster)
        XCTAssertEqual(m.attribute, .dark)
        XCTAssertEqual(m.level, 7)
        XCTAssertEqual(m.atk, 2500)
        XCTAssertEqual(m.def, 2100)
        XCTAssertEqual(m.levelStars, String(repeating: "★", count: 7))
        XCTAssertTrue(m.typeLineJa.hasPrefix("【"))
        XCTAssertTrue(m.typeLineEn.hasSuffix("Monster"))
        XCTAssertEqual(m.yugipediaURL?.absoluteString, "https://yugipedia.com/wiki/Dark_Magician")
    }

    func testIdsAreUniqueAndStableWithoutDbId() {
        let db = Self.db
        let ids = db.cards.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "card ids must be unique")
        let noDb = db.cards.filter { $0.dbId == nil }
        XCTAssertEqual(noDb.count, 35)
        for c in noDb { XCTAssertFalse(c.id.isEmpty) }
    }

    func testPackIndexes() {
        let db = Self.db
        let miracle = db.cards(inPack: "Miracle of Nature")
        XCTAssertEqual(miracle.count, 52)
        let groups = db.cardsByRarity(inPack: "Miracle of Nature")
        XCTAssertEqual(groups.map(\.cards.count).reduce(0, +), 52)
        let names = groups.map(\.rarity)
        // Ultra → Super → Rare → Common ordering
        let ranks = names.map(Rarity.rank)
        XCTAssertEqual(ranks, ranks.sorted())
        XCTAssertEqual(db.pack(named: "Miracle of Nature")?.ja, "大自然の驚異")
        XCTAssertEqual(db.pack(named: "Miracle of Nature")?.pickerLabel, "Miracle of Nature — 大自然の驚異")
    }

    func testVocabLookup() {
        let db = Self.db
        XCTAssertEqual(db.vocab(for: "悪魔")?.en, "devil; demon; fiend")
        XCTAssertNil(db.vocab(for: "zzz"))
    }

    func testMissingPacksFallsBackToCardPacks() throws {
        let cardsURL = try XCTUnwrap(Bundle.module.url(forResource: "cards", withExtension: "json", subdirectory: "Resources"))
        let db = try CardDatabase.load(cardsData: Data(contentsOf: cardsURL), packsData: nil, vocabData: nil, gameTermsData: nil)
        XCTAssertFalse(db.packs.isEmpty)
        XCTAssertTrue(db.packs.contains { $0.name == "Miracle of Nature" })
        XCTAssertTrue(db.vocab.isEmpty)
    }
}

final class JapaneseTextTests: XCTestCase {
    func testKatakanaToHiragana() {
        XCTAssertEqual(JapaneseText.katakanaToHiragana("ブラック・マジシャン"), "ぶらっく・まじしゃん")
        XCTAssertEqual(JapaneseText.katakanaToHiragana("abc 123 漢字"), "abc 123 漢字")
        XCTAssertEqual(JapaneseText.katakanaToHiragana(""), "")
    }

    func testRowOf() {
        XCTAssertEqual(JapaneseText.rowOf("せぶん"), "さ")
        XCTAssertEqual(JapaneseText.rowOf("ブラック"), "は")
        XCTAssertEqual(JapaneseText.rowOf("がんばる"), "か")
        XCTAssertEqual(JapaneseText.rowOf("7"), "他")
        XCTAssertEqual(JapaneseText.rowOf(""), "他")
    }

    func testWildcard() {
        XCTAssertTrue(JapaneseText.wildcardMatch("*の", "闇の"))
        XCTAssertFalse(JapaneseText.wildcardMatch("*の", "のろい"))
        XCTAssertTrue(JapaneseText.wildcardMatch("dark*", "dark magician"))
        XCTAssertTrue(JapaneseText.wildcardMatch("*magic*", "dark magician girl"))
        XCTAssertFalse(JapaneseText.wildcardMatch("magic", "dark magician"))
        XCTAssertTrue(JapaneseText.wildcardMatch("*", ""))
        XCTAssertTrue(JapaneseText.wildcardMatch("a*b*c", "aXXbYYc"))
        XCTAssertFalse(JapaneseText.wildcardMatch("a*b*c", "aXXbYY"))
    }
}

final class RubyHTMLTests: XCTestCase {
    func testParsesVocabAndRuby() {
        let html = "「７」が<span class=\"vocab\" data-w=\"自分\"><ruby>自分<rt>じぶん</rt></ruby></span><span class=\"vocab\" data-w=\"フィールド\">フィールド</span>に"
        let segs = RubyHTML.parse(html)
        XCTAssertEqual(segs.count, 4)
        XCTAssertEqual(segs[0], RubySegment(base: "「７」が"))
        XCTAssertEqual(segs[1], RubySegment(base: "自分", reading: "じぶん", vocab: "自分"))
        XCTAssertEqual(segs[2], RubySegment(base: "フィールド", reading: nil, vocab: "フィールド"))
        XCTAssertEqual(segs[3], RubySegment(base: "に"))
        XCTAssertEqual(RubyHTML.plainText(html), "「７」が自分フィールドに")
    }

    func testEntitiesAndTypeLine() {
        XCTAssertEqual(RubyHTML.plainText("A &amp; B &lt;c&gt; &quot;d&quot;"), "A & B <c> \"d\"")
        let segs = RubyHTML.parse("<ruby>魔法<rt>まほう</rt></ruby>カード")
        XCTAssertEqual(segs, [RubySegment(base: "魔法", reading: "まほう"), RubySegment(base: "カード")])
    }

    func testEveryCardParsesToItsPlainText() {
        // The HTML is a marked-up version of jpEff; stripping markup must give jpEff back.
        var mismatches = 0
        for c in DatabaseTests.db.cards {
            guard let html = c.jpEffHtml else { continue }
            if RubyHTML.plainText(html) != c.jpEff { mismatches += 1 }
            if let t = c.typeLineJaHtml, RubyHTML.plainText(t) != c.typeLineJa.replacingOccurrences(of: "【", with: "").replacingOccurrences(of: "】", with: "") {
                // monsters' typeLineJaHtml carries the brackets itself; only check spells/traps strictly
                if !c.isMonster { mismatches += 1 }
            }
        }
        XCTAssertEqual(mismatches, 0)
    }

    func testSentencesSplitOnMaru() {
        let segs = RubyHTML.parse("Aです。<ruby>B<rt>び</rt></ruby>です。C")
        let s = RubyHTML.sentences(segs)
        XCTAssertEqual(s.count, 3)
        XCTAssertEqual(s[0].map(\.base).joined(), "Aです。")
        XCTAssertEqual(s[1].map(\.base).joined(), "Bです。")
        XCTAssertEqual(s[2].map(\.base).joined(), "C")
    }

    func testSentenceAlignment() {
        let en = "Draw 3 cards. Then destroy all cards; and gain 700 LP."
        XCTAssertEqual(SentenceAligner.englishSentences(en), ["Draw 3 cards.", "Then destroy all cards;", "and gain 700 LP."])
        let jp = RubyHTML.sentences(RubyHTML.parse("一。二。三。"))
        XCTAssertEqual(SentenceAligner.align(jpSentences: jp, en: en)?.count, 3)
        XCTAssertNil(SentenceAligner.align(jpSentences: jp, en: "Only one sentence."))
        let one = RubyHTML.sentences(RubyHTML.parse("一。"))
        XCTAssertNil(SentenceAligner.align(jpSentences: one, en: "One."))
    }

    func testAlignmentCoversTheSevenCard() throws {
        let seven = try XCTUnwrap(DatabaseTests.db.cards.first { $0.en == "7" })
        let jp = RubyHTML.sentences(RubyHTML.parse(seven.jpEffHtml!))
        XCTAssertEqual(jp.count, 3)
        XCTAssertEqual(SentenceAligner.align(jpSentences: jp, en: seven.enEff)?.count, 3)
    }
}

final class CardQueryTests: XCTestCase {
    var db: CardDatabase { DatabaseTests.db }

    func testEmptyQueryReturnsAllSortedByReading() {
        let all = CardQuery().apply(to: db)
        XCTAssertEqual(all.count, db.cards.count)
        let keys = all.map { JapaneseText.katakanaToHiragana($0.reading.isEmpty ? $0.ja : $0.reading) }
        for i in 1..<keys.count {
            XCTAssertFalse(keys[i].unicodeScalars.lexicographicallyPrecedes(keys[i - 1].unicodeScalars), "not sorted at \(i)")
        }
    }

    func testNameSearchIsKanaInsensitive() {
        var q = CardQuery()
        q.text = "ぶらっく・まじしゃん"
        let r = q.apply(to: db)
        XCTAssertTrue(r.contains { $0.en == "Dark Magician" })
        q.text = "ブラック・マジシャン"
        XCTAssertEqual(q.apply(to: db).count, r.count)
        q.text = "dark magician"
        XCTAssertTrue(q.apply(to: db).contains { $0.en == "Dark Magician" })
    }

    func testWildcardNameSearch() {
        var q = CardQuery()
        q.text = "*ドラゴン"
        let r = q.apply(to: db)
        XCTAssertFalse(r.isEmpty)
        for c in r {
            let ja = JapaneseText.katakanaToHiragana(c.ja), rd = JapaneseText.katakanaToHiragana(c.reading)
            XCTAssertTrue(ja.hasSuffix("どらごん") || rd.hasSuffix("どらごん") || c.packs.isEmpty == false && false, c.en)
        }
    }

    func testPackNameSearchInNameMode() {
        var q = CardQuery()
        q.text = "大自然"
        let r = q.apply(to: db)
        XCTAssertEqual(r.count, db.cards(inPack: "Miracle of Nature").count)
        q.mode = .text
        XCTAssertNotEqual(q.apply(to: db).count, r.count)
    }

    func testTextSearch() {
        var q = CardQuery()
        q.mode = .text
        q.text = "ライフポイント"
        let r = q.apply(to: db)
        XCTAssertFalse(r.isEmpty)
        XCTAssertTrue(r.allSatisfy { $0.jpEff.contains("ライフポイント") || $0.enEff.lowercased().contains("ライフポイント") })
        q.text = "draw 3 cards"
        XCTAssertTrue(q.apply(to: db).contains { $0.en == "7" })
    }

    func testFilters() {
        var q = CardQuery()
        q.cardType = .monster
        q.attributes = [.dark]
        q.levels = [7, 8]
        q.atkMin = 2500
        let r = q.apply(to: db)
        XCTAssertFalse(r.isEmpty)
        XCTAssertTrue(r.allSatisfy { $0.cardType == .monster && $0.attribute == .dark && [7, 8].contains($0.level!) && $0.atk! >= 2500 })
        XCTAssertTrue(r.contains { $0.en == "Dark Magician" })

        var s = CardQuery()
        s.cardType = .spell
        s.pack = "Visitor from Beyond"
        XCTAssertTrue(s.apply(to: db).allSatisfy { $0.cardType == .spell && $0.packs.contains { $0.pack == "Visitor from Beyond" } })
        XCTAssertTrue(s.hasActiveFilters)
        s.clearFilters()
        XCTAssertFalse(s.hasActiveFilters)
        XCTAssertEqual(s.activeFilterCount, 0)

        var d = CardQuery()
        d.defMin = 2000; d.defMax = 2100
        XCTAssertTrue(d.apply(to: db).allSatisfy { (2000...2100).contains($0.def!) })
        d.races = ["Dragon"]; d.categories = ["Effect"]
        XCTAssertTrue(d.apply(to: db).allSatisfy { $0.race == "Dragon" && $0.category == "Effect" })
    }

    func testSorts() {
        var q = CardQuery()
        q.sort = .atk
        let a = q.apply(to: db).map { $0.atk ?? -1 }
        XCTAssertEqual(a, a.sorted(by: >))
        q.sort = .def
        let d = q.apply(to: db).map { $0.def ?? -1 }
        XCTAssertEqual(d, d.sorted(by: >))
        q.sort = .level
        let l = q.apply(to: db).map { $0.level ?? -1 }
        XCTAssertEqual(l, l.sorted(by: >))
        q.sort = .en
        let e = q.apply(to: db).map(\.en)
        for i in 1..<e.count { XCTAssertNotEqual(e[i - 1].localizedCaseInsensitiveCompare(e[i]), .orderedDescending) }
    }
}

final class DictionaryTests: XCTestCase {
    var db: CardDatabase { DatabaseTests.db }

    func testWordsGroupedByRow() {
        let entries = CardDictionary.entries(mode: .words, db: db)
        XCTAssertEqual(entries.count, db.vocab.count)
        XCTAssertEqual(entries.first?.group, "あ行")
        let sections = CardDictionary.sections(entries)
        XCTAssertTrue(sections.count >= 10)
        XCTAssertEqual(sections.map(\.entries.count).reduce(0, +), entries.count)
        XCTAssertEqual(entries.first { $0.ja == "アイツ" }?.displayReading, "あいつ")
    }

    func testGameTermsGroupedByCategory() {
        let entries = CardDictionary.entries(mode: .game, db: db)
        XCTAssertEqual(entries.count, db.gameTerms.count)
        XCTAssertEqual(entries.first?.group, "メニュー · Menu")
        XCTAssertEqual(entries.first { $0.ja == "はい" }?.displayReading, "")
    }

    func testFilter() {
        let entries = CardDictionary.entries(mode: .words, db: db)
        XCTAssertTrue(CardDictionary.filter(entries, query: "demon").allSatisfy { $0.en.lowercased().contains("demon") })
        XCTAssertTrue(CardDictionary.filter(entries, query: "アクマ").contains { $0.ja == "悪魔" })
        XCTAssertEqual(CardDictionary.filter(entries, query: "   ").count, entries.count)
        XCTAssertTrue(CardDictionary.hint(mode: .words, count: 5).hasPrefix("5 words"))
    }
}

final class SymbolTests: XCTestCase {
    func testSymbolInfo() {
        XCTAssertEqual(Symbols.info(for: .attribute(.dark))?.ja, "闇")
        XCTAssertEqual(Symbols.info(for: .level(7))?.label, "Level 7")
        XCTAssertEqual(Symbols.info(for: .spell("Quick-Play"))?.ja, "速攻魔法")
        XCTAssertEqual(Symbols.info(for: .trap("Counter"))?.ja, "カウンター罠")
        XCTAssertNil(Symbols.info(for: .trap("Equip")))
        XCTAssertEqual(Symbols.subtypeSFSymbol("Continuous"), "infinity")
        XCTAssertNil(Symbols.subtypeSFSymbol("Normal"))
    }
}

final class MyCardsStoreTests: XCTestCase {
    func testRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ntcodex-tests-\(UUID().uuidString)")
        let url = dir.appendingPathComponent("my-cards.json")
        defer { try? FileManager.default.removeItem(at: dir) }
        let db = DatabaseTests.db
        let a = db.cards[0], b = db.cards[1]

        let store = MyCardsStore(fileURL: url)
        XCTAssertTrue(store.cards.isEmpty)
        XCTAssertTrue(store.save(a))
        XCTAssertFalse(store.save(a), "duplicate save is a no-op")
        XCTAssertTrue(store.save(b))
        XCTAssertEqual(store.cards.map(\.card.id), [b.id, a.id], "newest first")
        store.updateNote(for: a, note: "great card")
        XCTAssertTrue(store.isSaved(a))

        let reloaded = MyCardsStore(fileURL: url)
        XCTAssertEqual(reloaded.cards.count, 2)
        XCTAssertEqual(reloaded.cards.first { $0.card.id == a.id }?.userNote, "great card")
        XCTAssertEqual(reloaded.cards.first { $0.card.id == a.id }?.card.jpEffHtml, a.jpEffHtml)

        reloaded.remove(a)
        XCTAssertFalse(reloaded.isSaved(a))
        reloaded.remove(at: 0)
        XCTAssertTrue(reloaded.cards.isEmpty)
        XCTAssertTrue(MyCardsStore(fileURL: url).cards.isEmpty)
    }
}
