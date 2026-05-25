import Foundation
import SwiftData

/// Implementación de `GoalStoring` sobre SwiftData.
@MainActor
final class GoalRepository: GoalStoring {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchGoals(activeOnly: Bool) throws -> [Goal] {
        var descriptor = FetchDescriptor<Goal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if activeOnly {
            descriptor.predicate = #Predicate { $0.isActive }
        }
        return try context.fetch(descriptor)
    }

    func goal(with id: UUID) throws -> Goal? {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func insert(_ goal: Goal) throws {
        context.insert(goal)
        try save()
    }

    func delete(_ goal: Goal) throws {
        context.delete(goal)
        try save()
    }

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
