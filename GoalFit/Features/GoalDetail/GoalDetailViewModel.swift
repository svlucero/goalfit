import Foundation

/// ViewModel for the goal detail screen: loads the current progress and the
/// last-N-days history from the health source.
@MainActor
@Observable
final class GoalDetailViewModel {
    let goal: Goal
    private let health: HealthDataProviding
    private let historyDays: Int

    private(set) var progress: GoalProgress?
    private(set) var series: [HealthDataPoint] = []
    private(set) var isLoading = false

    init(goal: Goal, health: HealthDataProviding, historyDays: Int = 7) {
        self.goal = goal
        self.health = health
        self.historyDays = historyDays
    }

    var isCumulative: Bool { goal.type.isCumulative }

    /// Best value in the loaded series (e.g. best day).
    var bestValue: Double? { series.map(\.value).max() }

    /// Average value across the loaded series.
    var averageValue: Double? {
        guard !series.isEmpty else { return nil }
        return series.map(\.value).reduce(0, +) / Double(series.count)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let (start, end) = PeriodResolver.bounds(for: goal)
        let value = (try? await health.currentValue(for: goal)) ?? 0
        progress = ProgressCalculator.progress(
            for: goal, currentValue: value, periodStart: start, periodEnd: end
        )
        series = (try? await health.dailySeries(for: goal, days: historyDays)) ?? []
    }
}
