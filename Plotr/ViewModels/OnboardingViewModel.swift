import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {
    var step: Int = 0
    var name: String = ""
    var handle: String = ""
    var painPoint: String = ""
    var contentVolume: String = ""
    var selected: Set<Platform> = []

    var headerSubtitle: String {
        switch step {
        case 0: "Tell us about you"
        case 1: "How do you plan content?"
        case 2: "How often do you post?"
        case 3: "Pick your platforms"
        case 4: "What you get with Plotr"
        default: ""
        }
    }

    var primaryButtonTitle: String {
        step == 4 ? "Let's go" : "Continue"
    }

    /// `true` when the current step's required answer is present.
    /// Steps 0 (name/handle) and 3 (platforms) are intentionally ungated —
    /// the header "Skip" button is the escape hatch out of onboarding.
    var canAdvance: Bool {
        switch step {
        case 1: !painPoint.isEmpty
        case 2: !contentVolume.isEmpty
        default: true
        }
    }

    var serializedPlatforms: String {
        selected.map(\.rawValue).joined(separator: ",")
    }

    func togglePlatform(_ platform: Platform) {
        if selected.contains(platform) {
            selected.remove(platform)
        } else {
            selected.insert(platform)
        }
    }

    func goBack() {
        guard step > 0 else { return }
        step -= 1
    }

    func advance(finish: () -> Void) {
        guard canAdvance else { return }
        if step < 4 {
            step += 1
        } else {
            finish()
        }
    }
}
