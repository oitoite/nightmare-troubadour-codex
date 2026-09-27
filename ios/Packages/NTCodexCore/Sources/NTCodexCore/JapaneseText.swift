import Foundation

/// Kana helpers ported from the web app's util.js.
public enum JapaneseText {
    /// Katakana → hiragana (ァ..ヶ shifted down by 0x60). Everything else untouched.
    public static func katakanaToHiragana(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars {
            if u.value >= 0x30A1 && u.value <= 0x30F6, let h = Unicode.Scalar(u.value - 0x60) {
                out.append(h)
            } else {
                out.append(u)
            }
        }
        return String(out)
    }

    private static let rows: [(head: String, chars: String)] = [
        ("あ", "あいうえお"),
        ("か", "かきくけこがぎぐげご"),
        ("さ", "さしすせそざじずぜぞ"),
        ("た", "たちつてとだぢづでど"),
        ("な", "なにぬねの"),
        ("は", "はひふへほばびぶべぼぱぴぷぺぽ"),
        ("ま", "まみむめも"),
        ("や", "やゆよ"),
        ("ら", "らりるれろ"),
        ("わ", "わをん"),
    ]

    private static let rowMap: [Character: String] = {
        var m: [Character: String] = [:]
        for r in rows { for ch in r.chars { m[ch] = r.head } }
        return m
    }()

    /// あいうえお row head for a reading ("他" when it doesn't start with kana).
    public static func rowOf(_ reading: String) -> String {
        let h = katakanaToHiragana(reading)
        guard let first = h.first else { return "他" }
        return rowMap[first] ?? "他"
    }

    /// Anchored wildcard match where `*` matches any run of characters.
    /// Works on Unicode scalars; empty pattern matches only the empty string.
    public static func wildcardMatch(_ pattern: String, _ text: String) -> Bool {
        let p = Array(pattern.unicodeScalars)
        let t = Array(text.unicodeScalars)
        var pi = 0, ti = 0
        var starP = -1, starT = -1
        while ti < t.count {
            if pi < p.count, p[pi] == "*" {
                starP = pi; starT = ti; pi += 1
            } else if pi < p.count, p[pi] == t[ti] {
                pi += 1; ti += 1
            } else if starP >= 0 {
                pi = starP + 1; starT += 1; ti = starT
            } else {
                return false
            }
        }
        while pi < p.count, p[pi] == "*" { pi += 1 }
        return pi == p.count
    }
}
