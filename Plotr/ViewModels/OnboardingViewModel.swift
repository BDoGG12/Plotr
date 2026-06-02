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
        if step < 4 {
            step += 1
        } else {
            finish()
        }
    }
}
