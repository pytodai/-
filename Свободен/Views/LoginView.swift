import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var authVM: AuthViewModel
    @FocusState private var focused: Field?

    enum Field { case username, password }

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: Theme.s5) {
                Spacer(minLength: 60)

                VStack(spacing: Theme.s2) {
                    Text("Свободен")
                        .font(.displayLarge)
                        .foregroundStyle(Theme.sunsetGradient)
                    Text(authVM.mode == .login ? "С возвращением!" : "Привет, новенький")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, Theme.s2)

                VStack(spacing: Theme.s3) {
                    fieldRow(icon: "at", placeholder: "логин", text: $authVM.username, secure: false, field: .username)
                    fieldRow(icon: "lock.fill", placeholder: "пароль", text: $authVM.password, secure: true, field: .password)
                }
                .padding(.horizontal, Theme.s5)

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.s5)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
                    HStack {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(authVM.mode == .login ? "Войти" : "Зарегистрироваться")
                        }
                    }
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(authVM.username.isEmpty || authVM.password.isEmpty || authVM.isLoading)
                .opacity((authVM.username.isEmpty || authVM.password.isEmpty) ? 0.55 : 1)
                .padding(.horizontal, Theme.s5)

                Button {
                    Haptics.soft()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        authVM.toggleMode()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(authVM.mode == .login ? "Нет аккаунта?" : "Уже есть аккаунт?")
                            .foregroundStyle(.secondary)
                        Text(authVM.mode == .login ? "Зарегистрируйся" : "Войти")
                            .foregroundStyle(Theme.coral)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
            .animation(.easeInOut, value: authVM.errorMessage)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: authVM.mode)
        }
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, secure: Bool, field: Field) -> some View {
        HStack(spacing: Theme.s3) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(focused == field ? Theme.coral : .secondary)
                .frame(width: 22)
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
        }
        .padding(.horizontal, Theme.s4)
        .padding(.vertical, Theme.s3 + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rMd, style: .continuous)
                .stroke(focused == field ? Theme.coral.opacity(0.6) : Theme.border, lineWidth: focused == field ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: focused)
    }
}
