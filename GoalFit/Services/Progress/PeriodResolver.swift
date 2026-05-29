import Foundation

/// Resolves the time bounds over which a goal's progress is evaluated.
/// Pure, testable logic.
enum PeriodResolver {
    static func bounds(
        for goal: Goal,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        switch goal.period {
        case .daily:
            return (calendar.startOfDay(for: now), now)

        case .weekly:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
                ?? calendar.startOfDay(for: now)
            return (start, now)

        case .target:
            // For target goals (e.g. weight) the latest sample matters, so we use
            // a wide window to find the most recent value.
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start, now)
        }
    }
}
