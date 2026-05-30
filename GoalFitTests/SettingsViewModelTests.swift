import XCTest
@testable import GoalFit

@MainActor
final class SettingsViewModelTests: XCTestCase {

    func testRefreshReadsStatusFromService() async {
        let notifications = MockNotificationService()
        notifications.status = .denied
        let vm = SettingsViewModel(
            store: InMemoryGoalStore(),
            healthService: MockHealthService(),
            notifications: notifications
        )

        await vm.refresh()

        XCTAssertEqual(vm.notificationStatus, .denied)
        XCTAssertEqual(vm.notificationStatusText, "Denied")
    }

    func testGlobalToggleOnReschedulesEnabledRemindersOnly() async throws {
        let store = InMemoryGoalStore()
        let withReminder = Goal(
            title: "Walk", type: .steps, targetValue: 10000,
            reminderEnabled: true, reminderTime: Date()
        )
        let withoutReminder = Goal(title: "Calories", type: .activeEnergy, targetValue: 500)
        try store.insert(withReminder)
        try store.insert(withoutReminder)

        let notifications = MockNotificationService()
        let vm = SettingsViewModel(
            store: store,
            healthService: MockHealthService(),
            notifications: notifications
        )

        await vm.applyGlobalNotificationsToggle(true)

        XCTAssertEqual(notifications.calls, [.scheduleReminder(goalId: withReminder.id)])
    }

    func testGlobalToggleOffCancelsAllReminders() async throws {
        let store = InMemoryGoalStore()
        let goal1 = Goal(
            title: "Walk", type: .steps, targetValue: 10000,
            reminderEnabled: true, reminderTime: Date()
        )
        let goal2 = Goal(title: "Calories", type: .activeEnergy, targetValue: 500)
        try store.insert(goal1)
        try store.insert(goal2)

        let notifications = MockNotificationService()
        let vm = SettingsViewModel(
            store: store,
            healthService: MockHealthService(),
            notifications: notifications
        )

        await vm.applyGlobalNotificationsToggle(false)

        // Cancels for every active goal, regardless of reminderEnabled (so any
        // stale reminder for a goal whose toggle was just flipped off is also gone).
        XCTAssertEqual(notifications.calls.count, 2)
        XCTAssertTrue(notifications.calls.contains(.cancelReminder(goalId: goal1.id)))
        XCTAssertTrue(notifications.calls.contains(.cancelReminder(goalId: goal2.id)))
    }
}
