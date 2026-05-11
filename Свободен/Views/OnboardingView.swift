import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

private let pages: [OnboardingPage] = [
    .init(icon: "hand.wave.fill",
          title: "Скажи, что свободен",
          subtitle: "Одно нажатие — и друзья знают, что ты готов встретиться прямо сейчас"),
    .init(icon: "person.2.fill",
          title: "Видишь, кто свободен",
          subtitle: "Лента показывает друзей с обратным отсчётом — без лишних созвонов"),
    .init(icon: "paperplane.fill",
          title: "Зови на встречу",
          subtitle: "Отправь приглашение с предложением куда пойти — друг примет или отклонит"),
    .init(icon: "location.fill",
          title: "Делись районом",
          subtitle: "Опционально — друзья увидят в каком районе ты, без точного адреса"),
]

struct OnboardingView: View {
    @Binding var isOnboardingDone: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i], index: i).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: Theme.s2) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage
                                  ? AnyShapeStyle(Theme.primaryGradient)
                                  : AnyShapeStyle(Color.secondary.opacity(0.3)))
                            .frame(width: i == currentPage ? 26 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, Theme.s5)

                Button {
                    Haptics.tap()
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            currentPage += 1
                        }
                    } else {
                        Haptics.success()
                        withAnimation { isOnboardingDone = true }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Далее" : "Начать")
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .buttonStyle(GradientButtonStyle())
                .padding(.horizontal, Theme.s6)
                .padding(.bottom, 48)
            }
        }
    }

    private func pageView(_ page: OnboardingPage, index: Int) -> some View {
        VStack(spacing: Theme.s6) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.auroraGradient.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .blur(radius: 12)
                Circle()
                    .stroke(Theme.coral.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: 140, height: 140)
                    .shadow(color: Theme.coral.opacity(0.45), radius: 30, x: 0, y: 18)
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: Theme.s3) {
                Text(page.title)
                    .font(.displayMedium)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.s5)
            }

            Spacer()
            Spacer()
        }
    }
}
