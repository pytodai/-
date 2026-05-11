import Foundation

@Observable
@MainActor
final class AppViewModel {
    var isAuthenticated = false
    var currentStatus: UserStatus? = nil
    var isLoadingStatus = false
    let ws = WebSocketService()

    init() {
        isAuthenticated = KeychainService.loadToken() != nil
        if isAuthenticated {
            ws.connect()
            PushService.shared.requestAuthorizationAndRegister()
        }
    }

    func onLogin(token: String) {
        KeychainService.saveToken(token)
        isAuthenticated = true
        ws.connect()
        PushService.shared.requestAuthorizationAndRegister()
        Task { await refreshStatus() }
    }

    func logout() {
        ws.disconnect()
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
