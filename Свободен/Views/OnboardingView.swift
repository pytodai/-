import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        icon: "hand.wave.fill",
        title: "Скажи, что свободен",
        subtitle: "Одним нажатием сообщи друзьям, что ты готов встретиться прямо сейчас",
        color: .accentColor
    ),
    OnboardingPage(
        icon: "person.2.fill",
        title: "Видишь, кто свободен",
        subtitle: "Лента показывает твоих друзей с обратным отсчётом — никаких созвонов",
        color: .green
    ),
    OnboardingPage(
        icon: "paperplane.fill",
        title: "Зови на встречу",
        subtitle: "Отправь приглашение другу с предложением куда пойти — он примет или отклонит",
        color: .orange
    ),
    OnboardingPage(
        icon: "location.fill",
        title: "Делись районом",
        subtitle: "Опционально — друзья увидят в каком районе ты сейчас, без точного адреса",
        color: .blue
    ),
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
            .animation(.easeInOut, value: currentPage)

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: i == currentPage ? 20 : 8, height: 8)
                        .animation(.spring(duration: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    isOnboardingDone = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Далее" : "Начать")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
