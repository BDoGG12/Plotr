import Foundation
import UserNotifications

/// Centralised handling of local-notification permission requests and status
/// checks. All members are static — `NotificationManager` is a namespace, not
/// an instantiable type.
final class NotificationManager {
    /// Requests alert, badge, and sound permissions from the system.
    /// - Returns: `true` if the user granted permission; `false` if they
    ///   denied it or the request threw.
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Reads the current notification authorization status without prompting
    /// the user.
    /// - Returns: `true` when notifications are authorized or provisionally
    ///   authorized; `false` otherwise.
    static func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return switch settings.authorizationStatus {
        case .authorized, .provisional: true
        default: false
        }
    }
}
