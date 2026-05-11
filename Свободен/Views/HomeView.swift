import SwiftUI

struct HomeView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        TabView {
            StatusTabView()
                .tabItem {
                    Label("Статус", systemImage: "circle.fill")
                }

            FriendsView(ws: appVM.ws)
                .tabItem {
                    Label("Друзья", systemImage: "person.2.fill")
                }
        }
        .tint(Theme.accent)
    }
}

struct StatusTabView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var locationService = LocationService()
    @State private var showSetStatus = false
    @State private var statusVM: StatusViewModel? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.s5) {
                    if let status = appVM.currentStatus {
                        StatusCardView(status: status) {
                            Haptics.warning()
                            await statusVM?.clearStatus(appVM: appVM)
                        }
                        .padding(.horizontal, Theme.s4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer(minLength: 40)

                    bigButton

                    if appVM.currentStatus == nil {
                        Text("Сообщи друзьям, что готов встретиться")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.s6)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, Theme.s3)
                .animation(.easeOut(duration: 0.25), value: appVM.currentStatus != nil)
            }
            .navigationTitle("Свободен")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.soft()
                        appVM.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    .buttonStyle(IconButtonStyle())
                }
            }
            .sheet(isPresented: $showSetStatus) {
                if let vm = statusVM {
                    SetStatusSheet(statusVM: vm).environment(appVM)
                }
            }
            .task { await appVM.refreshStatus() }
        }
    }

    private var bigButton: some View {
        Button {
            Haptics.tap()
            statusVM = StatusViewModel(locationService: locationService)
            showSetStatus = true
        } label: {
            ZStack {
                Circle()
                    .fill(appVM.currentStatus == nil ? Theme.accent : Theme.card)
                    .overlay(
                        Circle()
                            .stroke(appVM.currentStatus == nil ? Color.clear : Theme.border, lineWidth: 1)
                    )

                VStack(spacing: Theme.s2) {
                    Text(appVM.currentStatus != nil ? "ОБНОВИТЬ" : "СВОБОДЕН")
                        .font(.system(size: 22, weight: .black))
                        .tracking(2)
                    if appVM.currentStatus == nil {
                        Rectangle()
                            .fill(.white.opacity(0.6))
                            .frame(width: 28, height: 2)
                    }
                }
                .foregroundStyle(appVM.currentStatus == nil ? Color.white : Theme.muted)
            }
            .frame(width: 220, height: 220)
        }
        .buttonStyle(IconButtonStyle())
        .scaleEffect(appVM.currentStatus != nil ? 0.82 : 1.0)
        .animation(.easeOut(duration: 0.25), value: appVM.currentStatus != nil)
    }
}
