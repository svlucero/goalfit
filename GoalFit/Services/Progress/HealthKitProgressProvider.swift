import Foundation

/// `ProgressProviding` backed by a `HealthDataProviding` source: reads the
/// current value from health data and computes progress with `ProgressCalculator`.
struct HealthKitProgressProvider: ProgressProviding {
    let health: HealthDataProviding

    func progress(for goal: Goal) async -> GoalProgress {
        let (start, end) = PeriodResolver.bounds(for: goal)
        let value = (try? await health.currentValue(for: goal)) ?? 0
        return ProgressCalculator.progress(
            for: goal,
            currentValue: value,
            periodStart: start,
            periodEnd: end
        )
    }
}
