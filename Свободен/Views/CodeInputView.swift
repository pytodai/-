import SwiftUI

struct CodeInputView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(AppViewModel.self) private var appVM
    @State private var code = ""

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Код из SMS")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Отправлен на \(authVM.phone)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("0000", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 64)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await authVM.verifyCode(code) { token in
                        appVM.onLogin(token: token)
                    }
                }
            } label: {
                Group {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Войти").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(code.count < 4 || authVM.isLoading)
            .padding(.horizontal, 32)

            Button("Изменить номер") {
                authVM.codeSent = false
                authVM.errorMessage = nil
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
