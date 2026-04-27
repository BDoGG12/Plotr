import Foundation
import SwiftData
import SwiftUI

enum Stage: String, CaseIterable, Identifiable, Codable {
    case idea = "Idea"
    case script = "Script"
    case filming = "Filming"
    case editing = "Editing"
    case done = "Done"

    var id: String { rawValue }

    var next: Stage? {
        let all = Stage.allCases
        guard let idx = all.firstIndex(of: self), idx < all.count - 1 else { return nil }
        return all[idx + 1]
    }

    var index: Int { Stage.allCases.firstIndex(of: self) ?? 0 }
}

enum Platform: String, CaseIterable, Identifiable, Codable {
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case instagram = "Instagram"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .youtube:   return Color(hex: "7c6ee0")
        case .tiktok:    return Color(hex: "c9a84c")
        case .instagram: return Color(hex: "c45c8a")
        }
    }

    var defaultChecklist: [String] {
        switch self {
        case .youtube:
            return ["Hook drafted", "Full script written", "B-roll filmed", "Edit pass complete", "Thumbnail + title set"]
        case .tiktok:
            return ["Hook drafted", "Script outlined", "Footage captured", "Captions added", "Cover frame chosen"]
        case .instagram:
            return ["Concept defined", "Shoot list ready", "Photos / video captured", "Edit + color complete", "Caption + hashtags written"]
        }
    }
}

@Model
final class Post {
    @Attribute(.unique) var id: UUID
    var title: String
    var platformRaw: String
    var stageRaw: String
    var dueDate: Date?
    var pillar: String
    var format: String
    var estimatedLength: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.post)
    var checklist: [ChecklistItem] = []

    init(
        id: UUID = UUID(),
        title: String = "",
        platform: Platform = .youtube,
        stage: Stage = .idea,
        dueDate: Date? = nil,
        pillar: String = "",
        format: String = "",
        estimatedLength: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.platformRaw = platform.rawValue
        self.stageRaw = stage.rawValue
        self.dueDate = dueDate
        self.pillar = pillar
        self.format = format
        self.estimatedLength = estimatedLength
        self.createdAt = createdAt
    }

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .youtube }
        set {
            platformRaw = newValue.rawValue
        }
    }

    var stage: Stage {
        get { Stage(rawValue: stageRaw) ?? .idea }
        set { stageRaw = newValue.rawValue }
    }

    func resetChecklistForCurrentPlatform(context: ModelContext) {
        for item in checklist {
            context.delete(item)
        }
        checklist = []
        for (idx, title) in platform.defaultChecklist.enumerated() {
            let item = ChecklistItem(title: title, sortIndex: idx)
            context.insert(item)
            item.post = self
            checklist.append(item)
        }
    }
}

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isComplete: Bool
    var sortIndex: Int
    var post: Post?

    init(id: UUID = UUID(), title: String, isComplete: Bool = false, sortIndex: Int = 0) {
        self.id = id
        self.title = title
        self.isComplete = isComplete
        self.sortIndex = sortIndex
    }
}
