import UIKit
import UserNotifications

@MainActor
final class PushService: NSObject {
    static let shared = PushService()

    private override init() { super.init() }

    func requestAuthorizationAndRegister() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            do {
                try await APIClient.shared.registerDeviceToken(hex)
            } catch {
                // silently retry on next launch
            }
        }
    }
}

extension PushService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
}
