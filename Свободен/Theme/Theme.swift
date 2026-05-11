import SwiftUI
import UIKit

enum Theme {
    // MARK: Palette
    static let coral   = Color(red: 1.00, green: 0.42, blue: 0.62)   // #FF6B9D
    static let peach   = Color(red: 1.00, green: 0.55, blue: 0.26)   // #FF8C42
    static let violet  = Color(red: 0.62, green: 0.48, blue: 1.00)   // #9D7AFF
    static let mint    = Color(red: 0.31, green: 0.80, blue: 0.77)   // #4ECDC4
    static let sun     = Color(red: 1.00, green: 0.78, blue: 0.28)   // #FFC647

    static let surface = Color(.systemBackground)
    static let card    = Color(.secondarySystemBackground)
    static let border  = Color.primary.opacity(0.08)

    // MARK: Gradients
    static let primaryGradient = LinearGradient(
        colors: [coral, peach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let auroraGradient = LinearGradient(
        colors: [coral, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunsetGradient = LinearGradient(
        colors: [violet, coral, peach, sun],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Spacing
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32

    // MARK: Radii
    static let rSm: CGFloat = 12
    static let rMd: CGFloat = 18
    static let rLg: CGFloat = 26
    static let rXl: CGFloat = 36
}

// MARK: - Typography

extension Font {
    static let displayLarge  = Font.system(size: 48, weight: .black,   design: .rounded)
    static let displayMedium = Font.system(size: 34, weight: .bold,    design: .rounded)
    static let titleStrong   = Font.system(size: 22, weight: .bold,    design: .rounded)
    static let bodyStrong    = Font.system(size: 17, weight: .semibold, design: .rounded)
}

// MARK: - Components

struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = Theme.primaryGradient
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyStrong)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.s4)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous))
            .shadow(color: Theme.coral.opacity(isProminent ? 0.35 : 0), radius: 18, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = Theme.s4
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.rLg, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rLg, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func glassCard(padding: CGFloat = Theme.s4) -> some View {
        modifier(GlassCardModifier(padding: padding))
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap()      { play(.light) }
    static func soft()     { play(.soft) }
    static func success()  { notify(.success) }
    static func warning()  { notify(.warning) }

    private static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }
    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(type)
    }
}
