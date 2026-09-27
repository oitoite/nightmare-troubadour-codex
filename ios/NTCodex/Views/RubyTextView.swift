import SwiftUI
import NTCodexCore

// MARK: - RubyTextView

/// Renders Japanese text with furigana readings above kanji, wrapping like the
/// web app's `.d-eff-jp` / `.d-typeline` blocks. Segments carrying a `vocab`
/// word get a dotted underline and are tappable to look the word up.
struct RubyTextView: View {
    let segments: [RubySegment]
    let showFurigana: Bool
    let fontSize: CGFloat
    let onVocabTap: ((String) -> Void)?

    init(segments: [RubySegment], showFurigana: Bool, fontSize: CGFloat, onVocabTap: ((String) -> Void)?) {
        self.segments = segments
        self.showFurigana = showFurigana
        self.fontSize = fontSize
        self.onVocabTap = onVocabTap
    }

    var body: some View {
        let items = Self.buildItems(segments)
        RubyFlowLayout(lineHeight: fontSize * (showFurigana ? 1.95 : 1.55)) {
            ForEach(items) { item in
                itemView(item)
            }
        }
    }

    @ViewBuilder
    private func itemView(_ item: RubyFlowItem) -> some View {
        if item.isBreak {
            Color.clear
                .frame(width: 0, height: 0)
                .rubyForceBreak()
        } else if let reading = item.reading, !reading.isEmpty {
            VStack(alignment: .center, spacing: 0) {
                if showFurigana {
                    Text(reading)
                        .font(Theme.jp(fontSize * 0.5))
                        .foregroundStyle(Theme.ink2)
                }
                baseText(item)
            }
        } else {
            baseText(item)
        }
    }

    @ViewBuilder
    private func baseText(_ item: RubyFlowItem) -> some View {
        let text = Text(item.text)
            .font(Theme.jp(fontSize))
            .foregroundStyle(Theme.ink)
        if item.hasVocab, let vocab = item.vocab {
            text
                .overlay(alignment: .bottom) {
                    RubyDashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .foregroundStyle(Theme.gold2.opacity(0.6))
                        .frame(height: 2)
                }
                .contentShape(Rectangle())
                .onTapGesture { onVocabTap?(vocab) }
        } else {
            text
        }
    }

    // MARK: Item construction

    /// Splits parsed segments into individually-flowable pieces: a segment WITH
    /// a reading stays whole (reading + base ride together), a segment WITHOUT a
    /// reading is split per-character for CJK text (so wrapping behaves like
    /// Japanese) while runs of non-CJK characters (numbers, "ATK", punctuation,
    /// spaces) stay together as one item. A lone "\n" base forces a line break.
    private static func buildItems(_ segments: [RubySegment]) -> [RubyFlowItem] {
        var items: [RubyFlowItem] = []
        var idx = 0
        for seg in segments {
            if seg.hasReading {
                items.append(RubyFlowItem(id: idx, isBreak: false, text: seg.base, reading: seg.reading, vocab: seg.vocab))
                idx += 1
            } else if seg.base == "\n" {
                items.append(RubyFlowItem(id: idx, isBreak: true, text: "", reading: nil, vocab: nil))
                idx += 1
            } else {
                for piece in splitPieces(seg.base) {
                    items.append(RubyFlowItem(id: idx, isBreak: false, text: piece, reading: nil, vocab: seg.vocab))
                    idx += 1
                }
            }
        }
        return items
    }

    private static func splitPieces(_ base: String) -> [String] {
        guard !base.isEmpty else { return [] }
        var pieces: [String] = []
        var run = ""
        for ch in base {
            if isCJK(ch) {
                if !run.isEmpty { pieces.append(run); run = "" }
                pieces.append(String(ch))
            } else {
                run.append(ch)
            }
        }
        if !run.isEmpty { pieces.append(run) }
        return pieces
    }

    /// True for characters that should flow/wrap one at a time, like Japanese
    /// text does (kana, kanji, CJK/fullwidth punctuation).
    private static func isCJK(_ c: Character) -> Bool {
        guard let scalar = c.unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x3000...0x303F, // CJK punctuation
             0x3040...0x309F, // Hiragana
             0x30A0...0x30FF, // Katakana
             0x3400...0x4DBF, // CJK extension A
             0x4E00...0x9FFF, // CJK unified ideographs
             0xF900...0xFAFF, // CJK compatibility ideographs
             0xFF00...0xFFEF: // Halfwidth/fullwidth forms
            return true
        default:
            return false
        }
    }
}

private struct RubyFlowItem: Identifiable {
    let id: Int
    let isBreak: Bool
    let text: String
    let reading: String?
    let vocab: String?

    var hasVocab: Bool { !(vocab ?? "").isEmpty }
}

private struct RubyDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        return p
    }
}

// MARK: - RubyNameView

/// The card name block: reading above (small, muted), name below (bold, jp font).
struct RubyNameView: View {
    let ja: String
    let reading: String?
    let fontSize: CGFloat

    init(ja: String, reading: String?, fontSize: CGFloat) {
        self.ja = ja
        self.reading = reading
        self.fontSize = fontSize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let reading, !reading.isEmpty {
                Text(reading)
                    .font(Theme.jp(fontSize * 0.45))
                    .foregroundStyle(Theme.ink2)
            }
            Text(ja)
                .font(Theme.jp(fontSize, weight: .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - RubyFlowLayout (fixed line height, used for Japanese ruby text)

/// Marks a subview as forcing a line break (used for parsed "<br>" segments).
private struct RubyLineBreakKey: LayoutValueKey {
    static let defaultValue: Bool = false
}

private extension View {
    func rubyForceBreak(_ value: Bool = true) -> some View {
        layoutValue(key: RubyLineBreakKey.self, value: value)
    }
}

/// Flows subviews left-to-right, wrapping at `lineHeight`-tall lines, with each
/// item's bottom aligned to the line's bottom (so kanji with and without
/// furigana still sit on a common baseline). A subview tagged with
/// `rubyForceBreak()` ends its line immediately without occupying width.
struct RubyFlowLayout: Layout {
    var lineHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // With no width proposal (e.g. an HStack asking for the ideal size) lay
        // everything on one line; otherwise wrap at the proposed width and
        // report the widest line actually used.
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var widest: CGFloat = 0
        var lines: CGFloat = subviews.isEmpty ? 0 : 1
        for subview in subviews {
            if subview[RubyLineBreakKey.self] {
                widest = max(widest, x)
                lines += 1
                x = 0
                continue
            }
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                widest = max(widest, x)
                lines += 1
                x = size.width
            } else {
                x += size.width
            }
        }
        widest = max(widest, x)
        let width = maxWidth.isFinite ? min(widest, maxWidth) : widest
        return CGSize(width: width, height: lineHeight * max(lines, 1))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        for subview in subviews {
            if subview[RubyLineBreakKey.self] {
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: 0, height: 0))
                x = bounds.minX
                y += lineHeight
                continue
            }
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.minX + bounds.width {
                x = bounds.minX
                y += lineHeight
            }
            let itemY = y + max(0, lineHeight - size.height)
            subview.place(at: CGPoint(x: x, y: itemY), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width
        }
    }
}

// MARK: - FlowLayout (general purpose, dynamic line height, used for chips)

/// A simple wrapping row layout for same-size-ish chips (pack chips, link
/// buttons): dynamic per-line height, fixed spacing between items and lines.
struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    init(spacing: CGFloat = 6, lineSpacing: CGFloat = 6) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                maxLineWidth = max(maxLineWidth, x - spacing)
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        maxLineWidth = max(maxLineWidth, x - spacing)
        y += lineHeight
        let width = max(maxLineWidth, 0)
        return CGSize(width: maxWidth.isFinite ? min(width, maxWidth) : width, height: max(y, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.minX + bounds.width {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
