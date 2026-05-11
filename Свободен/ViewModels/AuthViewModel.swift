import Foundation

@Observable
@MainActor
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    var codeSent = false
    var phone = ""

    func requestCode() async {
        guard !phone.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await APIClient.shared.requestCode(phone: phone)
            codeSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verifyCode(_ code: String, onSuccess: (String) -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = try await APIClient.shared.verifyCode(phone: phone, code: code)
            onSuccess(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
