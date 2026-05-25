import Foundation

/// Computes a goal's progress from its definition and a current value read from
/// HealthKit. Pure, stateless logic with no dependencies → fully testable.
enum ProgressCalculator {

    /// Computes a goal's progress.
    /// - Parameters:
    ///   - goal: the goal to evaluate.
    ///   - currentValue: current metric value. For cumulative goals it is the
    ///     period sum; for `reach` goals it is the latest sample.
    ///   - periodStart: start of the evaluated period.
    ///   - periodEnd: end of the evaluated period.
    ///   - now: computation date (injectable for tests).
    static func progress(
        for goal: Goal,
        currentValue: Double,
        periodStart: Date,
        periodEnd: Date,
        now: Date = .now
    ) -> GoalProgress {
        let fraction = fraction(for: goal, currentValue: currentValue)
        let completed = isCompleted(for: goal, currentValue: currentValue)

        return GoalProgress(
            goalId: goal.id,
            currentValue: currentValue,
            targetValue: goal.targetValue,
            fraction: fraction,
            isCompleted: completed,
            periodStart: periodStart,
            periodEnd: periodEnd,
            lastUpdated: now
        )
    }

    /// Normalized progress fraction in 0.0–1.0.
    static func fraction(for goal: Goal, currentValue: Double) -> Double {
        switch goal.direction {
        case .atLeast:
            guard goal.targetValue > 0 else { return 0 }
            return clamp(currentValue / goal.targetValue)

        case .atMost:
            // The further below the limit, the better. If it exceeds it, 0.
            guard goal.targetValue > 0 else { return 0 }
            if currentValue <= goal.targetValue { return 1 }
            // Penalize the excess proportionally.
            return clamp(goal.targetValue / currentValue)

        case .reach:
            // Progress from the start value toward the target.
            guard let start = goal.startValue else {
                return currentValue == goal.targetValue ? 1 : 0
            }
            let totalDelta = goal.targetValue - start
            guard abs(totalDelta) > .ulpOfOne else { return 1 }
            let achievedDelta = currentValue - start
            return clamp(achievedDelta / totalDelta)
        }
    }

    /// Whether the goal has been completed.
    static func isCompleted(for goal: Goal, currentValue: Double) -> Bool {
        switch goal.direction {
        case .atLeast:
            return currentValue >= goal.targetValue
        case .atMost:
            return currentValue <= goal.targetValue
        case .reach:
            guard let start = goal.startValue else {
                return abs(currentValue - goal.targetValue) <= reachTolerance(for: goal)
            }
            let tolerance = reachTolerance(for: goal)
            if goal.targetValue >= start {
                return currentValue >= goal.targetValue - tolerance
            } else {
                return currentValue <= goal.targetValue + tolerance
            }
        }
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    /// Tolerance to consider a `reach` goal achieved (e.g. 0.1 kg for weight).
    private static func reachTolerance(for goal: Goal) -> Double {
        goal.type == .bodyMass ? 0.1 : 0
    }
}
