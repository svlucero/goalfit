import Foundation

/// Provee el progreso de un objetivo. En M1 se usa una implementación simulada;
/// en M2 se reemplaza por una respaldada en HealthKit sin tocar los ViewModels.
protocol ProgressProviding {
    func progress(for goal: Goal) async -> GoalProgress
}

/// Implementación simulada para desarrollo previo a la integración con HealthKit.
/// Genera un valor estable por objetivo (derivado de su id) para que el dashboard
/// se vea "vivo" y determinista.
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

    /// Fracción pseudo-aleatoria pero estable en [0.15, 1.0] a partir del UUID.
    static func stableFraction(for id: UUID) -> Double {
        let byte = id.uuid.0
        return 0.15 + (Double(byte) / 255.0) * 0.85
    }
}
