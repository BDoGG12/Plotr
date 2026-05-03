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

    var supportsVideoAttachment: Bool {
        switch self {
        case .script, .filming, .editing: return true
        case .idea, .done: return false
        }
    }
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
    var platformsRaw: String
    var stageRaw: String
    var dueDate: Date?
    var pillar: String
    var format: String
    var estimatedLength: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.post)
    var checklist: [ChecklistItem] = []
    @Relationship(deleteRule: .cascade, inverse: \VideoAttachment.post)
    var videoAttachments: [VideoAttachment] = []

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
        self.platformsRaw = platform.rawValue
        self.stageRaw = stage.rawValue
        self.dueDate = dueDate
        self.pillar = pillar
        self.format = format
        self.estimatedLength = estimatedLength
        self.createdAt = createdAt
    }

    var platforms: Set<Platform> {
        get {
            let parts = platformsRaw.split(separator: ",").map { String($0) }
            return Set(parts.compactMap { Platform(rawValue: $0) })
        }
        set {
            platformsRaw = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }

    var primaryPlatform: Platform {
        platforms.sorted { $0.rawValue < $1.rawValue }.first ?? .youtube
    }

    var platform: Platform {
        get { primaryPlatform }
        set { platforms = [newValue] }
    }

    var stage: Stage {
        get { Stage(rawValue: stageRaw) ?? .idea }
        set { stageRaw = newValue.rawValue }
    }

    func resetChecklistForCurrentPlatforms(context: ModelContext) {
        for item in checklist {
            context.delete(item)
        }
        checklist = []

        var seen: Set<String> = []
        var sortIndex = 0
        for platform in platforms.sorted(by: { $0.rawValue < $1.rawValue }) {
            for title in platform.defaultChecklist {
                guard !seen.contains(title) else { continue }
                seen.insert(title)
                let item = ChecklistItem(title: title, sortIndex: sortIndex)
                context.insert(item)
                item.post = self
                checklist.append(item)
                sortIndex += 1
            }
        }
    }

    func resetChecklistForCurrentPlatform(context: ModelContext) {
        resetChecklistForCurrentPlatforms(context: context)
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

@Model
final class VideoAttachment {
    @Attribute(.unique) var id: UUID
    var bookmarkData: Data?
    var displayName: String
    var stageRaw: String
    var attachedAt: Date
    var post: Post?

    init(
        id: UUID = UUID(),
        bookmarkData: Data? = nil,
        displayName: String = "",
        stage: Stage = .filming,
        attachedAt: Date = .now
    ) {
        self.id = id
        self.bookmarkData = bookmarkData
        self.displayName = displayName
        self.stageRaw = stage.rawValue
        self.attachedAt = attachedAt
    }

    var stage: Stage {
        get { Stage(rawValue: stageRaw) ?? .filming }
        set { stageRaw = newValue.rawValue }
    }

    var resolvedURL: URL? {
        guard let bookmarkData else { return nil }
        var isStale = false
        return try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
}
