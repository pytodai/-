import SwiftUI
import UIKit

enum Theme {
    // MARK: Palette — единственный акцент, остальное нейтральное
    static let accent  = Color(red: 1.00, green: 0.42, blue: 0.10)   // #FF6B1A амбар
    static let accentDim = Color(red: 0.78, green: 0.32, blue: 0.06) // тёплый прижатый

    static let online  = Color(red: 0.30, green: 0.85, blue: 0.40)   // ярко-зелёный (онлайн)
    static let danger  = Color(red: 0.98, green: 0.30, blue: 0.27)

    static let surface = Color(.systemBackground)
    static let card    = Color(.secondarySystemBackground)
    static let muted   = Color.primary.opacity(0.55)
    static let border  = Color.primary.opacity(0.10)
    static let divider = Color.primary.opacity(0.06)

    // MARK: Spacing
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32

    // MARK: Radii
    static let rSm: CGFloat = 8
    static let rMd: CGFloat = 12
    static let rLg: CGFloat = 16
    static let rXl: CGFloat = 24
}

// MARK: - Typography (SF Pro, no rounded fluff)
extension Font {
    static let displayLarge  = Font.system(size: 40, weight: .black)
    static let displayMedium = Font.system(size: 30, weight: .black)
    static let titleStrong   = Font.system(size: 22, weight: .bold)
    static let bodyStrong    = Font.system(size: 17, weight: .semibold)
    static let metric        = Font.system(size: 17, weight: .bold).monospacedDigit()
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyStrong)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                    .fill(enabled ? Theme.accent : Theme.accent.opacity(0.35))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyStrong)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Card surface

struct CardModifier: ViewModifier {
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
    }
}

extension View {
    func card(padding: CGFloat = Theme.s4) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap()     { play(.light) }
    static func soft()    { play(.soft) }
    static func success() { notify(.success) }
    static func warning() { notify(.warning) }

    private static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
