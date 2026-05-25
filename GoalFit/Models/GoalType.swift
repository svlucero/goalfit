import Foundation

/// Health metric measured by a goal. The concrete mapping to HealthKit types
/// lives in the service layer to keep the domain model pure.
enum GoalType: String, Codable, CaseIterable, Identifiable {
    case steps
    case distance
    case activeEnergy
    case exerciseMinutes
    case bodyMass

    var id: String { rawValue }

    /// Human-readable name shown to the user.
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .distance: return "Distance"
        case .activeEnergy: return "Active energy"
        case .exerciseMinutes: return "Exercise minutes"
        case .bodyMass: return "Weight"
        }
    }

    /// Associated SF Symbol.
    var systemImage: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "location.fill"
        case .activeEnergy: return "flame.fill"
        case .exerciseMinutes: return "timer"
        case .bodyMass: return "scalemass.fill"
        }
    }

    /// Default human-readable unit.
    var defaultUnit: String {
        switch self {
        case .steps: return "steps"
        case .distance: return "km"
        case .activeEnergy: return "kcal"
        case .exerciseMinutes: return "min"
        case .bodyMass: return "kg"
        }
    }

    /// `true` when progress is computed by summing samples over the period
    /// (steps, distance, calories, minutes). `false` for target metrics where
    /// the latest value matters (weight).
    var isCumulative: Bool {
        switch self {
        case .steps, .distance, .activeEnergy, .exerciseMinutes: return true
        case .bodyMass: return false
        }
    }

    /// Default period suggested when creating a goal of this type.
    var defaultPeriod: GoalPeriod {
        isCumulative ? .daily : .target
    }

    /// Default direction suggested.
    var defaultDirection: GoalDirection {
        isCumulative ? .atLeast : .reach
    }
}

/// How often the goal is evaluated.
enum GoalPeriod: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case target

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .target: return "One-time goal"
        }
    }
}

/// How goal completion is interpreted.
enum GoalDirection: String, Codable, CaseIterable, Identifiable {
    /// Completed = reach or exceed (steps, distance, etc.).
    case atLeast
    /// Completed = stay below.
    case atMost
    /// Reach a target value (e.g. target weight).
    case reach

    var id: String { rawValue }
}
