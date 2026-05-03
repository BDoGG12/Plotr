import Foundation
import SwiftUI

@Observable
final class CalendarViewModel {
    var weekAnchor: Date = .now

    private let calendar: Calendar = .current

    var weekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: weekAnchor)?.start ?? weekAnchor
    }

    var days: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var weekRangeLabel: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let fmt = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(weekStart.formatted(fmt)) – \(end.formatted(fmt))"
    }

    func shiftWeek(by delta: Int) {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: delta, to: weekAnchor) {
            withAnimation(.snappy) { weekAnchor = newDate }
        }
    }

    func resetToThisWeek() {
        weekAnchor = .now
    }

    func posts(_ posts: [Post], on day: Date) -> [Post] {
        posts.filter { post in
            guard let due = post.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: day)
        }
        .sorted { $0.title < $1.title }
    }

    func isToday(_ day: Date) -> Bool {
        calendar.isDateInToday(day)
    }

    func uniquePlatforms(in posts: [Post]) -> [Platform] {
        var seen = Set<Platform>()
        var ordered: [Platform] = []
        for p in posts.flatMap(\.platforms) where !seen.contains(p) {
            seen.insert(p)
            ordered.append(p)
        }
        return ordered
    }
}
