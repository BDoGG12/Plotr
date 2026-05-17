import Foundation
import Testing
@testable import Plotr

// MARK: - Test helpers
//
// `TeleprompterView`'s default font-size load expression lives inside the
// view's `@State` initializer, which can't be invoked across the test
// boundary. The constant + expression below mirror the production code:
//
//     @State private var fontSize: CGFloat = UserDefaults.standard
//         .object(forKey: "plotr_teleprompter_font_size") as? CGFloat ?? 28
//
// If `TeleprompterView` changes either the key or the default, this mirror
// must change in lockstep — otherwise the test will pass while production
// behaviour drifts.

private let fontSizeKey = "plotr_teleprompter_font_size"

private func loadedFontSize() -> CGFloat {
    UserDefaults.standard.object(forKey: fontSizeKey) as? CGFloat ?? 28
}

@MainActor
struct TeleprompterTests {
    init() {
        // Each `@Test` runs in a fresh struct instance; clear any leaked key
        // from a previous test run so we start from a known-empty state.
        UserDefaults.standard.removeObject(forKey: fontSizeKey)
    }

    // MARK: - Speed → pixelsPerTick

    @Test func test_slowSpeed_pixelsPerTick() {
        #expect(TeleprompterSpeed.slow.pixelsPerTick == 40.0 / 20.0)
        #expect(TeleprompterSpeed.slow.pixelsPerTick == 2.0)
    }

    @Test func test_mediumSpeed_pixelsPerTick() {
        #expect(TeleprompterSpeed.medium.pixelsPerTick == 70.0 / 20.0)
        #expect(TeleprompterSpeed.medium.pixelsPerTick == 3.5)
    }

    @Test func test_fastSpeed_pixelsPerTick() {
        #expect(TeleprompterSpeed.fast.pixelsPerTick == 110.0 / 20.0)
        #expect(TeleprompterSpeed.fast.pixelsPerTick == 5.5)
    }

    // MARK: - Font size persistence

    @Test func test_fontSizeDefaultValue() {
        UserDefaults.standard.removeObject(forKey: fontSizeKey)
        #expect(loadedFontSize() == 28)
    }

    @Test func test_fontSizePersistsToUserDefaults() {
        UserDefaults.standard.set(CGFloat(36), forKey: fontSizeKey)
        #expect(loadedFontSize() == 36)

        // Clean up so we don't leak into the default-value test if test order
        // happens to interleave.
        UserDefaults.standard.removeObject(forKey: fontSizeKey)
    }

    // MARK: - Pro gating

    @Test func test_teleprompterGated_whenExpired() {
        let manager = SubscriptionManager()
        manager.status = .expired
        #expect(manager.isPro == false)
    }

    @Test func test_teleprompterAccessible_whenPro() {
        let manager = SubscriptionManager()
        manager.status = .pro
        #expect(manager.isPro == true)
    }

    @Test func test_teleprompterAccessible_whenTrial() {
        let manager = SubscriptionManager()
        manager.status = .trial
        #expect(manager.isPro == true)
    }
}
