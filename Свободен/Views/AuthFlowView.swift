import SwiftUI

struct AuthFlowView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var authVM = AuthViewModel()

    var body: some View {
        LoginView(authVM: authVM)
    }
}
