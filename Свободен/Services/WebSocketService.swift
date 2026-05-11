import Foundation

struct WSMessage: Decodable {
    let type: String
    let userId: String?
    let data: WSData?

    enum CodingKeys: String, CodingKey {
        case type
        case userId = "user_id"
        case data
    }
}

struct WSData: Decodable {
    let expiresAt: String?
    let activities: [String]?
    let district: String?

    enum CodingKeys: String, CodingKey {
        case expiresAt = "expires_at"
        case activities, district
    }
}

@Observable
@MainActor
final class WebSocketService {
    var isConnected = false
    private var task: URLSessionWebSocketTask?
    private var reconnectTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?

    var onMessage: ((WSMessage) -> Void)?

    func connect() {
        guard let token = KeychainService.loadToken() else { return }
        guard let url = URL(string: "wss://api.artem.sokolov.me/ws") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        task = URLSession.shared.webSocketTask(with: req)
        task?.resume()
        isConnected = true
        receive()
        startPing()
    }

    func disconnect() {
        reconnectTask?.cancel()
        pingTask?.cancel()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    private func receive() {
        task?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let msg):
                    if case .string(let text) = msg,
                       let data = text.data(using: .utf8),
                       let wsMsg = try? JSONDecoder().decode(WSMessage.self, from: data) {
                        self.onMessage?(wsMsg)
                    }
                    self.receive()
                case .failure:
                    self.isConnected = false
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func startPing() {
        pingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                self?.task?.sendPing { _ in }
            }
        }
    }

    private func scheduleReconnect() {
        reconnectTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.connect()
        }
    }
}
