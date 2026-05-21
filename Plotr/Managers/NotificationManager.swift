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

    /// Schedules reminder notifications for a post's due date. No-ops when the
    /// post has no due date, or when notification permission hasn't been
    /// granted. Reminders previously scheduled for this post are cancelled
    /// first, so repeated calls (e.g. each time the due date changes) leave a
    /// single, current set of reminders.
    ///
    /// - Note: The three trigger times below are placeholders — the real
    ///   scheduling offsets land in PLOT-94.
    static func scheduleNotifications(for post: Post) async {
        guard let dueDate = post.dueDate else { return }
        guard await checkAuthorizationStatus() else { return }

        let center = UNUserNotificationCenter.current()
        let identifiers = notificationIdentifiers(for: post)

        // Drop any reminders left over from a previous due date so repeated
        // calls don't accumulate stale notifications.
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        // Placeholder fire times — replaced with real offsets in PLOT-94.
        let day: TimeInterval = 24 * 60 * 60
        let placeholderFireDates = [
            dueDate.addingTimeInterval(-7 * day),
            dueDate.addingTimeInterval(-1 * day),
            dueDate
        ]

        let title = post.title.isEmpty ? "Untitled post" : post.title

        for (index, fireDate) in placeholderFireDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "This post is due soon."
            content.sound = .default

            // A calendar trigger is used (rather than a time-interval one)
            // because a past calendar date simply doesn't fire, whereas a
            // negative time interval traps at runtime.
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: identifiers[index],
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    /// Stable per-post notification identifiers, of the form `<post id>-<n>`.
    private static func notificationIdentifiers(for post: Post) -> [String] {
        (0..<3).map { "\(post.id.uuidString)-\($0)" }
    }
}
