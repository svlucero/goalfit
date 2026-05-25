import Foundation

/// ViewModel del formulario de creación/edición de objetivos.
@MainActor
@Observable
final class GoalFormViewModel {
    var title: String
    var type: GoalType {
        didSet { if oldValue != type { applyTypeDefaults() } }
    }
    var period: GoalPeriod
    var direction: GoalDirection
    var targetValue: Double
    var startValue: Double
    var hasDeadline: Bool
    var deadline: Date
    var reminderEnabled: Bool
    var reminderTime: Date

    private let store: GoalStoring
    private let editingGoal: Goal?

    var isEditing: Bool { editingGoal != nil }

    init(store: GoalStoring, goal: Goal? = nil) {
        self.store = store
        self.editingGoal = goal

        if let goal {
            title = goal.title
            type = goal.type
            period = goal.period
            direction = goal.direction
            targetValue = goal.targetValue
            startValue = goal.startValue ?? 0
            hasDeadline = goal.deadline != nil
            deadline = goal.deadline ?? Self.defaultDeadline
            reminderEnabled = goal.reminderEnabled
            reminderTime = goal.reminderTime ?? Self.defaultReminderTime
        } else {
            let defaultType = GoalType.steps
            title = ""
            type = defaultType
            period = defaultType.defaultPeriod
            direction = defaultType.defaultDirection
            targetValue = 10000
            startValue = 0
            hasDeadline = false
            deadline = Self.defaultDeadline
            reminderEnabled = false
            reminderTime = Self.defaultReminderTime
        }
    }

    var unit: String { type.defaultUnit }

    /// Indica si el objetivo necesita un valor de partida (metas de peso `reach`).
    var requiresStartValue: Bool { type == .bodyMass }

    /// Validación para habilitar el botón Guardar.
    var canSave: Bool {
        let titleOK = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let targetOK = targetValue > 0
        let startOK = !requiresStartValue || startValue > 0
        let deadlineOK = !hasDeadline || deadline > .now
        return titleOK && targetOK && startOK && deadlineOK
    }

    /// Título sugerido según el tipo (si el usuario no escribió uno propio).
    func suggestedTitle() -> String {
        switch type {
        case .steps: return "Caminar \(Int(targetValue)) pasos"
        case .distance: return "Recorrer \(targetValue.formatted()) km"
        case .activeEnergy: return "Quemar \(Int(targetValue)) kcal"
        case .exerciseMinutes: return "\(Int(targetValue)) min de ejercicio"
        case .bodyMass: return "Llegar a \(targetValue.formatted()) kg"
        }
    }

    func save() throws {
        let finalTitle = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? suggestedTitle()
            : title.trimmingCharacters(in: .whitespaces)

        if let goal = editingGoal {
            goal.title = finalTitle
            goal.type = type
            goal.period = period
            goal.direction = direction
            goal.targetValue = targetValue
            goal.startValue = requiresStartValue ? startValue : nil
            goal.unit = type.defaultUnit
            goal.deadline = hasDeadline ? deadline : nil
            goal.reminderEnabled = reminderEnabled
            goal.reminderTime = reminderEnabled ? reminderTime : nil
            try store.save()
        } else {
            let goal = Goal(
                title: finalTitle,
                type: type,
                period: period,
                direction: direction,
                targetValue: targetValue,
                startValue: requiresStartValue ? startValue : nil,
                deadline: hasDeadline ? deadline : nil,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderEnabled ? reminderTime : nil
            )
            try store.insert(goal)
        }
    }

    func delete() throws {
        guard let editingGoal else { return }
        try store.delete(editingGoal)
    }

    // MARK: - Helpers

    private func applyTypeDefaults() {
        period = type.defaultPeriod
        direction = type.defaultDirection
        targetValue = Self.defaultTarget(for: type)
    }

    private static func defaultTarget(for type: GoalType) -> Double {
        switch type {
        case .steps: return 10000
        case .distance: return 5
        case .activeEnergy: return 500
        case .exerciseMinutes: return 30
        case .bodyMass: return 70
        }
    }

    private static var defaultDeadline: Date {
        Calendar.current.date(byAdding: .month, value: 2, to: .now) ?? .now
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    }
}
