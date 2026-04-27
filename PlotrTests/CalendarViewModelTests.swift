import Foundation
import Testing
@testable import Plotr

@MainActor
struct CalendarViewModelTests {
    @Test func daysReturnsSevenContiguousDates() {
        let vm = CalendarViewModel()
        let days = vm.days

        #expect(days.count == 7)
        let cal = Calendar.current
        for i in 1..<days.count {
            let diff = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day
            #expect(diff == 1)
        }
    }

    @Test func weekStartIsAlignedToWeekBoundary() {
        let vm = CalendarViewModel()
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .weekOfYear, for: vm.weekAnchor)
        #expect(vm.weekStart == interval?.start)
    }

    @Test func shiftWeekMovesAnchorByDelta() {
        let vm = CalendarViewModel()
        let original = vm.weekAnchor
        vm.shiftWeek(by: 2)

        let cal = Calendar.current
        let weeks = cal.dateComponents([.weekOfYear], from: original, to: vm.weekAnchor).weekOfYear
        #expect(weeks == 2)
    }

    @Test func resetToThisWeekRestoresCurrentWeek() {
        let vm = CalendarViewModel()
        vm.shiftWeek(by: -10)
        vm.resetToThisWeek()

        let cal = Calendar.current
        #expect(cal.isDate(vm.weekAnchor, equalTo: .now, toGranularity: .weekOfYear))
    }

    @Test func postsOnDayFiltersAndSortsByTitle() throws {
        let context = try TestSupport.makeContext()
        let day = Date.now
        let other = Calendar.current.date(byAdding: .day, value: 3, to: day) ?? day

        let b = TestSupport.insertPost(title: "Beta", dueDate: day, in: context)
        let a = TestSupport.insertPost(title: "Alpha", dueDate: day, in: context)
        let off = TestSupport.insertPost(title: "Off", dueDate: other, in: context)
        let undated = TestSupport.insertPost(title: "Undated", dueDate: nil, in: context)

        let vm = CalendarViewModel()
        let result = vm.posts([b, a, off, undated], on: day)

        #expect(result.map(\.title) == ["Alpha", "Beta"])
    }

    @Test func isTodayMatchesNow() {
        let vm = CalendarViewModel()
        #expect(vm.isToday(.now))
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        #expect(vm.isToday(yesterday) == false)
    }

    @Test func uniquePlatformsPreservesFirstSeenOrder() throws {
        let context = try TestSupport.makeContext()
        let a = TestSupport.insertPost(platform: .tiktok, in: context)
        let b = TestSupport.insertPost(platform: .youtube, in: context)
        let c = TestSupport.insertPost(platform: .tiktok, in: context)
        let d = TestSupport.insertPost(platform: .instagram, in: context)

        let vm = CalendarViewModel()
        let platforms = vm.uniquePlatforms(in: [a, b, c, d])

        #expect(platforms == [.tiktok, .youtube, .instagram])
    }
}
