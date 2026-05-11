import Foundation

// MARK: - Friends

struct Friend: Codable, Identifiable {
    let id: String
    let phone: String
    let statusId: String?
    let expiresAt: Date?
    let activities: [String]?
    let district: String?

    var hasActiveStatus: Bool { statusId != nil }

    enum CodingKeys: String, CodingKey {
        case id, phone, district, activities
        case statusId  = "status_id"
        case expiresAt = "expires_at"
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let fromPhone: String
    let fromId: String

    enum CodingKeys: String, CodingKey {
        case id
        case fromPhone = "from_phone"
        case fromId    = "from_id"
    }
}

// MARK: - Status

struct UserStatus: Codable, Identifiable {
    let id: String
    let expiresAt: Date
    let activities: [String]
    let district: String?

    enum CodingKeys: String, CodingKey {
        case id
        case expiresAt = "expires_at"
        case activities
        case district
    }
}

struct SetStatusRequest: Codable {
    let durationMinutes: Int
    let activities: [String]
    let lat: Double?
    let lon: Double?

    enum CodingKeys: String, CodingKey {
        case durationMinutes = "duration_minutes"
        case activities
        case lat
        case lon
    }
}

enum Activity: String, CaseIterable, Identifiable {
    case cafe   = "кафе"
    case bar    = "бар"
    case cinema = "кино"
    case walk   = "погулять"
    case sport  = "спорт"
    case games  = "игры"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cafe:   return "cup.and.saucer.fill"
        case .bar:    return "wineglass.fill"
        case .cinema: return "film.fill"
        case .walk:   return "figure.walk"
        case .sport:  return "figure.run"
        case .games:  return "gamecontroller.fill"
        }
    }
}

enum DurationOption: CaseIterable, Identifiable {
    case oneHour
    case threeHours
    case tillEvening
    case custom(Date)

    static var allCases: [DurationOption] { [.oneHour, .threeHours, .tillEvening] }

    var id: String { label }

    var label: String {
        switch self {
        case .oneHour:     return "1 ч"
        case .threeHours:  return "3 ч"
        case .tillEvening: return "до вечера"
        case .custom:      return "точное время"
        }
    }

    func durationMinutes(from now: Date = .now) -> Int {
        switch self {
        case .oneHour:    return 60
        case .threeHours: return 180
        case .tillEvening:
            var cal = Calendar.current
            cal.locale = Locale(identifier: "ru_RU")
            let evening = cal.date(bySettingHour: 21, minute: 0, second: 0, of: now) ?? now
            return max(1, Int(evening.timeIntervalSince(now) / 60))
        case .custom(let date):
            return max(1, Int(date.timeIntervalSince(now) / 60))
        }
    }
}
