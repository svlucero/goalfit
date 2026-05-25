import Foundation

/// Result of computing a goal's progress for a given period.
/// Immutable value produced by `ProgressCalculator`.
struct GoalProgress: Equatable, Identifiable {
    let goalId: UUID
    let currentValue: Double
    let targetValue: Double
    /// Normalized progress between 0.0 and 1.0.
    let fraction: Double
    let isCompleted: Bool
    let periodStart: Date
    let periodEnd: Date
    let lastUpdated: Date

    var id: UUID { goalId }

    /// Progress as a whole percentage (0–100).
    var percent: Int { Int((fraction * 100).rounded()) }
}

/// Aggregated health data point (e.g. steps for a day) used to chart history.
struct HealthDataPoint: Equatable, Identifiable {
    let date: Date
    let value: Double

    var id: Date { date }
}
