import Foundation

/// Provides a goal's progress. In M1 a simulated implementation is used; in M2
/// it is replaced by a HealthKit-backed one without touching the ViewModels.
protocol ProgressProviding {
    func progress(for goal: Goal) async -> GoalProgress
}

/// Simulated implementation for development before the HealthKit integration.
/// Produces a stable per-goal value (derived from its id) so the dashboard looks
/// "alive" and deterministic.
struct MockProgressProvider: ProgressProviding {
    func progress(for goal: Goal) async -> GoalProgress {
        let fraction = Self.stableFraction(for: goal.id)
        let currentValue: Double

        switch goal.direction {
        case .atLeast, .atMost:
            currentValue = goal.targetValue * fraction
        case .reach:
            let start = goal.startValue ?? goal.targetValue
            currentValue = start + (goal.targetValue - start) * fraction
        }

        return ProgressCalculator.progress(
            for: goal,
            currentValue: currentValue,
            periodStart: Calendar.current.startOfDay(for: .now),
            periodEnd: .now
        )
    }

    /// Pseudo-random but stable fraction in [0.15, 1.0] derived from the UUID.
    static func stableFraction(for id: UUID) -> Double {
        let byte = id.uuid.0
        return 0.15 + (Double(byte) / 255.0) * 0.85
    }
}
