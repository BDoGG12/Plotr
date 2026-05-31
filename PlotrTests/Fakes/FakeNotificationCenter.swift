import Foundation
import UserNotifications
@testable import Plotr

/// Test double for `NotificationScheduling`. Records every call and returns
/// scripted responses without touching the real notification center.
final class FakeNotificationCenter: NotificationScheduling, @unchecked Sendable {
    // MARK: - Scripted responses

    var authorizationStatusToReturn: UNAuthorizationStatus = .authorized
    var requestAuthorizationResponse: Bool = true
    var requestAuthorizationError: Error?

    // MARK: - Observable state / recorded calls

    /// In-memory store of currently-pending requests. Mirrors the real
    /// center's behaviour: `add` appends, `removePendingNotificationRequests`
    /// filters out matching identifiers.
    var pending: [UNNotificationRequest] = []

    var addCalls: [UNNotificationRequest] = []
    var removeCalls: [[String]] = []
    var requestAuthorizationCallOptions: [UNAuthorizationOptions] = []

    // MARK: - NotificationScheduling

    func add(_ request: UNNotificationRequest) async throws {
        addCalls.append(request)
        pending.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removeCalls.append(identifiers)
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusToReturn
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCallOptions.append(options)
        if let requestAuthorizationError {
            throw requestAuthorizationError
        }
        return requestAuthorizationResponse
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pending
    }
}
