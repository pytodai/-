import Foundation

enum AuthMode {
    case login
    case register
}

@Observable
@MainActor
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    var mode: AuthMode = .login
    var username = ""
    var password = ""

    func submit(onSuccess: (String) -> Void) async {
        let user = username.trimmingCharacters(in: .whitespaces).lowercased()
        guard !user.isEmpty, !password.isEmpty else {
            errorMessage = "Введите имя и пароль"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token: String
            switch mode {
            case .login:
                token = try await APIClient.shared.login(username: user, password: password)
            case .register:
                token = try await APIClient.shared.register(username: user, password: password)
            }
            onSuccess(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleMode() {
        mode = (mode == .login) ? .register : .login
        errorMessage = nil
    }
}
