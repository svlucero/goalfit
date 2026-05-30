import Foundation

/// Settings screen ViewModel. Surfaces permission states and applies the
/// global notifications switch by (re)scheduling or cancelling reminders for
/// every active goal.
@MainActor
@Observable
final class SettingsViewModel {
    private let store: GoalStoring
    private let healthService: HealthDataProviding
    private let notifications: NotificationScheduling

    private(set) var notificationStatus: NotificationAuthorizationStatus = .notDetermined

    init(
        store: GoalStoring,
        healthService: HealthDataProviding,
        notifications: NotificationScheduling
    ) {
        self.store = store
        self.healthService = healthService
        self.notifications = notifications
    }

    var isHealthDataAvailable: Bool { healthService.isHealthDataAvailable }

    /// Refreshes the notification authorization status (e.g. when the screen
    /// appears, since the user may have changed it in system Settings).
    func refresh() async {
        notificationStatus = await notifications.authorizationStatus()
    }

    /// Applies the new global on/off state: on → reschedule all reminders for
    /// goals with `reminderEnabled`; off → cancel every reminder.
    func applyGlobalNotificationsToggle(_ enabled: Bool) async {
        let goals = (try? store.fetchGoals(activeOnly: true)) ?? []
        if enabled {
            for goal in goals where goal.reminderEnabled {
                await notifications.scheduleDailyReminder(for: goal)
            }
        } else {
            for goal in goals {
                await notifications.cancelReminder(for: goal)
            }
        }
    }

    /// Short, user-facing description of the notification status.
    var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .notDetermined: return "Not requested yet"
        }
    }
}
