import XCTest
@testable import GoalFit

@MainActor
final class DashboardViewModelTests: XCTestCase {

    /// Deterministic provider that completes goals listed in `completedIds`.
    private struct StubProgressProvider: ProgressProviding {
        let completedIds: Set<UUID>
        func progress(for goal: Goal) async -> GoalProgress {
            let completed = completedIds.contains(goal.id)
            return GoalProgress(
                goalId: goal.id,
                currentValue: completed ? goal.targetValue : goal.targetValue / 2,
                targetValue: goal.targetValue,
                fraction: completed ? 1 : 0.5,
                isCompleted: completed,
                periodStart: .now, periodEnd: .now, lastUpdated: .now
            )
        }
    }

    func testLoadPopulatesGoalsAndProgress() async throws {
        let store = InMemoryGoalStore.previewPopulated()
        let goals = try store.fetchGoals()
        let vm = DashboardViewModel(
            store: store,
            healthService: MockHealthService(),
            progressProvider: StubProgressProvider(completedIds: [goals[0].id]),
            notifications: MockNotificationService()
        )

        await vm.load()

        XCTAssertEqual(vm.goals.count, 3)
        XCTAssertFalse(vm.isEmpty)
        XCTAssertNotNil(vm.progress(for: goals[0]))
        XCTAssertEqual(vm.completedCount, 1)
    }

    func testEmptyStore() async {
        let vm = DashboardViewModel(
            store: InMemoryGoalStore(),
            healthService: MockHealthService(),
            progressProvider: MockProgressProvider(),
            notifications: MockNotificationService()
        )
        await vm.load()
        XCTAssertTrue(vm.isEmpty)
        XCTAssertEqual(vm.completedCount, 0)
    }

    func testDeleteRemovesGoal() async throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Delete me", type: .steps, targetValue: 10000)
        try store.insert(goal)
        let vm = DashboardViewModel(store: store, healthService: MockHealthService(), progressProvider: MockProgressProvider(), notifications: MockNotificationService())
        await vm.load()
        XCTAssertEqual(vm.goals.count, 1)

        await vm.delete(goal)

        XCTAssertTrue(vm.isEmpty)
        XCTAssertEqual(try store.fetchGoals().count, 0)
    }

    func testOnlyActiveGoalsAreLoaded() async throws {
        let store = InMemoryGoalStore()
        try store.insert(Goal(title: "Active", type: .steps, targetValue: 10000, isActive: true))
        try store.insert(Goal(title: "Archived", type: .steps, targetValue: 9000, isActive: false))
        let vm = DashboardViewModel(store: store, healthService: MockHealthService(), progressProvider: MockProgressProvider(), notifications: MockNotificationService())

        await vm.load()

        XCTAssertEqual(vm.goals.count, 1)
        XCTAssertEqual(vm.goals.first?.title, "Active")
    }
}
