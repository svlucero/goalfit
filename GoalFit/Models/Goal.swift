import Foundation
import SwiftData

/// Health goal defined by the user. Persisted with SwiftData.
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String

    /// We persist the enums' `rawValue` for schema stability.
    var typeRaw: String
    var periodRaw: String
    var directionRaw: String

    var targetValue: Double
    /// Start value, used in `reach` goals (e.g. starting weight).
    var startValue: Double?
    var unit: String

    var createdAt: Date
    var deadline: Date?
    var isActive: Bool

    var reminderEnabled: Bool
    var reminderTime: Date?

    /// Period start at which the user was last notified that this goal was
    /// completed. Used to avoid duplicate completion notifications within the
    /// same period (or, for target goals, to notify only once).
    var lastCompletedPeriodStart: Date?

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
        reminderTime: Date? = nil,
        lastCompletedPeriodStart: Date? = nil
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
        self.lastCompletedPeriodStart = lastCompletedPeriodStart
    }
}

// MARK: - Typed access to the enums

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
