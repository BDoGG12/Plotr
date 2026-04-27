import Foundation
import SwiftUI

@Observable
final class IdeaVaultViewModel {
    var search: String = ""

    func ideas(from posts: [Post]) -> [Post] {
        let pool = posts.filter { $0.stage == .idea }
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return pool }
        return pool.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }
}
