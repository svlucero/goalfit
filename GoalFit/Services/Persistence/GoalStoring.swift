import Foundation

/// Abstracción de almacenamiento de objetivos. Permite inyectar implementaciones
/// reales (SwiftData) o mocks en tests/previews.
@MainActor
protocol GoalStoring {
    /// Devuelve los objetivos. Si `activeOnly` es true, solo los activos.
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
