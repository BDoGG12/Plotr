import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {
    var step: Int = 0
    var name: String = ""
    var handle: String = ""
    var selected: Set<Platform> = []

    var headerSubtitle: String {
        step == 0 ? "Tell us about you" : "Pick your platforms"
    }

    var primaryButtonTitle: String {
        step == 0 ? "Continue" : "Start planning"
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
        if step == 0 {
            step = 1
        } else {
            finish()
        }
    }
}
