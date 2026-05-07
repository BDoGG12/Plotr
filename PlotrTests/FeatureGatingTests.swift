import Foundation
import SwiftData
import Testing
@testable import Plotr

/// Mirrors the gate predicate in `BoardView.handleAddTapped(in:)`:
/// `!subscriptionManager.isPro && posts.count >= freePostLimit`.
/// Re-implemented here because the gate lives inside a SwiftUI view body
/// and cannot be exercised directly from a test target.
private func shouldShowPaywall(
    subscriptionManager: SubscriptionManager,
    postCount: Int,
    freePostLimit: Int = 5
) -> Bool {
    !subscriptionManager.isPro && postCount >= freePostLimit
}

@MainActor
struct FeatureGatingTests {
    // MARK: - Post creation gating

    @Test func test_postCreationBlocked_whenExpiredAndFivePostsExist() throws {
        let context = try TestSupport.makeContext()
        for i in 0..<5 {
            _ = TestSupport.insertPost(title: "Post \(i)", in: context)
        }
        try context.save()

        let subscription = SubscriptionManager()
        subscription.status = .expired

        let posts = try context.fetch(FetchDescriptor<Post>())
        #expect(posts.count == 5)
        #expect(shouldShowPaywall(subscriptionManager: subscription, postCount: posts.count) == true)
    }

    @Test func test_postCreationAllowed_whenProAndFivePostsExist() throws {
        let context = try TestSupport.makeContext()
        for i in 0..<5 {
            _ = TestSupport.insertPost(title: "Post \(i)", in: context)
        }
        try context.save()

        let subscription = SubscriptionManager()
        subscription.status = .pro

        let posts = try context.fetch(FetchDescriptor<Post>())
        #expect(posts.count == 5)
        #expect(shouldShowPaywall(subscriptionManager: subscription, postCount: posts.count) == false)
    }

    @Test func test_postCreationAllowed_whenTrialAndFivePostsExist() throws {
        let context = try TestSupport.makeContext()
        for i in 0..<5 {
            _ = TestSupport.insertPost(title: "Post \(i)", in: context)
        }
        try context.save()

        let subscription = SubscriptionManager()
        subscription.status = .trial

        let posts = try context.fetch(FetchDescriptor<Post>())
        #expect(posts.count == 5)
        #expect(shouldShowPaywall(subscriptionManager: subscription, postCount: posts.count) == false)
    }

    // MARK: - Footage section gating (drives `subscriptionManager.isPro`)

    @Test func test_footageSectionHidden_whenExpired() {
        let subscription = SubscriptionManager()
        subscription.status = .expired
        #expect(subscription.isPro == false)
    }

    @Test func test_footageSectionVisible_whenPro() {
        let subscription = SubscriptionManager()
        subscription.status = .pro
        #expect(subscription.isPro == true)
    }

    @Test func test_footageSectionVisible_whenTrial() {
        let subscription = SubscriptionManager()
        subscription.status = .trial
        #expect(subscription.isPro == true)
    }
}
