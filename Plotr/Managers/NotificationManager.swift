import Foundation
import UserNotifications

/// Adapter protocol the manager depends on. Lets tests inject a fake center
/// without touching the real `UNUserNotificationCenter`.
protocol NotificationScheduling {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers: [String])
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: NotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}

/// Centralised handling of local-notification permission requests, status
/// checks, and due-date reminder scheduling.
///
/// Existing callers use the static facade (`NotificationManager.scheduleNotifications(for:)`
/// etc.), which dispatches to a shared `current` instance. The instance accepts
/// a `NotificationScheduling`-conforming adapter, defaulting to the real
/// `UNUserNotificationCenter`. Tests can swap `current` for an instance backed
/// by a fake, then restore it afterwards.
final class NotificationManager {
    /// Shared instance used by the static facade. Tests may swap this out
    /// and should restore it afterwards (e.g. via `defer` or `deinit`).
    static var current = NotificationManager()

    private let center: NotificationScheduling

    init(center: NotificationScheduling = UNUserNotificationCenter.current()) {
        self.center = center
    }

    // MARK: - Instance API

    /// Requests alert, badge, and sound permissions from the system.
    /// - Returns: `true` if granted, `false` if denied or the request threw.
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Reads the current notification authorization status without prompting.
    /// - Returns: `true` when authorized or provisionally authorized.
    func checkAuthorizationStatus() async -> Bool {
        let status = await center.authorizationStatus()
        print("[Notifications] Authorization status: \(status.rawValue)")
        return switch status {
        case .authorized, .provisional: true
        default: false
        }
    }

    /// Schedules up to three reminders around `post.dueDate` (day before, day
    /// of, day after — each at 9:00 AM). No-ops without a due date or without
    /// authorization. Previously-scheduled reminders for this post are
    /// cancelled first. Past fire times are skipped.
    func scheduleNotifications(for post: Post) async {
        guard let dueDate = post.dueDate else { return }
        guard await checkAuthorizationStatus() else { return }

        center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: post))

        let calendar = Calendar.current
        let title = post.title.isEmpty ? "Untitled post" : post.title

        for descriptor in Self.reminderDescriptors {
            guard let shiftedDay = calendar.date(
                byAdding: .day,
                value: descriptor.dayOffset,
                to: dueDate
            ) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: shiftedDay)
            components.hour = 9
            components.minute = 0
            components.second = 0

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

    /// Cancels every pending due-date reminder for a post.
    func cancelNotifications(for post: Post) {
        center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: post))
    }

    // MARK: - Static facade
    //
    // Preserves every existing call site (PostDetailViewModel, PlotrApp,
    // tests) — the static methods just dispatch to `current`.

    static func requestPermission() async -> Bool {
        await current.requestPermission()
    }

    static func checkAuthorizationStatus() async -> Bool {
        await current.checkAuthorizationStatus()
    }

    static func scheduleNotifications(for post: Post) async {
        await current.scheduleNotifications(for: post)
    }

    static func cancelNotifications(for post: Post) {
        current.cancelNotifications(for: post)
    }

    // MARK: - Reminder data

    /// The three due-date reminders: how far each fires from the due date
    /// (in days), the identifier suffix, and the notification body.
    private static let reminderDescriptors: [(dayOffset: Int, suffix: String, body: String)] = [
        (-1, "_tomorrow", "Your post is due tomorrow. Time to wrap it up!"),
        (0,  "_today",    "Your post is due today. You've got this!"),
        (1,  "_overdue",  "Your post is overdue. Tap to get back on track.")
    ]

    /// Stable per-post notification identifiers — the post id joined with
    /// each reminder suffix. Used to cancel before rescheduling.
    private func notificationIdentifiers(for post: Post) -> [String] {
        Self.reminderDescriptors.map { "\(post.id.uuidString)\($0.suffix)" }
    }
}
