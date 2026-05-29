import Foundation
import UserNotifications

/// `UNUserNotificationCenterDelegate` that captures notification taps and
/// publishes the tapped goal id so the UI can deep-link to its detail.
@MainActor
final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    /// Set when the user taps a notification with a `goalId` in userInfo.
    /// The UI observes it, navigates to the goal and resets it back to nil.
    @MainActor @Observable
    final class State {
        var pendingGoalId: UUID?
    }

    let state = State()

    /// Wires this coordinator as the delegate of the given center.
    func install(in center: UNUserNotificationCenter = .current()) {
        center.delegate = self
    }

    // Foreground delivery: show the banner anyway.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let raw = userInfo[NotificationService.goalIdUserInfoKey] as? String,
           let id = UUID(uuidString: raw) {
            Task { @MainActor in self.state.pendingGoalId = id }
        }
        completionHandler()
    }
}
