import Foundation
import SwiftData
import Testing
import UserNotifications
@testable import Plotr

/// Tests for `NotificationManager`'s due-date reminder behaviour and the
/// `PostDetailViewModel` integration that drives it.
///
/// Both surfaces share `NotificationManager.current` as their entry point,
/// so they live in one class-based suite. `init`/`deinit` swaps the static
/// `current` to a manager backed by a `FakeNotificationCenter` for each
/// test, and restores it afterwards — keeping the fake-injection contained
/// and avoiding parallel-execution collisions across separate test files.
@MainActor
final class NotificationTests {
    private let fakeCenter: FakeNotificationCenter
    private let previousManager: NotificationManager

    init() {
        fakeCenter = FakeNotificationCenter()
        fakeCenter.authorizationStatusToReturn = .authorized
        previousManager = NotificationManager.current
        NotificationManager.current = NotificationManager(center: fakeCenter)
    }

    deinit {
        NotificationManager.current = previousManager
    }

    // MARK: - Helpers

    private func futureDate() -> Date {
        .now.addingTimeInterval(10 * 24 * 60 * 60)
    }

    /// Drains the view-model's fire-and-forget `Task { ... }` closures. The
    /// fake's async methods don't touch real I/O, so a handful of yields
    /// covers the chain of awaits inside `scheduleNotifications`.
    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
    }

    private func request(matching suffix: String, for post: Post) -> UNNotificationRequest? {
        fakeCenter.pending.first { $0.identifier == post.id.uuidString + suffix }
    }

    // MARK: - NotificationManager: scheduling

    @Test func test_scheduleNotifications_schedulesThreeRequests() async {
        let post = Post(title: "Future post", dueDate: futureDate())
        await NotificationManager.scheduleNotifications(for: post)

        #expect(fakeCenter.addCalls.count == 3)
        #expect(fakeCenter.pending.count == 3)
    }

    @Test func test_scheduleNotifications_skipsIfNoDueDate() async {
        let post = Post(title: "No due date")   // dueDate defaults to nil
        await NotificationManager.scheduleNotifications(for: post)

        #expect(fakeCenter.addCalls.isEmpty)
    }

    @Test func test_scheduleNotifications_skipsPastDates() async {
        // Ten days ago — every reminder's 9 AM slot is in the past.
        let post = Post(title: "Past post", dueDate: .now.addingTimeInterval(-10 * 24 * 60 * 60))
        await NotificationManager.scheduleNotifications(for: post)

        #expect(fakeCenter.addCalls.isEmpty)
    }

    @Test func test_scheduleNotifications_notCalledWhenNotAuthorized() async {
        fakeCenter.authorizationStatusToReturn = .denied

        let post = Post(title: "No auth", dueDate: futureDate())
        await NotificationManager.scheduleNotifications(for: post)

        #expect(fakeCenter.addCalls.isEmpty)
    }

    // MARK: - NotificationManager: cancellation

    @Test func test_cancelNotifications_removesAllThreeIdentifiers() async {
        let post = Post(title: "Cancel me", dueDate: futureDate())
        await NotificationManager.scheduleNotifications(for: post)
        #expect(fakeCenter.pending.count == 3)

        NotificationManager.cancelNotifications(for: post)

        #expect(fakeCenter.pending.isEmpty)
    }

    @Test func test_notificationIdentifiers_usePostID() async {
        let post = Post(title: "ID check", dueDate: futureDate())
        await NotificationManager.scheduleNotifications(for: post)

        let identifiers = Set(fakeCenter.pending.map(\.identifier))
        #expect(identifiers == [
            post.id.uuidString + "_tomorrow",
            post.id.uuidString + "_today",
            post.id.uuidString + "_overdue"
        ])
    }

    @Test func test_cancelNotifications_calledWithCorrectPostID() async {
        let post = Post(title: "Cancel identifiers", dueDate: futureDate())
        await NotificationManager.scheduleNotifications(for: post)

        NotificationManager.cancelNotifications(for: post)

        let expected: Set<String> = [
            post.id.uuidString + "_tomorrow",
            post.id.uuidString + "_today",
            post.id.uuidString + "_overdue"
        ]
        let cancelCall = fakeCenter.removeCalls.last ?? []
        #expect(Set(cancelCall) == expected)
    }

    // MARK: - Trigger times

    @Test func test_dayBeforeNotification_firesAtNineAM() async {
        try? await assertFiresAtNineAM(suffix: "_tomorrow")
    }

    @Test func test_dayOfNotification_firesAtNineAM() async {
        try? await assertFiresAtNineAM(suffix: "_today")
    }

    @Test func test_overdueNotification_firesAtNineAM() async {
        try? await assertFiresAtNineAM(suffix: "_overdue")
    }

    private func assertFiresAtNineAM(suffix: String) async throws {
        let post = Post(title: "Trigger time", dueDate: futureDate())
        await NotificationManager.scheduleNotifications(for: post)

        let scheduled = try #require(request(matching: suffix, for: post))
        let trigger = try #require(scheduled.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
    }

    // MARK: - PostDetailViewModel integration

    @Test func test_dueDateToggled_true_schedulesNotifications() async {
        let viewModel = PostDetailViewModel()
        viewModel.dueDateValue = futureDate()
        let post = Post(title: "Toggle on")

        viewModel.dueDateToggled(true, post: post)
        await settle()

        #expect(fakeCenter.addCalls.count == 3)
        #expect(fakeCenter.pending.count == 3)
    }

    @Test func test_dueDateToggled_false_cancelsNotifications() async {
        let viewModel = PostDetailViewModel()
        viewModel.dueDateValue = futureDate()
        let post = Post(title: "Toggle off")

        viewModel.dueDateToggled(true, post: post)
        await settle()
        #expect(fakeCenter.pending.count == 3)

        viewModel.dueDateToggled(false, post: post)
        #expect(fakeCenter.pending.isEmpty)
    }

    @Test func test_dueDateChanged_schedulesNotifications() async {
        let viewModel = PostDetailViewModel()
        viewModel.hasDueDate = true
        let post = Post(title: "Date change")

        viewModel.dueDateChanged(futureDate(), post: post)
        await settle()

        #expect(fakeCenter.addCalls.count == 3)
    }

    @Test func test_deletePost_cancelsNotificationsBeforeDeleting() async throws {
        let context = try TestSupport.makeContext()
        let post = TestSupport.insertPost(
            title: "Delete me",
            dueDate: futureDate(),
            in: context
        )
        try context.save()

        await NotificationManager.scheduleNotifications(for: post)
        #expect(fakeCenter.pending.count == 3)

        let viewModel = PostDetailViewModel()
        viewModel.delete(post, context: context)
        try context.save()

        #expect(fakeCenter.pending.isEmpty)
        #expect(try context.fetch(FetchDescriptor<Post>()).isEmpty)
    }
}
