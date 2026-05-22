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

    /// Schedules up to three reminders around a post's due date — the day
    /// before, the day of, and the day after, each at 9:00 AM. No-ops when the
    /// post has no due date, or when notification permission hasn't been
    /// granted. Reminders previously scheduled for this post are cancelled
    /// first, so repeated calls (e.g. each time the due date changes) leave a
    /// single, current set of reminders. Any reminder whose fire time has
    /// already passed is skipped.
    static func scheduleNotifications(for post: Post) async {
        guard let dueDate = post.dueDate else { return }
        guard await checkAuthorizationStatus() else { return }

        let center = UNUserNotificationCenter.current()

        // Drop any reminders left over from a previous due date so repeated
        // calls don't accumulate stale notifications.
        center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: post))

        let calendar = Calendar.current
        let title = post.title.isEmpty ? "Untitled post" : post.title

        for descriptor in reminderDescriptors {
            guard let shiftedDay = calendar.date(
                byAdding: .day,
                value: descriptor.dayOffset,
                to: dueDate
            ) else { continue }

            // Fire at 9:00 AM on the shifted day.
            var components = calendar.dateComponents([.year, .month, .day], from: shiftedDay)
            components.hour = 9
            components.minute = 0
            components.second = 0

            // A past calendar trigger never fires; skip it so we don't
            // register dead requests.
            guard let fireDate = calendar.date(from: components), fireDate >= .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = descriptor.body
            content.sound = .default
            content.categoryIdentifier = "DUE_DATE_REMINDER"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(post.id.uuidString)\(descriptor.suffix)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    /// Cancels every pending due-date reminder for a post. Safe to call when
    /// no reminders are scheduled — unmatched identifiers are simply ignored.
    static func cancelNotifications(for post: Post) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: post))
    }

    /// The three due-date reminders: how far each fires from the due date (in
    /// days), the identifier suffix, and the notification body.
    private static let reminderDescriptors: [(dayOffset: Int, suffix: String, body: String)] = [
        (-1, "_tomorrow", "Your post is due tomorrow. Time to wrap it up!"),
        (0,  "_today",    "Your post is due today. You've got this!"),
        (1,  "_overdue",  "Your post is overdue. Tap to get back on track.")
    ]

    /// Stable per-post notification identifiers — the post id joined with each
    /// reminder suffix. Used to cancel a post's reminders before rescheduling.
    private static func notificationIdentifiers(for post: Post) -> [String] {
        reminderDescriptors.map { "\(post.id.uuidString)\($0.suffix)" }
    }
}
