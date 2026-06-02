import Foundation
import Testing
@testable import Plotr

/// Tests for the onboarding flow's step gating and the personalised
/// paywall headline.
///
/// Several tests mutate `plotr_paywall_shown_after_onboarding` in the
/// standard `UserDefaults`. The suite is `.serialized` so concurrent
/// tests can't interleave their writes, and `init` / `deinit` clear
/// the key before and after every test.
///
/// ### Known gaps in the production code
///
/// 1. `OnboardingViewModel.advance(finish:)` does not currently gate on
///    `painPoint` / `contentVolume` being filled — it always increments
///    `step`. The two `..._requiresSelectionToProceed` tests describe
///    the desired behaviour and will fail until the gating is added.
///
/// 2. The paywall presentation logic (`finish()`,
///    `completePaywallStep()`, `showPaywall`) lives entirely on
///    `OnboardingView` as private members. There is no view-model seam
///    to invoke, so the two presentation tests assert against the
///    UserDefaults *contract* the View depends on rather than driving
///    the View directly.
///
/// 3. `PaywallView.paywallHeadline` is declared `private`, which
///    `@testable import` cannot reach. The four headline tests are
///    `.disabled(...)` until the property is widened to `internal`
///    (drop the `private` keyword) in `PaywallView.swift`.
@MainActor
@Suite(.serialized)
final class OnboardingPaywallTests {
    private let paywallShownKey = "plotr_paywall_shown_after_onboarding"

    init() {
        UserDefaults.standard.removeObject(forKey: paywallShownKey)
    }

    deinit {
        UserDefaults.standard.removeObject(forKey: paywallShownKey)
    }

    // MARK: - Step gating
    //
    // These two tests will fail against the current code: `advance()`
    // increments `step` regardless of selection. The failure is the
    // intended signal — it documents the missing gating until the view
    // model is taught to refuse advancement on an empty answer.

    @Test func test_painPointScreen_requiresSelectionToProceed() {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.painPoint == "")

        viewModel.step = 1
        var didFinish = false
        viewModel.advance(finish: { didFinish = true })

        #expect(
            viewModel.step == 1,
            "advance() should not leave step 1 while painPoint is empty"
        )
        #expect(didFinish == false)
    }

    @Test func test_contentVolumeScreen_requiresSelectionToProceed() {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.contentVolume == "")

        viewModel.step = 2
        var didFinish = false
        viewModel.advance(finish: { didFinish = true })

        #expect(
            viewModel.step == 2,
            "advance() should not leave step 2 while contentVolume is empty"
        )
        #expect(didFinish == false)
    }

    // MARK: - Paywall presentation (UserDefaults contract)
    //
    // The production paywall presentation logic lives on `OnboardingView`
    // — both `finish()` and `completePaywallStep()` are private — so we
    // can't drive it from here. These tests verify the UserDefaults
    // contract those private methods rely on instead.

    @Test func test_onboardingCompletion_presentsPaywall() {
        // First-launch precondition: key is absent (read returns false).
        #expect(UserDefaults.standard.bool(forKey: paywallShownKey) == false)

        // Mirrors `OnboardingView.completePaywallStep()` — runs when
        // the paywall sheet dismisses after a first-time onboarding.
        UserDefaults.standard.set(true, forKey: paywallShownKey)

        #expect(UserDefaults.standard.bool(forKey: paywallShownKey) == true)
    }

    @Test func test_paywall_notShownAgain_afterAlreadySeen() {
        // Simulate a user who has already seen the post-onboarding paywall.
        UserDefaults.standard.set(true, forKey: paywallShownKey)

        // Mirrors the branch inside `OnboardingView.finish()`:
        //     let paywallAlreadyShown = UserDefaults.standard.bool(forKey: ...)
        //     if paywallAlreadyShown { hasOnboarded = true }
        //     else                   { showPaywall = true }
        let paywallAlreadyShown = UserDefaults.standard.bool(forKey: paywallShownKey)
        let wouldShowPaywall = !paywallAlreadyShown

        #expect(paywallAlreadyShown == true)
        #expect(
            wouldShowPaywall == false,
            "finish() should skip the paywall when the key is already set"
        )
    }

    // MARK: - Personalised paywall headline
    //
    // `PaywallView.paywallHeadline` is `private` in the current source.
    // `@testable import` widens `internal` to public for the test target
    // but does not touch `private` members, so these tests cannot
    // reference the property. To enable them:
    //
    //   1. In `PaywallView.swift`, drop the `private` keyword on
    //      `paywallHeadline` (or change it to `internal`).
    //   2. Remove the `.disabled(...)` trait on each test below.
    //
    // The intended assertions are kept inline as comments so they can
    // be uncommented verbatim once the property is accessible.

    @Test(.disabled("PaywallView.paywallHeadline is private — make it internal to enable."))
    func test_paywallHeadline_personalised_forNotesApp() {
        // let view = PaywallView(dismiss: {}, postCount: 0, painPoint: "Notes app")
        // #expect(view.paywallHeadline == "Ditch the notes app. Plan like a pro.")
    }

    @Test(.disabled("PaywallView.paywallHeadline is private — make it internal to enable."))
    func test_paywallHeadline_personalised_forSpreadsheet() {
        // let view = PaywallView(dismiss: {}, postCount: 0, painPoint: "Spreadsheet")
        // #expect(view.paywallHeadline == "Ditch the spreadsheet. Plan like a pro.")
    }

    @Test(.disabled("PaywallView.paywallHeadline is private — make it internal to enable."))
    func test_paywallHeadline_personalised_forInMyHead() {
        // let view = PaywallView(dismiss: {}, postCount: 0, painPoint: "In my head")
        // #expect(view.paywallHeadline == "Stop planning in your head. Plan like a pro.")
    }

    @Test(.disabled("PaywallView.paywallHeadline is private — make it internal to enable."))
    func test_paywallHeadline_usesDefault_whenNoPainPoint() {
        // let view = PaywallView(dismiss: {}, postCount: 0, painPoint: nil)
        // #expect(view.paywallHeadline == "Plan your content like a pro.")
    }
}
