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

    @Test func advanceFromStepOneCallsFinish() {
        let vm = OnboardingViewModel()
        vm.step = 1
        var finished = false

        vm.advance { finished = true }

        #expect(finished == true)
        #expect(vm.step == 1)
    }

    @Test func goBackFromStepOneReturnsToZero() {
        let vm = OnboardingViewModel()
        vm.step = 1
        vm.goBack()
        #expect(vm.step == 0)
    }

    @Test func headerSubtitleAndButtonTitleByStep() {
        let vm = OnboardingViewModel()
        #expect(vm.headerSubtitle == "Tell us about you")
        #expect(vm.primaryButtonTitle == "Continue")

        vm.step = 1
        #expect(vm.headerSubtitle == "Pick your platforms")
        #expect(vm.primaryButtonTitle == "Start planning")
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
