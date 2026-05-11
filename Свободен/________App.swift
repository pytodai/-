import SwiftUI

@main
struct ________App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appVM = AppViewModel()
    @AppStorage("onboardingDone") private var onboardingDone = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !onboardingDone {
                    OnboardingView(isOnboardingDone: $onboardingDone)
                        .transition(.push(from: .trailing))
                } else if appVM.isAuthenticated {
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
            .animation(.easeInOut(duration: 0.35), value: onboardingDone)
            .animation(.easeInOut(duration: 0.35), value: appVM.isAuthenticated)
        }
    }
}
