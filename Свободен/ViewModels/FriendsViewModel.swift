import Foundation

@Observable
@MainActor
final class FriendsViewModel {
    var friends: [Friend] = []
    var pendingRequests: [FriendRequest] = []
    var isLoading = false
    var errorMessage: String?

    private let ws: WebSocketService

    init(ws: WebSocketService) {
        self.ws = ws
        ws.onMessage = { [weak self] msg in
            Task { @MainActor [weak self] in
                self?.handleWSMessage(msg)
            }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let friendsTask = loadFriends()
        async let requestsTask = loadRequests()
        await friendsTask
        await requestsTask
    }

    private func loadFriends() async {
        do {
            friends = try await APIClient.shared.getFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRequests() async {
        do {
            pendingRequests = try await APIClient.shared.getPendingRequests()
        } catch {
            // Ignore requests fetch errors silently
        }
    }

    func sendRequest(phone: String) async throws {
        try await APIClient.shared.sendFriendRequest(phone: phone)
    }

    func accept(request: FriendRequest) async {
        do {
            try await APIClient.shared.acceptRequest(id: request.id)
            pendingRequests.removeAll { $0.id == request.id }
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(request: FriendRequest) async {
        do {
            try await APIClient.shared.declineRequest(id: request.id)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friend: Friend) async {
        do {
            try await APIClient.shared.removeFriend(id: friend.id)
            friends.removeAll { $0.id == friend.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleWSMessage(_ msg: WSMessage) {
        guard let userId = msg.userId else { return }
        switch msg.type {
        case "status_set":
            if let idx = friends.firstIndex(where: { $0.id == userId }) {
                let f = friends[idx]
                let isoFormatter = ISO8601DateFormatter()
                let expiresAt = msg.data?.expiresAt
                friends[idx] = Friend(
                    id: f.id,
                    phone: f.phone,
                    statusId: "live",
                    expiresAt: expiresAt.flatMap { isoFormatter.date(from: $0) },
                    activities: msg.data?.activities ?? [],
                    district: msg.data?.district
                )
            }
        case "status_cleared":
            if let idx = friends.firstIndex(where: { $0.id == userId }) {
                let f = friends[idx]
                friends[idx] = Friend(
                    id: f.id, phone: f.phone,
                    statusId: nil, expiresAt: nil,
                    activities: nil, district: nil
                )
            }
        default:
            break
        }
    }
}
