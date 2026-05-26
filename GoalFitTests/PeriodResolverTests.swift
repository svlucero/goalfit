import XCTest
@testable import GoalFit

final class PeriodResolverTests: XCTestCase {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2 // Monday
        return cal
    }

    func testDailyStartsAtMidnight() {
        let now = Date(timeIntervalSince1970: 1_700_000_000) // fixed instant
        let goal = Goal(title: "Steps", type: .steps, period: .daily, targetValue: 10000)

        let bounds = PeriodResolver.bounds(for: goal, now: now, calendar: calendar)

        XCTAssertEqual(bounds.start, calendar.startOfDay(for: now))
        XCTAssertEqual(bounds.end, now)
        XCTAssertLessThanOrEqual(bounds.start, bounds.end)
    }

    func testWeeklyStartsAtWeekBoundary() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let goal = Goal(title: "Steps", type: .steps, period: .weekly, targetValue: 50000)

        let bounds = PeriodResolver.bounds(for: goal, now: now, calendar: calendar)
        let expectedStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start

        XCTAssertEqual(bounds.start, expectedStart)
        XCTAssertLessThanOrEqual(bounds.start, now)
    }

    func testTargetUsesWideWindow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let goal = Goal(title: "Weight", type: .bodyMass, targetValue: 70, startValue: 80)

        let bounds = PeriodResolver.bounds(for: goal, now: now, calendar: calendar)
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)

        XCTAssertEqual(bounds.start, oneYearAgo)
        XCTAssertEqual(bounds.end, now)
    }
}
