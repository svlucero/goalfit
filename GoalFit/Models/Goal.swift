import Foundation
import SwiftData

/// Objetivo de salud definido por el usuario. Se persiste con SwiftData.
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String

    /// Persistimos el `rawValue` de los enums para estabilidad del esquema.
    var typeRaw: String
    var periodRaw: String
    var directionRaw: String

    var targetValue: Double
    /// Valor de partida, usado en metas de tipo `reach` (ej: peso inicial).
    var startValue: Double?
    var unit: String

    var createdAt: Date
    var deadline: Date?
    var isActive: Bool

    var reminderEnabled: Bool
    var reminderTime: Date?

    init(
        id: UUID = UUID(),
        title: String,
        type: GoalType,
        period: GoalPeriod? = nil,
        direction: GoalDirection? = nil,
        targetValue: Double,
        startValue: Double? = nil,
        unit: String? = nil,
        createdAt: Date = .now,
        deadline: Date? = nil,
        isActive: Bool = true,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.typeRaw = type.rawValue
        self.periodRaw = (period ?? type.defaultPeriod).rawValue
        self.directionRaw = (direction ?? type.defaultDirection).rawValue
        self.targetValue = targetValue
        self.startValue = startValue
        self.unit = unit ?? type.defaultUnit
        self.createdAt = createdAt
        self.deadline = deadline
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
    }
}

// MARK: - Acceso tipado a los enums

extension Goal {
    var type: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .steps }
        set { typeRaw = newValue.rawValue }
    }

    var period: GoalPeriod {
        get { GoalPeriod(rawValue: periodRaw) ?? .daily }
        set { periodRaw = newValue.rawValue }
    }

    var direction: GoalDirection {
        get { GoalDirection(rawValue: directionRaw) ?? .atLeast }
        set { directionRaw = newValue.rawValue }
    }
}
