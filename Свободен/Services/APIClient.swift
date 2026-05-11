import Foundation

enum APIError: Error, LocalizedError {
    case notAuthenticated
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:        return "Not authenticated"
        case .httpError(let c, let m): return "HTTP \(c): \(m)"
        case .decodingError(let e):    return "Decode error: \(e.localizedDescription)"
        case .networkError(let e):     return e.localizedDescription
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://localhost:8080")!

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    func requestCode(phone: String) async throws {
        let body = ["phone": phone]
        _ = try await post(path: "/auth/phone/request", body: body, token: nil) as [String: String]
    }

    func verifyCode(phone: String, code: String) async throws -> String {
        let body = ["phone": phone, "code": code]
        let resp = try await post(path: "/auth/phone/verify", body: body, token: nil) as [String: String]
        guard let token = resp["token"] else {
            throw APIError.httpError(200, "missing token in response")
        }
        return token
    }

    func getStatus() async throws -> UserStatus {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        return try await get(path: "/me/status", token: token)
    }

    func setStatus(_ request: SetStatusRequest) async throws -> UserStatus {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        return try await put(path: "/me/status", body: request, token: token)
    }

    func deleteStatus() async throws {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        try await deleteReq(path: "/me/status", token: token)
    }

    // MARK: - Friends

    func getFriends() async throws -> [Friend] {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        return try await get(path: "/friends", token: token)
    }

    func sendFriendRequest(phone: String) async throws {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        let body = ["phone": phone]
        _ = try await post(path: "/friends/requests", body: body, token: token) as [String: String]
    }

    func getPendingRequests() async throws -> [FriendRequest] {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        return try await get(path: "/friends/requests", token: token)
    }

    func acceptRequest(id: String) async throws {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        try await postNoContent(path: "/friends/requests/\(id)/accept", token: token)
    }

    func declineRequest(id: String) async throws {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        try await postNoContent(path: "/friends/requests/\(id)/decline", token: token)
    }

    func removeFriend(id: String) async throws {
        guard let token = KeychainService.loadToken() else { throw APIError.notAuthenticated }
        try await deleteReq(path: "/friends/\(id)", token: token)
    }

    private func get<T: Decodable>(path: String, token: String?) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "GET"
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await perform(req)
    }

    private func post<B: Encodable, T: Decodable>(path: String, body: B, token: String?) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await perform(req)
    }

    private func put<B: Encodable, T: Decodable>(path: String, body: B, token: String?) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await perform(req)
    }

    private func deleteReq(path: String, token: String?) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "DELETE"
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (_, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw APIError.httpError(http.statusCode, "")
        }
    }

    // Workaround for 204 No Content responses where we don't need a body
    private func postNoContent(path: String, token: String?) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (_, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw APIError.httpError(http.statusCode, "")
        }
    }

    private func perform<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        if http.statusCode >= 400 {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? ""
            throw APIError.httpError(http.statusCode, msg)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
