import Foundation
import Testing
import UserNotifications
@testable import Plotr

// MARK: - Notes on these tests
//
// `NotificationManager` talks directly to `UNUserNotificationCenter.current()`
// with no injection seam, so it can't be unit-tested in isolation — the tests
// below are integration tests against the real, process-wide notification
// center. Two consequences shape the file:
//
//  * `scheduleNotifications(for:)` returns early at its authorization guard
//    unless notifications are authorized. Each scheduling test first requests
//    *provisional* authorization, which the system grants without a prompt.
//    If the host can't grant it, the test records an issue rather than
//    passing silently for the wrong reason.
//  * The notification center is shared process-wide state, so the suite is
//    `.serialized` and every test clears the center before and after.
//
// The robust fix — not possible without touching source — is to give
// `NotificationManager` a notification-center protocol it can be injected
// with, so a fake can be used in tests.

@MainActor
@Suite(.serialized)
struct NotificationTests {

    private let center = UNUserNotificationCenter.current()

    /// One day, in seconds — used to build fixture due dates.
    private let day: TimeInterval = 24 * 60 * 60

    // MARK: - Helpers

    /// Requests provisional authorization (granted without a user prompt) so
    /// `scheduleNotifications` clears its permission guard.
    /// - Returns: whether notifications are authorized for this run.
    private func ensureAuthorization() async -> Bool {
        _ = try? await center.requestAuthorization(options: [.provisional])
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    /// Pending requests whose identifier belongs to the given post.
    private func pendingRequests(for post: Post) async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(post.id.uuidString) }
    }

    private func clearPending() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Scheduling

    @Test func test_scheduleNotifications_schedulesThreeRequests() async {
        guard await ensureAuthorization() else {
            Issue.record("Provisional notification authorization unavailable — cannot exercise scheduling.")
            return
        }
        clearPending()
        defer { clearPending() }

        // Far enough out that all three 9 AM fire times are in the future.
        let post = Post(title: "Future post", dueDate: .now.addingTimeInterval(10 * day))
        await NotificationManager.scheduleNotifications(for: post)

        let pending = await pendingRequests(for: post)
        #expect(pending.count == 3)
    }

    @Test func test_scheduleNotifications_skipsIfNoDueDate() async {
        guard await ensureAuthorization() else {
            Issue.record("Provisional notification authorization unavailable — cannot exercise scheduling.")
            return
        }
        clearPending()
        defer { clearPending() }

        // No due date — `scheduleNotifications` returns at its first guard.
        // Authorization is granted above so 0 reflects the missing due date,
        // not a denied-permission early-out.
        let post = Post(title: "No due date")
        await NotificationManager.scheduleNotifications(for: post)

        let pending = await pendingRequests(for: post)
        #expect(pending.isEmpty)
    }

    @Test func test_scheduleNotifications_skipsPastDates() async {
        guard await ensureAuthorization() else {
            Issue.record("Provisional notification authorization unavailable — cannot exercise scheduling.")
            return
        }
        clearPending()
        defer { clearPending() }

        // Ten days in the past: even the day-after reminder's 9 AM slot has
        // passed, so every reminder should be skipped.
        let post = Post(title: "Past post", dueDate: .now.addingTimeInterval(-10 * day))
        await NotificationManager.scheduleNotifications(for: post)

        let pending = await pendingRequests(for: post)
        #expect(pending.isEmpty)
    }

    // MARK: - Cancellation

    @Test func test_cancelNotifications_removesAllThreeIdentifiers() async {
        guard await ensureAuthorization() else {
            Issue.record("Provisional notification authorization unavailable — cannot exercise scheduling.")
            return
        }
        clearPending()
        defer { clearPending() }

        let post = Post(title: "Cancel me", dueDate: .now.addingTimeInterval(10 * day))
        await NotificationManager.scheduleNotifications(for: post)
        #expect(await pendingRequests(for: post).count == 3)

        NotificationManager.cancelNotifications(for: post)

        let remaining = await pendingRequests(for: post)
        #expect(remaining.isEmpty)
    }

    // MARK: - Identifiers

    @Test func test_notificationIdentifiers_usePostID() async {
        guard await ensureAuthorization() else {
            Issue.record("Provisional notification authorization unavailable — cannot exercise scheduling.")
            return
        }
        clearPending()
        defer { clearPending() }

        let post = Post(title: "ID check", dueDate: .now.addingTimeInterval(10 * day))
        await NotificationManager.scheduleNotifications(for: post)

        let identifiers = Set(await pendingRequests(for: post).map(\.identifier))
        #expect(identifiers == [
            post.id.uuidString + "_tomorrow",
            post.id.uuidString + "_today",
            post.id.uuidString + "_overdue"
        ])
    }

    // MARK: - Trigger times

    @Test func test_dayBeforeNotification_firesAtNineAM() async {
        await assertFiresAtNineAM(identifierSuffix: "_tomorrow")
    }

    @Test func test_dayOfNotification_firesAtNineAM() async {
        await assertFiresAtNineAM(identifierSuffix: "_today")
    }

    @Test func test_overdueNotification_firesAtNineAM() async {
        await assertFiresAtNineAM(identifierSuffix: "_overdue")
    }

    /// Schedules a post far enough in the future that all three reminders are
    /// created, then verifies the named reminder's calendar trigger fires at
    /// 09:00.
    private func assertFiresAtNineAM(identifierSuffix: String) async {
        guard await ensureAuthorization() else {
            Issue.record("Provisional notification authorization unavailable — cannot exercise scheduling.")
            return
        }
        clearPending()
        defer { clearPending() }

        let post = Post(title: "Trigger time", dueDate: .now.addingTimeInterval(10 * day))
        await NotificationManager.scheduleNotifications(for: post)

        let request = await pendingRequests(for: post)
            .first { $0.identifier == post.id.uuidString + identifierSuffix }

        guard let trigger = request?.trigger as? UNCalendarNotificationTrigger else {
            Issue.record("No calendar trigger found for reminder \(identifierSuffix).")
            return
        }
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
    }
}
