import Foundation

/// Storage abstraction for goals. Allows injecting real implementations
/// (SwiftData) or mocks in tests/previews.
@MainActor
protocol GoalStoring {
    /// Returns the goals. If `activeOnly` is true, only active ones.
    func fetchGoals(activeOnly: Bool) throws -> [Goal]
    func goal(with id: UUID) throws -> Goal?
    func insert(_ goal: Goal) throws
    func delete(_ goal: Goal) throws
    func save() throws
}

extension GoalStoring {
    func fetchGoals() throws -> [Goal] {
        try fetchGoals(activeOnly: false)
    }
}
