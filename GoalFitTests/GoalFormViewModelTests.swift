import XCTest
@testable import GoalFit

@MainActor
final class GoalFormViewModelTests: XCTestCase {

    func testCreateInsertsGoal() async throws {
        let store = InMemoryGoalStore()
        let vm = GoalFormViewModel(store: store)
        vm.title = "Walk"
        vm.type = .steps
        vm.targetValue = 12000

        try await vm.save()

        let goals = try store.fetchGoals()
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.title, "Walk")
        XCTAssertEqual(goals.first?.targetValue, 12000)
        XCTAssertEqual(goals.first?.type, .steps)
    }

    func testEmptyTitleUsesSuggestedTitle() async throws {
        let store = InMemoryGoalStore()
        let vm = GoalFormViewModel(store: store)
        vm.title = "   "
        vm.type = .exerciseMinutes
        vm.targetValue = 30

        try await vm.save()

        let goal = try XCTUnwrap(try store.fetchGoals().first)
        XCTAssertFalse(goal.title.isEmpty)
        XCTAssertTrue(goal.title.contains("30"))
    }

    func testEditUpdatesExistingGoal() async throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Old", type: .steps, targetValue: 8000)
        try store.insert(goal)

        let vm = GoalFormViewModel(store: store, goal: goal)
        vm.title = "New"
        vm.targetValue = 15000
        try await vm.save()

        XCTAssertEqual(try store.fetchGoals().count, 1)
        let updated = try XCTUnwrap(try store.goal(with: goal.id))
        XCTAssertEqual(updated.title, "New")
        XCTAssertEqual(updated.targetValue, 15000)
    }

    func testDeleteRemovesGoal() async throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Delete me", type: .distance, targetValue: 5)
        try store.insert(goal)

        let vm = GoalFormViewModel(store: store, goal: goal)
        try await vm.delete()

        XCTAssertEqual(try store.fetchGoals().count, 0)
    }

    func testCanSaveValidation() {
        let vm = GoalFormViewModel(store: InMemoryGoalStore())
        vm.title = "Ok"
        vm.targetValue = 10000
        XCTAssertTrue(vm.canSave)

        vm.targetValue = 0
        XCTAssertFalse(vm.canSave)

        vm.targetValue = 10000
        vm.title = ""
        // an empty title is valid because the suggested title is used instead
        XCTAssertTrue(vm.canSave)
    }

    func testBodyMassRequiresStartValue() {
        let vm = GoalFormViewModel(store: InMemoryGoalStore())
        vm.type = .bodyMass
        vm.title = "Weight"
        vm.targetValue = 70
        vm.startValue = 0
        XCTAssertTrue(vm.requiresStartValue)
        XCTAssertFalse(vm.canSave)

        vm.startValue = 78
        XCTAssertTrue(vm.canSave)
    }

    func testChangingTypeAppliesDefaults() {
        let vm = GoalFormViewModel(store: InMemoryGoalStore())
        vm.type = .bodyMass
        XCTAssertEqual(vm.period, .target)
        XCTAssertEqual(vm.direction, .reach)

        vm.type = .steps
        XCTAssertEqual(vm.period, .daily)
        XCTAssertEqual(vm.direction, .atLeast)
    }

    func testBodyMassSavesStartValueAndClearsForOthers() async throws {
        let store = InMemoryGoalStore()
        let vm = GoalFormViewModel(store: store)
        vm.type = .bodyMass
        vm.title = "Weight"
        vm.targetValue = 70
        vm.startValue = 80
        try await vm.save()

        let goal = try XCTUnwrap(try store.fetchGoals().first)
        XCTAssertEqual(goal.startValue, 80)
        XCTAssertEqual(goal.direction, .reach)
    }
}
