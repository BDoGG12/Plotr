import Foundation
import Testing
@testable import Plotr

@MainActor
struct OnboardingViewModelTests {
    @Test func togglePlatformAddsAndRemoves() {
        let vm = OnboardingViewModel()

        vm.togglePlatform(.youtube)
        #expect(vm.selected == [.youtube])

        vm.togglePlatform(.tiktok)
        #expect(vm.selected == [.youtube, .tiktok])

        vm.togglePlatform(.youtube)
        #expect(vm.selected == [.tiktok])
    }

    @Test func goBackOnFirstStepIsNoOp() {
        let vm = OnboardingViewModel()
        vm.goBack()
        #expect(vm.step == 0)
    }

    @Test func advanceFromStepZeroMovesToStepOne() {
        let vm = OnboardingViewModel()
        var finished = false

        vm.advance { finished = true }

        #expect(vm.step == 1)
        #expect(finished == false)
    }

    @Test func advanceFromFinalStepCallsFinish() {
        // Onboarding now has five steps (0…4). `finish` only fires from
        // the last one — step 4 (the value-prop screen).
        let vm = OnboardingViewModel()
        vm.step = 4
        var finished = false

        vm.advance { finished = true }

        #expect(finished == true)
        #expect(vm.step == 4)
    }

    @Test func goBackFromStepOneReturnsToZero() {
        let vm = OnboardingViewModel()
        vm.step = 1
        vm.goBack()
        #expect(vm.step == 0)
    }

    @Test func headerSubtitleAndButtonTitleByStep() {
        let vm = OnboardingViewModel()

        // Step 0 — name / handle
        #expect(vm.headerSubtitle == "Tell us about you")
        #expect(vm.primaryButtonTitle == "Continue")

        // Step 1 — pain point
        vm.step = 1
        #expect(vm.headerSubtitle == "How do you plan content?")
        #expect(vm.primaryButtonTitle == "Continue")

        // Step 2 — content volume
        vm.step = 2
        #expect(vm.headerSubtitle == "How often do you post?")
        #expect(vm.primaryButtonTitle == "Continue")

        // Step 3 — platform picker
        vm.step = 3
        #expect(vm.headerSubtitle == "Pick your platforms")
        #expect(vm.primaryButtonTitle == "Continue")

        // Step 4 — value proposition (final step, button changes copy)
        vm.step = 4
        #expect(vm.headerSubtitle == "What you get with Plotr")
        #expect(vm.primaryButtonTitle == "Let's go")
    }

    @Test func serializedPlatformsContainsAllSelectedRawValues() {
        let vm = OnboardingViewModel()
        vm.togglePlatform(.youtube)
        vm.togglePlatform(.instagram)

        let parts = Set(vm.serializedPlatforms.split(separator: ",").map(String.init))
        #expect(parts == ["YouTube", "Instagram"])
    }

    @Test func serializedPlatformsIsEmptyWhenNoneSelected() {
        let vm = OnboardingViewModel()
        #expect(vm.serializedPlatforms == "")
    }
}
