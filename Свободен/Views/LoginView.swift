import SwiftUI

struct LoginView: View {
    @Environment(AppViewModel.self) private var appVM
    @Bindable var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Свободен")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text(authVM.mode == .login ? "Войди в аккаунт" : "Создай аккаунт")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("логин", text: $authVM.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .font(.title3)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                SecureField("пароль", text: $authVM.password)
                    .textContentType(authVM.mode == .login ? .password : .newPassword)
                    .font(.title3)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await authVM.submit { token in
                        appVM.onLogin(token: token)
                    }
                }
            } label: {
                Group {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(authVM.mode == .login ? "Войти" : "Зарегистрироваться")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(authVM.username.isEmpty || authVM.password.isEmpty || authVM.isLoading)
            .padding(.horizontal, 32)

            Button {
                authVM.toggleMode()
            } label: {
                Text(authVM.mode == .login
                     ? "Нет аккаунта? Зарегистрируйся"
                     : "Уже есть аккаунт? Войти")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
