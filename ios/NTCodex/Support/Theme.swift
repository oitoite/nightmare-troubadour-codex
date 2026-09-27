import SwiftUI
import NTCodexCore

extension Color {
    init(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespaces)
        if hexStr.hasPrefix("#") {
            hexStr.removeFirst()
        }

        guard hexStr.count == 6,
              let int = Int(hexStr, radix: 16) else {
            self = .gray
            return
        }

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    // MARK: - Palette
    static let ink = Color(hex: "#ede4d0")
    static let ink2 = Color(hex: "#b6a684")
    static let ink3 = Color(hex: "#8a7a57")
    static let page = Color(hex: "#0d0b08")
    static let frame = Color(hex: "#8a713c")
    static let frame2 = Color(hex: "#5a4a28")
    static let panel = Color(hex: "#1d1810")
    static let panel2 = Color(hex: "#16130d")
    static let gold = Color(hex: "#e6c988")
    static let gold2 = Color(hex: "#c8a45a")
    static let line = Color(hex: "#3a2f1c")
    static let line2 = Color(hex: "#2a2114")
    static let banner = Color(hex: "#6b5630")

    // MARK: - Derived Colors
    static func frameColor(_ card: Card) -> Color {
        Color(hex: card.frameHex)
    }

    static func attributeColor(_ a: Attribute) -> Color {
        Color(hex: a.hex)
    }

    // MARK: - Backgrounds & Gradients
    static var pageBackground: some View {
        ZStack {
            // Linear gradient base
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#16130d"), location: 0.0),
                    .init(color: Color(hex: "#0d0b08"), location: 0.55),
                    .init(color: Color(hex: "#08060a"), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Radial gold glow at top
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#e6c988").opacity(0.18), location: 0.0),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .init(x: 0.5, y: -0.06),
                startRadius: 0,
                endRadius: 800
            )
        }
        .ignoresSafeArea()
    }

    static var panelGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#241d12"), location: 0.0),
                .init(color: Color(hex: "#16130d"), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#e6c988"), location: 0.0),
                .init(color: Color(hex: "#c8a45a"), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Fonts
    static func display(_ size: CGFloat, bold: Bool = false) -> Font {
        if bold {
            return .custom("Cinzel-Bold", size: size)
        } else {
            return .custom("Cinzel-Medium", size: size)
        }
    }

    static func jp(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - PanelModifier
struct PanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.panelGradient)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.frame2, lineWidth: 2))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}

// MARK: - View Extensions
extension View {
    func panel() -> some View {
        modifier(PanelModifier())
    }

    func codexScreen() -> some View {
        self
            .background(Theme.pageBackground)
            .tint(Theme.gold)
            .toolbarBackground(Theme.panel2, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Button Styles
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(13, bold: true))
            .tracking(0.8)
            .foregroundColor(Color(hex: "#2a2010"))
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Theme.goldGradient)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color(hex: "#8a713c"), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(12))
            .tracking(0.5)
            .foregroundColor(Theme.gold)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Theme.panel2)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Theme.frame, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    init(_ label: String, isOn: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isOn = isOn
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.jp(13, weight: .medium))
                .foregroundColor(isOn ? Theme.gold : Theme.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isOn ? Theme.gold.opacity(0.12) : Theme.panel2)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isOn ? Theme.gold : Theme.line, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(Theme.display(11))
            .foregroundColor(Theme.gold2)
            .tracking(1)
    }
}
