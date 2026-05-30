import Foundation
import UserNotifications

/// Real implementation of `NotificationScheduling` backed by
/// `UNUserNotificationCenter`. Uses deterministic identifiers per goal so that
/// scheduling twice replaces the previous request, and cancel works by id.
@MainActor
final class NotificationService: NotificationScheduling {
    static let goalIdUserInfoKey = "goalId"
    static let kindUserInfoKey = "kind"
    static let reminderKind = "reminder"
    static let completedKind = "completed"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .notDetermined
        }
    }

    // MARK: - Reminders

    func scheduleDailyReminder(for goal: Goal) async {
        guard goal.reminderEnabled, let time = goal.reminderTime else { return }

        let content = UNMutableNotificationContent()
        content.title = goal.title
        content.body = reminderBody(for: goal)
        content.sound = .default
        content.userInfo = [
            Self.goalIdUserInfoKey: goal.id.uuidString,
            Self.kindUserInfoKey: Self.reminderKind
        ]

        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.reminderIdentifier(for: goal),
            content: content,
            trigger: trigger
        )

        // Remove the previous one (if any) and add the new one.
        center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
        do { try await center.add(request) } catch { /* silent in MVP */ }
    }

    func cancelReminder(for goal: Goal) async {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.reminderIdentifier(for: goal)]
        )
    }

    // MARK: - Completion

    func notifyGoalCompleted(_ goal: Goal) async {
        let content = UNMutableNotificationContent()
        content.title = "Goal completed 🎉"
        content.body = completionBody(for: goal)
        content.sound = .default
        content.userInfo = [
            Self.goalIdUserInfoKey: goal.id.uuidString,
            Self.kindUserInfoKey: Self.completedKind
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.completedIdentifier(for: goal),
            content: content,
            trigger: trigger
        )
        do { try await center.add(request) } catch { /* silent */ }
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Identifiers

    static func reminderIdentifier(for goal: Goal) -> String {
        "reminder-\(goal.id.uuidString)"
    }

    static func completedIdentifier(for goal: Goal) -> String {
        "completed-\(goal.id.uuidString)"
    }

    // MARK: - Copy

    private func reminderBody(for goal: Goal) -> String {
        switch goal.type {
        case .steps: return "Time to move toward your \(Int(goal.targetValue)) steps."
        case .distance: return "A short walk gets you closer to your \(goal.targetValue.formatted()) km."
        case .activeEnergy: return "Burn some calories toward your \(Int(goal.targetValue)) kcal."
        case .exerciseMinutes: return "How about \(Int(goal.targetValue)) min of exercise today?"
        case .bodyMass: return "Log your weight to keep tracking your progress."
        }
    }

    private func completionBody(for goal: Goal) -> String {
        switch goal.type {
        case .bodyMass: return "You reached your target weight. Amazing!"
        default: return "You hit \"\(goal.title)\". Keep it up!"
        }
    }
}
