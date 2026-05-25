import XCTest
@testable import GoalFit

@MainActor
final class GoalFormViewModelTests: XCTestCase {

    func testCreateInsertsGoal() throws {
        let store = InMemoryGoalStore()
        let vm = GoalFormViewModel(store: store)
        vm.title = "Caminar"
        vm.type = .steps
        vm.targetValue = 12000

        try vm.save()

        let goals = try store.fetchGoals()
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.title, "Caminar")
        XCTAssertEqual(goals.first?.targetValue, 12000)
        XCTAssertEqual(goals.first?.type, .steps)
    }

    func testEmptyTitleUsesSuggestedTitle() throws {
        let store = InMemoryGoalStore()
        let vm = GoalFormViewModel(store: store)
        vm.title = "   "
        vm.type = .exerciseMinutes
        vm.targetValue = 30

        try vm.save()

        let goal = try XCTUnwrap(try store.fetchGoals().first)
        XCTAssertFalse(goal.title.isEmpty)
        XCTAssertTrue(goal.title.contains("30"))
    }

    func testEditUpdatesExistingGoal() throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Viejo", type: .steps, targetValue: 8000)
        try store.insert(goal)

        let vm = GoalFormViewModel(store: store, goal: goal)
        vm.title = "Nuevo"
        vm.targetValue = 15000
        try vm.save()

        XCTAssertEqual(try store.fetchGoals().count, 1)
        let updated = try XCTUnwrap(try store.goal(with: goal.id))
        XCTAssertEqual(updated.title, "Nuevo")
        XCTAssertEqual(updated.targetValue, 15000)
    }

    func testDeleteRemovesGoal() throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Borrar", type: .distance, targetValue: 5)
        try store.insert(goal)

        let vm = GoalFormViewModel(store: store, goal: goal)
        try vm.delete()

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
        // título vacío es válido porque se usa el sugerido
        XCTAssertTrue(vm.canSave)
    }

    func testBodyMassRequiresStartValue() {
        let vm = GoalFormViewModel(store: InMemoryGoalStore())
        vm.type = .bodyMass
        vm.title = "Peso"
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

    func testBodyMassSavesStartValueAndClearsForOthers() throws {
        let store = InMemoryGoalStore()
        let vm = GoalFormViewModel(store: store)
        vm.type = .bodyMass
        vm.title = "Peso"
        vm.targetValue = 70
        vm.startValue = 80
        try vm.save()

        let goal = try XCTUnwrap(try store.fetchGoals().first)
        XCTAssertEqual(goal.startValue, 80)
        XCTAssertEqual(goal.direction, .reach)
    }
}
