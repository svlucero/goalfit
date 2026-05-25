import Foundation

/// In-memory `GoalStoring` implementation, for previews and tests without SwiftData.
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

    func save() throws { /* no-op: mutations already live in memory */ }
}

extension InMemoryGoalStore {
    /// Store with sample data for previews.
    static func previewPopulated() -> InMemoryGoalStore {
        InMemoryGoalStore(goals: [
            Goal(title: "Walk 10,000 steps", type: .steps, targetValue: 10000),
            Goal(title: "30 min of exercise", type: .exerciseMinutes, targetValue: 30),
            Goal(title: "Reach 70 kg", type: .bodyMass, targetValue: 70, startValue: 78)
        ])
    }
}
