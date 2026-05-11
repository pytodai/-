import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

private let pages: [OnboardingPage] = [
    .init(icon: "circle.fill",
          title: "Скажи, что свободен",
          subtitle: "Одно нажатие — друзья знают, что ты готов встретиться"),
    .init(icon: "person.2.fill",
          title: "Видишь, кто свободен",
          subtitle: "Лента с обратным отсчётом — без созвонов"),
    .init(icon: "paperplane.fill",
          title: "Зови на встречу",
          subtitle: "Отправь приглашение — друг примет или отклонит"),
    .init(icon: "mappin.circle.fill",
          title: "Делись районом",
          subtitle: "Опционально — без точного адреса"),
]

struct OnboardingView: View {
    @Binding var isOnboardingDone: Bool
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Theme.accent : Theme.muted.opacity(0.3))
                        .frame(width: i == currentPage ? 20 : 6, height: 6)
                        .animation(.easeOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, Theme.s5)

            Button {
                Haptics.tap()
                if currentPage < pages.count - 1 {
                    withAnimation(.easeOut(duration: 0.25)) { currentPage += 1 }
                } else {
                    Haptics.success()
                    withAnimation { isOnboardingDone = true }
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Далее" : "Начать")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.s5)
            .padding(.bottom, 48)
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Theme.s5) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.accent)
                .frame(width: 140, height: 140)
                .background(
                    Circle().stroke(Theme.border, lineWidth: 1)
                )

            VStack(spacing: Theme.s2) {
                Text(page.title)
                    .font(.displayMedium)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.s5)
            }

            Spacer()
            Spacer()
        }
    }
}
