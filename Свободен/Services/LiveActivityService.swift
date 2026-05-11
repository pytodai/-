import ActivityKit
import Foundation

struct StatusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var expiresAt: Date
        var activities: [String]
        var district: String?
    }

    let username: String
}

@Observable
@MainActor
final class LiveActivityService {
    private var activity: ActivityKit.Activity<StatusActivityAttributes>?

    func start(status: UserStatus, username: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attrs = StatusActivityAttributes(username: username)
        let state = StatusActivityAttributes.ContentState(
            expiresAt: status.expiresAt,
            activities: status.activities,
            district: status.district
        )
        let content = ActivityContent(state: state, staleDate: status.expiresAt)

        do {
            activity = try ActivityKit.Activity.request(
                attributes: attrs,
                content: content,
                pushType: nil
            )
        } catch {
            // Live Activity unavailable (simulator or entitlement missing)
        }
    }

    func update(status: UserStatus) {
        guard let activity else { return }
        let state = StatusActivityAttributes.ContentState(
            expiresAt: status.expiresAt,
            activities: status.activities,
            district: status.district
        )
        let content = ActivityContent(state: state, staleDate: status.expiresAt)
        Task {
            await activity.update(content)
        }
    }

    func stop() {
        guard let activity else { return }
        Task {
            let policy = ActivityUIDismissalPolicy.immediate
            await activity.end(nil, dismissalPolicy: policy)
            self.activity = nil
        }
    }
}
