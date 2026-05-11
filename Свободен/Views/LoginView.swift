import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var authVM: AuthViewModel
    @FocusState private var focused: Field?

    enum Field { case username, password }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mark / logo
            Text("СВОБОДЕН")
                .font(.system(size: 32, weight: .black))
                .tracking(4)
                .padding(.bottom, Theme.s2)

            Rectangle()
                .fill(Theme.accent)
                .frame(width: 40, height: 3)
                .padding(.bottom, Theme.s5)

            VStack(spacing: Theme.s3) {
                fieldRow(placeholder: "логин", text: $authVM.username, secure: false, field: .username)
                fieldRow(placeholder: "пароль", text: $authVM.password, secure: true, field: .password)
            }
            .padding(.horizontal, Theme.s5)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.danger)
                    .padding(.horizontal, Theme.s5)
                    .padding(.top, Theme.s3)
            }

            Button {
                Haptics.tap()
                focused = nil
                Task {
                    await authVM.submit { token in
                        Haptics.success()
                        appVM.onLogin(token: token)
                    }
                }
            } label: {
                if authVM.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(authVM.mode == .login ? "Войти" : "Создать аккаунт")
                }
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !authVM.username.isEmpty && !authVM.password.isEmpty))
            .disabled(authVM.username.isEmpty || authVM.password.isEmpty || authVM.isLoading)
            .padding(.horizontal, Theme.s5)
            .padding(.top, Theme.s4)

            Button {
                Haptics.soft()
                authVM.toggleMode()
            } label: {
                HStack(spacing: 6) {
                    Text(authVM.mode == .login ? "Нет аккаунта?" : "Уже есть аккаунт?")
                        .foregroundStyle(Theme.muted)
                    Text(authVM.mode == .login ? "Создать" : "Войти")
                        .foregroundStyle(Theme.accent)
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(.top, Theme.s4)

            Spacer()
        }
        .animation(.easeOut(duration: 0.2), value: authVM.errorMessage)
        .animation(.easeOut(duration: 0.2), value: authVM.mode)
    }

    @ViewBuilder
    private func fieldRow(placeholder: String, text: Binding<String>, secure: Bool, field: Field) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
                    .textContentType(authVM.mode == .login ? .password : .newPassword)
            } else {
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
            }
        }
        .font(.bodyStrong)
        .focused($focused, equals: field)
        .padding(.horizontal, Theme.s4)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                .stroke(focused == field ? Theme.accent : Theme.border,
                        lineWidth: focused == field ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.15), value: focused)
    }
}
