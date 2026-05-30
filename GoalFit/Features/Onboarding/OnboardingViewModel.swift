import Foundation

/// Drives the 4-step onboarding flow and asks for Health/Notification
/// permissions in their dedicated steps.
@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome
        case health
        case notifications
        case firstGoal
    }

    private(set) var step: Step = .welcome
    private(set) var didRequestHealth = false
    private(set) var didRequestNotifications = false

    private let healthService: HealthDataProviding
    private let notifications: NotificationScheduling

    init(healthService: HealthDataProviding, notifications: NotificationScheduling) {
        self.healthService = healthService
        self.notifications = notifications
    }

    var isLastStep: Bool { step == .firstGoal }

    /// Advance to the next step. No-op if already at the last step.
    func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    /// Jump back one step (for the back button on later screens).
    func goBack() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    /// Triggers HealthKit authorization once; then advances regardless of
    /// the outcome so the user is never stuck on the permission screen.
    func requestHealthAndAdvance() async {
        if healthService.isHealthDataAvailable, !didRequestHealth {
            didRequestHealth = true
            try? await healthService.requestAuthorization(for: GoalType.allCases)
        }
        advance()
    }

    /// Triggers notification authorization once and advances.
    func requestNotificationsAndAdvance() async {
        if !didRequestNotifications {
            didRequestNotifications = true
            _ = await notifications.requestAuthorization()
        }
        advance()
    }
}
