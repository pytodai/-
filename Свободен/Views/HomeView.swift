import SwiftUI

struct HomeView: View {
    @Environment(AppViewModel.self) private var appVM

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
    }
}

struct StatusTabView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var locationService = LocationService()
    @State private var showSetStatus = false
    @State private var statusVM: StatusViewModel? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if let status = appVM.currentStatus {
                    StatusCardView(status: status) {
                        await statusVM?.clearStatus(appVM: appVM)
                    }
                    .padding(.horizontal)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    statusVM = StatusViewModel(locationService: locationService)
                    showSetStatus = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 40))
                        Text(appVM.currentStatus != nil ? "Обновить статус" : "Я свободен!")
                            .font(.title2.bold())
                    }
                    .frame(width: 200, height: 200)
                    .background(
                        Circle().fill(appVM.currentStatus != nil
                                      ? Color.accentColor.opacity(0.7)
                                      : Color.accentColor)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .scaleEffect(appVM.currentStatus != nil ? 0.9 : 1.0)
                .animation(.spring(duration: 0.4), value: appVM.currentStatus != nil)

                Spacer()
            }
            .navigationTitle("Свободен")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Выйти") { appVM.logout() }
                        .font(.subheadline)
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
}
