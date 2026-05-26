import Foundation

/// Abstraction over the health data source. Lets us inject the real HealthKit
/// service or a mock in tests/previews.
protocol HealthDataProviding {
    /// Whether health data is available on this device.
    var isHealthDataAvailable: Bool { get }

    /// Requests read authorization for the given goal types.
    func requestAuthorization(for types: [GoalType]) async throws

    /// Current value of the goal's metric for its period (sum for cumulative
    /// goals, latest sample for target goals).
    func currentValue(for goal: Goal) async throws -> Double

    /// Daily aggregated series for the last `days` days, to chart history.
    func dailySeries(for goal: Goal, days: Int) async throws -> [HealthDataPoint]
}

/// Deterministic in-memory health source for previews and tests.
struct MockHealthService: HealthDataProviding {
    var available = true
    var valueProvider: (Goal) -> Double = { $0.targetValue * 0.62 }

    var isHealthDataAvailable: Bool { available }

    func requestAuthorization(for types: [GoalType]) async throws {}

    func currentValue(for goal: Goal) async throws -> Double {
        valueProvider(goal)
    }

    func dailySeries(for goal: Goal, days: Int) async throws -> [HealthDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let base = goal.targetValue
            let factor = 0.4 + Double((offset * 7) % 6) / 10.0
            return HealthDataPoint(date: date, value: base * factor)
        }
    }
}
