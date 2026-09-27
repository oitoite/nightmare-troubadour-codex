import Foundation

/// One run of Japanese text from an effect line: base text, optional furigana,
/// and the dictionary headword it links to (for tap-to-define).
public struct RubySegment: Hashable, Sendable, Identifiable {
    public var base: String
    public var reading: String?
    public var vocab: String?

    public init(base: String, reading: String? = nil, vocab: String? = nil) {
        self.base = base; self.reading = reading; self.vocab = vocab
    }

    /// Identity is positional; callers should enumerate. Kept for ForEach convenience.
    public var id: String { "\(base)|\(reading ?? "")|\(vocab ?? "")" }

    public var hasReading: Bool { !(reading ?? "").isEmpty }
    public var hasVocab: Bool { !(vocab ?? "").isEmpty }
}

/// Parses the tiny HTML dialect used in cards.json (`jpEffHtml`, `typeLineJaHtml`):
/// `<span class="vocab" data-w="…">…</span>`, `<ruby>base<rt>reading</rt></ruby>`,
/// and plain text with HTML entities. Any other tag is ignored.
public enum RubyHTML {
    public static func parse(_ html: String) -> [RubySegment] {
        var segments: [RubySegment] = []
        var text = ""                      // pending plain text
        var vocabStack: [String?] = []     // innermost span's data-w
        var rubyBase: String? = nil        // non-nil while inside <ruby>
        var rubyRt: String? = nil          // reading collected for the open <ruby>
        var inRt = false

        func currentVocab() -> String? { vocabStack.last ?? nil }

        func flushText() {
            guard !text.isEmpty else { return }
            segments.append(RubySegment(base: text, reading: nil, vocab: currentVocab()))
            text = ""
        }

        let chars = Array(html)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if ch == "<", let end = chars[i...].firstIndex(of: ">") {
                let tag = String(chars[(i + 1)..<end])
                i = end + 1
                let lower = tag.lowercased()
                if lower.hasPrefix("span") {
                    flushText()
                    vocabStack.append(attribute("data-w", in: tag))
                } else if lower == "/span" {
                    flushText()
                    if !vocabStack.isEmpty { vocabStack.removeLast() }
                } else if lower.hasPrefix("ruby") {
                    flushText()
                    rubyBase = ""; rubyRt = nil; inRt = false
                } else if lower == "/ruby" {
                    if let base = rubyBase, !base.isEmpty {
                        segments.append(RubySegment(base: base, reading: rubyRt, vocab: currentVocab()))
                    }
                    rubyBase = nil; rubyRt = nil; inRt = false
                } else if lower.hasPrefix("rt") {
                    inRt = true; rubyRt = ""
                } else if lower == "/rt" {
                    inRt = false
                } else if lower.hasPrefix("br") {
                    flushText()
                    segments.append(RubySegment(base: "\n"))
                }
                continue
            }
            if inRt {
                rubyRt = (rubyRt ?? "") + String(ch)
            } else if rubyBase != nil {
                rubyBase!.append(ch)
            } else {
                text.append(ch)
            }
            i += 1
        }
        flushText()
        return decodeEntities(in: segments)
    }

    private static func attribute(_ name: String, in tag: String) -> String? {
        guard let r = tag.range(of: name + "=\"") else { return nil }
        let after = tag[r.upperBound...]
        guard let q = after.firstIndex(of: "\"") else { return nil }
        return decodeEntities(String(after[..<q]))
    }

    private static func decodeEntities(in segs: [RubySegment]) -> [RubySegment] {
        segs.map {
            RubySegment(base: decodeEntities($0.base), reading: $0.reading.map(decodeEntities), vocab: $0.vocab)
        }
    }

    public static func decodeEntities(_ s: String) -> String {
        guard s.contains("&") else { return s }
        return s
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: "\u{00A0}")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    /// Plain text with all markup removed (readings dropped).
    public static func plainText(_ html: String) -> String {
        parse(html).map(\.base).joined()
    }

    /// Splits segments into sentences on 。 (the 。 stays with its sentence).
    /// Segment boundaries are preserved; a segment containing 。 mid-way is split.
    public static func sentences(_ segments: [RubySegment]) -> [[RubySegment]] {
        var out: [[RubySegment]] = []
        var cur: [RubySegment] = []
        for seg in segments {
            if seg.hasReading || !seg.base.contains("。") {
                cur.append(seg)
                if seg.hasReading == false, seg.base.hasSuffix("。") {
                    out.append(cur); cur = []
                }
                continue
            }
            // plain text with one or more 。 inside
            var piece = ""
            for ch in seg.base {
                piece.append(ch)
                if ch == "。" {
                    cur.append(RubySegment(base: piece, vocab: seg.vocab))
                    out.append(cur); cur = []; piece = ""
                }
            }
            if !piece.isEmpty { cur.append(RubySegment(base: piece, vocab: seg.vocab)) }
        }
        if !cur.isEmpty {
            // drop whitespace-only tail
            if cur.contains(where: { !$0.base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                out.append(cur)
            }
        }
        return out
    }
}

/// Aligns Japanese effect sentences with English ones so a sentence can be
/// "peeked" in translation. Mirrors buildJpEffInner() in the web app.
public enum SentenceAligner {
    /// English sentences split after `.` or `;` followed by whitespace.
    public static func englishSentences(_ en: String) -> [String] {
        var out: [String] = []
        var cur = ""
        let chars = Array(en)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            cur.append(ch)
            if ch == "." || ch == ";" {
                // split if followed by whitespace
                if i + 1 < chars.count, chars[i + 1].isWhitespace {
                    out.append(cur.trimmingCharacters(in: .whitespacesAndNewlines))
                    cur = ""
                    while i + 1 < chars.count, chars[i + 1].isWhitespace { i += 1 }
                }
            }
            i += 1
        }
        let tail = cur.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { out.append(tail) }
        return out
    }

    /// Returns per-sentence English when the JP and EN sentence counts agree and
    /// there is more than one sentence; otherwise nil (caller shows a full toggle).
    public static func align(jpSentences: [[RubySegment]], en: String) -> [String]? {
        let enParts = englishSentences(en)
        guard jpSentences.count > 1, jpSentences.count == enParts.count else { return nil }
        return enParts
    }
}
