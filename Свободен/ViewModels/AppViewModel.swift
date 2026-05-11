import Foundation

@Observable
@MainActor
final class AppViewModel {
    var isAuthenticated = false
    var currentStatus: UserStatus? = nil
    var isLoadingStatus = false
    let ws = WebSocketService()
    let liveActivity = LiveActivityService()

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
        liveActivity.stop()
        KeychainService.deleteToken()
        isAuthenticated = false
        currentStatus = nil
    }

    func refreshStatus() async {
        isLoadingStatus = true
        defer { isLoadingStatus = false }
        do {
            let status = try await APIClient.shared.getStatus()
            applyStatus(status)
        } catch APIError.httpError(404, _) {
            applyStatus(nil)
        } catch {
            // Keep last known status on network error
        }
    }

    func applyStatus(_ status: UserStatus?) {
        let previous = currentStatus
        currentStatus = status
        if let status {
            if previous == nil {
                liveActivity.start(status: status, username: usernameFromToken() ?? "me")
            } else {
                liveActivity.update(status: status)
            }
        } else {
            liveActivity.stop()
        }
    }

    private func usernameFromToken() -> String? {
        guard let token = KeychainService.loadToken() else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
        while payload.count % 4 != 0 { payload.append("=") }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let username = json["username"] as? String else { return nil }
        return username
    }
}
