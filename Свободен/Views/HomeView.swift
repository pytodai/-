import SwiftUI

struct HomeView: View {
    @Environment(AppViewModel.self) private var appVM

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            StatusTabView()
                .tabItem {
                    Label("Статус", systemImage: "hand.wave.fill")
                }

            FriendsView(ws: appVM.ws)
                .tabItem {
                    Label("Друзья", systemImage: "person.2.fill")
                }
        }
        .tint(Theme.coral)
    }
}

struct StatusTabView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var locationService = LocationService()
    @State private var showSetStatus = false
    @State private var statusVM: StatusViewModel? = nil
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: Theme.s5) {
                        Spacer(minLength: 40)

                        if let status = appVM.currentStatus {
                            StatusCardView(status: status) {
                                Haptics.warning()
                                await statusVM?.clearStatus(appVM: appVM)
                            }
                            .padding(.horizontal, Theme.s4)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
                        }

                        bigButton
                            .padding(.top, appVM.currentStatus == nil ? Theme.s5 : 0)

                        if appVM.currentStatus == nil {
                            Text("Дай знать друзьям, что готов встретиться")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.s6)
                        }

                        Spacer(minLength: 60)
                    }
                    .animation(.spring(response: 0.55, dampingFraction: 0.75), value: appVM.currentStatus != nil)
                }
            }
            .navigationTitle("Свободен")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.soft()
                        appVM.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSetStatus) {
                if let vm = statusVM {
                    SetStatusSheet(statusVM: vm).environment(appVM)
                }
            }
            .task { await appVM.refreshStatus() }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var bigButton: some View {
        Button {
            Haptics.tap()
            statusVM = StatusViewModel(locationService: locationService)
            showSetStatus = true
        } label: {
            ZStack {
                // External pulsing ring (only when no status)
                if appVM.currentStatus == nil {
                    Circle()
                        .stroke(Theme.coral.opacity(0.35), lineWidth: 2)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .opacity(pulse ? 0 : 0.7)
                        .frame(width: 220, height: 220)
                }

                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: 200, height: 200)
                    .shadow(color: Theme.coral.opacity(0.45), radius: 30, x: 0, y: 18)

                VStack(spacing: Theme.s2) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 44, weight: .bold))
                    Text(appVM.currentStatus != nil ? "Обновить" : "Я свободен!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
            }
        }
        .buttonStyle(SquishyButtonStyle())
        .scaleEffect(appVM.currentStatus != nil ? 0.78 : 1.0)
    }
}

struct SquishyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
