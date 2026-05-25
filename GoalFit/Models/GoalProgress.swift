import Foundation

/// Resultado del cálculo de progreso de un objetivo en un período concreto.
/// Es un valor inmutable producido por `ProgressCalculator`.
struct GoalProgress: Equatable, Identifiable {
    let goalId: UUID
    let currentValue: Double
    let targetValue: Double
    /// Progreso normalizado entre 0.0 y 1.0.
    let fraction: Double
    let isCompleted: Bool
    let periodStart: Date
    let periodEnd: Date
    let lastUpdated: Date

    var id: UUID { goalId }

    /// Progreso en porcentaje entero (0–100).
    var percent: Int { Int((fraction * 100).rounded()) }
}

/// Punto agregado de datos de salud (ej: pasos de un día) para graficar histórico.
struct HealthDataPoint: Equatable, Identifiable {
    let date: Date
    let value: Double

    var id: Date { date }
}
