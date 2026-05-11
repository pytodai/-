import SwiftUI

@main
struct ________App: App {
    @State private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appVM.isAuthenticated {
                    HomeView()
                        .environment(appVM)
                        .transition(.asymmetric(
                            insertion: .push(from: .trailing),
                            removal: .push(from: .leading)
                        ))
                } else {
                    AuthFlowView()
                        .environment(appVM)
                        .transition(.asymmetric(
                            insertion: .push(from: .leading),
                            removal: .push(from: .trailing)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: appVM.isAuthenticated)
        }
    }
}
