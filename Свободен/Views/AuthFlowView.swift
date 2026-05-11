import SwiftUI

struct AuthFlowView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var authVM = AuthViewModel()

    var body: some View {
        ZStack {
            if !authVM.codeSent {
                PhoneInputView(authVM: authVM)
                    .transition(.push(from: .leading))
            } else {
                CodeInputView(authVM: authVM)
                    .transition(.push(from: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.codeSent)
    }
}
