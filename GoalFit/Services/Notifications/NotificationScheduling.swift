import Foundation

/// Current authorization status for local notifications, reduced to the
/// states the UI cares about.
enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}

/// Abstraction over the local notification scheduler. Lets us inject the real
/// `NotificationService` or a recording mock in tests/previews.
@MainActor
protocol NotificationScheduling {
    /// Asks the system for authorization. Returns `true` if granted.
    func requestAuthorization() async -> Bool

    /// Current authorization status, observed from `UNNotificationCenter`.
    func authorizationStatus() async -> NotificationAuthorizationStatus

    /// Schedules (or replaces) the daily reminder for `goal` at its
    /// `reminderTime`. No-op if `reminderEnabled` is false or no time is set.
    func scheduleDailyReminder(for goal: Goal) async

    /// Cancels the pending reminder for `goal`, if any.
    func cancelReminder(for goal: Goal) async

    /// Sends a "goal completed" notification immediately.
    func notifyGoalCompleted(_ goal: Goal) async

    /// Cancels all pending notifications.
    func cancelAll() async
}

// MARK: - Mock

/// In-memory mock that records the calls made to it. Used by tests and previews.
@MainActor
final class MockNotificationService: NotificationScheduling {
    enum Call: Equatable {
        case requestAuthorization
        case scheduleReminder(goalId: UUID)
        case cancelReminder(goalId: UUID)
        case notifyCompleted(goalId: UUID)
        case cancelAll
    }

    var grantsAuthorization = true
    var status: NotificationAuthorizationStatus = .authorized
    private(set) var calls: [Call] = []

    func requestAuthorization() async -> Bool {
        calls.append(.requestAuthorization)
        if grantsAuthorization { status = .authorized } else { status = .denied }
        return grantsAuthorization
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus { status }

    func scheduleDailyReminder(for goal: Goal) async {
        guard goal.reminderEnabled, goal.reminderTime != nil else { return }
        calls.append(.scheduleReminder(goalId: goal.id))
    }

    func cancelReminder(for goal: Goal) async {
        calls.append(.cancelReminder(goalId: goal.id))
    }

    func notifyGoalCompleted(_ goal: Goal) async {
        calls.append(.notifyCompleted(goalId: goal.id))
    }

    func cancelAll() async {
        calls.append(.cancelAll)
    }
}
