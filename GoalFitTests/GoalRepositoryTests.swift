import XCTest
import SwiftData
@testable import GoalFit

@MainActor
final class GoalRepositoryTests: XCTestCase {

    private func makeRepository() throws -> GoalRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Goal.self, configurations: config)
        return GoalRepository(context: container.mainContext)
    }

    func testInsertAndFetch() throws {
        let repo = try makeRepository()
        let goal = Goal(title: "Pasos", type: .steps, targetValue: 10000)

        try repo.insert(goal)
        let goals = try repo.fetchGoals()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.title, "Pasos")
        XCTAssertEqual(goals.first?.type, .steps)
    }

    func testFetchById() throws {
        let repo = try makeRepository()
        let goal = Goal(title: "Peso", type: .bodyMass, targetValue: 70, startValue: 80)
        try repo.insert(goal)

        let found = try repo.goal(with: goal.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, goal.id)
        XCTAssertEqual(found?.startValue, 80)
    }

    func testDelete() throws {
        let repo = try makeRepository()
        let goal = Goal(title: "Distancia", type: .distance, targetValue: 5)
        try repo.insert(goal)
        XCTAssertEqual(try repo.fetchGoals().count, 1)

        try repo.delete(goal)
        XCTAssertEqual(try repo.fetchGoals().count, 0)
    }

    func testFetchActiveOnly() throws {
        let repo = try makeRepository()
        let active = Goal(title: "Activo", type: .steps, targetValue: 10000, isActive: true)
        let archived = Goal(title: "Archivado", type: .steps, targetValue: 8000, isActive: false)
        try repo.insert(active)
        try repo.insert(archived)

        let activeGoals = try repo.fetchGoals(activeOnly: true)
        XCTAssertEqual(activeGoals.count, 1)
        XCTAssertEqual(activeGoals.first?.title, "Activo")

        XCTAssertEqual(try repo.fetchGoals(activeOnly: false).count, 2)
    }

    func testEnumRoundTrip() throws {
        let repo = try makeRepository()
        let goal = Goal(
            title: "Límite calorías", type: .activeEnergy,
            period: .weekly, direction: .atMost, targetValue: 3500
        )
        try repo.insert(goal)

        let fetched = try repo.goal(with: goal.id)
        XCTAssertEqual(fetched?.type, .activeEnergy)
        XCTAssertEqual(fetched?.period, .weekly)
        XCTAssertEqual(fetched?.direction, .atMost)
    }
}
