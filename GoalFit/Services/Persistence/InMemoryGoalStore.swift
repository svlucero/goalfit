import Foundation

/// Implementación de `GoalStoring` en memoria, para previews y tests sin SwiftData.
@MainActor
final class InMemoryGoalStore: GoalStoring {
    private var goals: [Goal]

    init(goals: [Goal] = []) {
        self.goals = goals
    }

    func fetchGoals(activeOnly: Bool) throws -> [Goal] {
        let result = activeOnly ? goals.filter(\.isActive) : goals
        return result.sorted { $0.createdAt > $1.createdAt }
    }

    func goal(with id: UUID) throws -> Goal? {
        goals.first { $0.id == id }
    }

    func insert(_ goal: Goal) throws {
        if !goals.contains(where: { $0.id == goal.id }) {
            goals.append(goal)
        }
    }

    func delete(_ goal: Goal) throws {
        goals.removeAll { $0.id == goal.id }
    }

    func save() throws { /* no-op: las mutaciones ya están en memoria */ }
}

extension InMemoryGoalStore {
    /// Store con datos de ejemplo para previews.
    static func previewPopulated() -> InMemoryGoalStore {
        InMemoryGoalStore(goals: [
            Goal(title: "Caminar 10.000 pasos", type: .steps, targetValue: 10000),
            Goal(title: "30 min de ejercicio", type: .exerciseMinutes, targetValue: 30),
            Goal(title: "Llegar a 70 kg", type: .bodyMass, targetValue: 70, startValue: 78)
        ])
    }
}
