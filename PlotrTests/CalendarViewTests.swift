import Foundation
import SwiftUI
import Testing
@testable import Plotr

// These tests cover the data/logic that `CalendarView` renders: the real
// `CalendarViewModel` week navigation, day-grouping, and platform-dedup
// helpers, plus the `Post`-model fact behind the per-day platform dot.
// The SwiftUI view itself isn't exercised — that would need ViewInspector.

@MainActor
struct CalendarViewTests {
    // MARK: - Week navigation (real CalendarViewModel logic)

    @Test func test_weekNavigation_advancesBySevenDays() throws {
        let viewModel = CalendarViewModel()
        viewModel.weekAnchor = try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))
        )
        let originalStart = viewModel.weekStart

        viewModel.shiftWeek(by: 1)

        let dayDelta = try #require(
            Calendar.current.dateComponents([.day], from: originalStart, to: viewModel.weekStart).day
        )
        #expect(dayDelta == 7)
    }

    @Test func test_weekNavigation_goesBackBySevenDays() throws {
        let viewModel = CalendarViewModel()
        viewModel.weekAnchor = try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))
        )
        let originalStart = viewModel.weekStart

        viewModel.shiftWeek(by: -1)

        let dayDelta = try #require(
            Calendar.current.dateComponents([.day], from: originalStart, to: viewModel.weekStart).day
        )
        #expect(dayDelta == -7)
    }

    // MARK: - Post grouping by due date

    @Test func test_postsGroupedByDueDate_correctly() throws {
        let viewModel = CalendarViewModel()
        viewModel.weekAnchor = try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))
        )

        let weekDays = viewModel.days
        let dayA = weekDays[0]
        let dayB = weekDays[3]

        let postA = Post(title: "Sunday post", dueDate: dayA)
        let postB = Post(title: "Wednesday post", dueDate: dayB)
        let posts = [postA, postB]

        let onDayA = viewModel.posts(posts, on: dayA)
        #expect(onDayA.count == 1)
        #expect(onDayA.first?.id == postA.id)

        let onDayB = viewModel.posts(posts, on: dayB)
        #expect(onDayB.count == 1)
        #expect(onDayB.first?.id == postB.id)
    }

    @Test func test_postsWithNoDueDate_notShownInCalendar() throws {
        let viewModel = CalendarViewModel()
        viewModel.weekAnchor = try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))
        )

        let post = Post(title: "Floating idea", dueDate: nil)

        for day in viewModel.days {
            #expect(viewModel.posts([post], on: day).isEmpty)
        }
    }

    // MARK: - Platform visuals

    @Test func test_platformDotColor_matchesPrimaryPlatform() {
        let post = Post(platform: .tiktok)

        #expect(post.primaryPlatform == .tiktok)
        #expect(post.primaryPlatform.color == Platform.tiktok.color)
    }

    @Test func test_uniquePlatforms_deduplicatesAcrossPosts() {
        let viewModel = CalendarViewModel()
        let posts = [Post(platform: .youtube), Post(platform: .youtube)]

        #expect(viewModel.uniquePlatforms(in: posts) == [.youtube])
    }
}
