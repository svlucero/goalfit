import Foundation

/// Métrica de salud que mide un objetivo. El mapeo concreto a tipos de HealthKit
/// vive en la capa de servicios para mantener el modelo de dominio puro.
enum GoalType: String, Codable, CaseIterable, Identifiable {
    case steps
    case distance
    case activeEnergy
    case exerciseMinutes
    case bodyMass

    var id: String { rawValue }

    /// Nombre legible para el usuario.
    var displayName: String {
        switch self {
        case .steps: return "Pasos"
        case .distance: return "Distancia"
        case .activeEnergy: return "Calorías activas"
        case .exerciseMinutes: return "Minutos de ejercicio"
        case .bodyMass: return "Peso"
        }
    }

    /// Símbolo de SF Symbols asociado.
    var systemImage: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "location.fill"
        case .activeEnergy: return "flame.fill"
        case .exerciseMinutes: return "timer"
        case .bodyMass: return "scalemass.fill"
        }
    }

    /// Unidad legible por defecto.
    var defaultUnit: String {
        switch self {
        case .steps: return "pasos"
        case .distance: return "km"
        case .activeEnergy: return "kcal"
        case .exerciseMinutes: return "min"
        case .bodyMass: return "kg"
        }
    }

    /// `true` si el progreso se calcula sumando muestras del período
    /// (pasos, distancia, calorías, minutos). `false` para métricas de target
    /// donde interesa el último valor (peso).
    var isCumulative: Bool {
        switch self {
        case .steps, .distance, .activeEnergy, .exerciseMinutes: return true
        case .bodyMass: return false
        }
    }

    /// Período por defecto sugerido al crear un objetivo de este tipo.
    var defaultPeriod: GoalPeriod {
        isCumulative ? .daily : .target
    }

    /// Dirección por defecto sugerida.
    var defaultDirection: GoalDirection {
        isCumulative ? .atLeast : .reach
    }
}

/// Cada cuánto se evalúa el objetivo.
enum GoalPeriod: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case target

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Diario"
        case .weekly: return "Semanal"
        case .target: return "Meta única"
        }
    }
}

/// Cómo se interpreta el cumplimiento de la meta.
enum GoalDirection: String, Codable, CaseIterable, Identifiable {
    /// Cumplir = alcanzar o superar (pasos, distancia, etc.).
    case atLeast
    /// Cumplir = mantenerse por debajo.
    case atMost
    /// Llegar a un valor objetivo (ej: peso target).
    case reach

    var id: String { rawValue }
}
