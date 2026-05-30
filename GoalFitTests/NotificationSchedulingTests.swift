import XCTest
@testable import GoalFit

@MainActor
final class NotificationSchedulingTests: XCTestCase {

    // MARK: - GoalFormViewModel reminder side-effects

    func testSavingWithReminderEnabledSchedulesReminder() async throws {
        let store = InMemoryGoalStore()
        let notifications = MockNotificationService()
        let vm = GoalFormViewModel(store: store, notifications: notifications)
        vm.title = "Walk"
        vm.targetValue = 10000
        vm.reminderEnabled = true

        try await vm.save()

        let goal = try XCTUnwrap(try store.fetchGoals().first)
        XCTAssertEqual(notifications.calls, [.scheduleReminder(goalId: goal.id)])
    }

    func testSavingWithReminderDisabledCancelsReminder() async throws {
        let store = InMemoryGoalStore()
        let notifications = MockNotificationService()
        let vm = GoalFormViewModel(store: store, notifications: notifications)
        vm.title = "Walk"
        vm.targetValue = 10000
        vm.reminderEnabled = false

        try await vm.save()

        let goal = try XCTUnwrap(try store.fetchGoals().first)
        XCTAssertEqual(notifications.calls, [.cancelReminder(goalId: goal.id)])
    }

    func testEditingChangesReminderState() async throws {
        let store = InMemoryGoalStore()
        let notifications = MockNotificationService()
        let goal = Goal(
            title: "Walk", type: .steps, targetValue: 10000,
            reminderEnabled: true, reminderTime: Date()
        )
        try store.insert(goal)

        let vm = GoalFormViewModel(store: store, goal: goal, notifications: notifications)
        vm.reminderEnabled = false
        try await vm.save()

        XCTAssertEqual(notifications.calls, [.cancelReminder(goalId: goal.id)])
    }

    func testDeletingCancelsReminder() async throws {
        let store = InMemoryGoalStore()
        let notifications = MockNotificationService()
        let goal = Goal(title: "Walk", type: .steps, targetValue: 10000)
        try store.insert(goal)

        let vm = GoalFormViewModel(store: store, goal: goal, notifications: notifications)
        try await vm.delete()

        XCTAssertEqual(notifications.calls, [.cancelReminder(goalId: goal.id)])
    }

    // MARK: - DashboardViewModel completion notification

    /// Provider that completes a specific goal id once.
    private struct StubProgress: ProgressProviding {
        let completedIds: Set<UUID>
        func progress(for goal: Goal) async -> GoalProgress {
            let done = completedIds.contains(goal.id)
            return GoalProgress(
                goalId: goal.id,
                currentValue: done ? goal.targetValue : 0,
                targetValue: goal.targetValue,
                fraction: done ? 1 : 0,
                isCompleted: done,
                periodStart: Calendar.current.startOfDay(for: .now),
                periodEnd: .now,
                lastUpdated: .now
            )
        }
    }

    func testCompletionNotificationFiresOncePerPeriod() async throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Exercise", type: .exerciseMinutes, targetValue: 30)
        try store.insert(goal)
        let notifications = MockNotificationService()
        let vm = DashboardViewModel(
            store: store,
            healthService: MockHealthService(),
            progressProvider: StubProgress(completedIds: [goal.id]),
            notifications: notifications
        )

        await vm.load()
        await vm.load() // a second pass in the same period

        let completionCalls = notifications.calls.filter {
            if case .notifyCompleted = $0 { return true } else { return false }
        }
        XCTAssertEqual(completionCalls, [.notifyCompleted(goalId: goal.id)])
        XCTAssertNotNil(goal.lastCompletedPeriodStart)
    }

    func testCompletionDoesNotFireWhenNotCompleted() async throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Exercise", type: .exerciseMinutes, targetValue: 30)
        try store.insert(goal)
        let notifications = MockNotificationService()
        let vm = DashboardViewModel(
            store: store,
            healthService: MockHealthService(),
            progressProvider: StubProgress(completedIds: []),
            notifications: notifications
        )

        await vm.load()

        XCTAssertFalse(notifications.calls.contains { call in
            if case .notifyCompleted = call { return true } else { return false }
        })
    }

    func testTargetGoalCompletionFiresOnlyOnceEver() async throws {
        let store = InMemoryGoalStore()
        let goal = Goal(title: "Weight", type: .bodyMass, targetValue: 70, startValue: 80)
        try store.insert(goal)
        let notifications = MockNotificationService()
        let vm = DashboardViewModel(
            store: store,
            healthService: MockHealthService(),
            progressProvider: StubProgress(completedIds: [goal.id]),
            notifications: notifications
        )

        await vm.load()
        await vm.load()

        let completionCalls = notifications.calls.filter {
            if case .notifyCompleted = $0 { return true } else { return false }
        }
        XCTAssertEqual(completionCalls.count, 1)
    }
}
