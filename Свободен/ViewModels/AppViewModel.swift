import Foundation

@Observable
@MainActor
final class AppViewModel {
    var isAuthenticated = false
    var currentStatus: UserStatus? = nil
    var isLoadingStatus = false

    init() {
        isAuthenticated = KeychainService.loadToken() != nil
    }

    func onLogin(token: String) {
        KeychainService.saveToken(token)
        isAuthenticated = true
        Task { await refreshStatus() }
    }

    func logout() {
        KeychainService.deleteToken()
        isAuthenticated = false
        currentStatus = nil
    }

    func refreshStatus() async {
        isLoadingStatus = true
        defer { isLoadingStatus = false }
        do {
            currentStatus = try await APIClient.shared.getStatus()
        } catch APIError.httpError(404, _) {
            currentStatus = nil
        } catch {
            // Keep last known status on network error
        }
    }
}
