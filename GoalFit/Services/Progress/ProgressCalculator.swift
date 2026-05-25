import Foundation

/// Calcula el progreso de un objetivo a partir de su definición y un valor
/// actual leído de HealthKit. Lógica pura, sin estado ni dependencias →
/// 100% testeable.
enum ProgressCalculator {

    /// Calcula el progreso de un objetivo.
    /// - Parameters:
    ///   - goal: el objetivo a evaluar.
    ///   - currentValue: valor actual de la métrica. Para objetivos acumulativos
    ///     es la suma del período; para `reach` es la última muestra.
    ///   - periodStart: inicio del período evaluado.
    ///   - periodEnd: fin del período evaluado.
    ///   - now: fecha de cálculo (inyectable para tests).
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

    /// Fracción de avance normalizada en 0.0–1.0.
    static func fraction(for goal: Goal, currentValue: Double) -> Double {
        switch goal.direction {
        case .atLeast:
            guard goal.targetValue > 0 else { return 0 }
            return clamp(currentValue / goal.targetValue)

        case .atMost:
            // Cuanto más por debajo del límite, mejor. Si lo supera, 0.
            guard goal.targetValue > 0 else { return 0 }
            if currentValue <= goal.targetValue { return 1 }
            // Penaliza proporcionalmente el exceso.
            return clamp(goal.targetValue / currentValue)

        case .reach:
            // Progreso desde el valor de partida hacia el objetivo.
            guard let start = goal.startValue else {
                return currentValue == goal.targetValue ? 1 : 0
            }
            let totalDelta = goal.targetValue - start
            guard abs(totalDelta) > .ulpOfOne else { return 1 }
            let achievedDelta = currentValue - start
            return clamp(achievedDelta / totalDelta)
        }
    }

    /// Indica si la meta se cumplió.
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

    /// Tolerancia para considerar alcanzada una meta de tipo `reach`
    /// (ej: 0.1 kg para peso).
    private static func reachTolerance(for goal: Goal) -> Double {
        goal.type == .bodyMass ? 0.1 : 0
    }
}
