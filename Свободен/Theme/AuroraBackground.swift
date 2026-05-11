import SwiftUI

/// Анимированный фон — три плавающих "блобa" поверх лёгкого градиента.
struct AuroraBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.violet.opacity(0.10),
                    Theme.coral.opacity(0.08),
                    Theme.peach.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            blob(color: Theme.coral, x: animate ? -80 : 60, y: animate ? -120 : -180, size: 320)
            blob(color: Theme.violet, x: animate ? 140 : -100, y: animate ? 220 : 320, size: 340)
            blob(color: Theme.peach, x: animate ? 60 : 160, y: animate ? -60 : 80, size: 260)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }

    private func blob(color: Color, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 80)
            .opacity(0.55)
            .offset(x: x, y: y)
    }
}
