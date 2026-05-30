import Foundation
import SwiftData

/// App dependency container. Creates and injects services from SwiftData's
/// `ModelContext`. Exposed via SwiftUI's `Environment`.
@MainActor
@Observable
final class AppContainer {
    let store: GoalStoring
    let healthService: HealthDataProviding
    let progressProvider: ProgressProviding
    let notifications: NotificationScheduling
    let notificationCoordinator: NotificationCoordinator

    init(context: ModelContext) {
        let health = HealthKitService()
        let coordinator = NotificationCoordinator()
        coordinator.install()
        self.store = GoalRepository(context: context)
        self.healthService = health
        self.progressProvider = HealthKitProgressProvider(health: health)
        self.notifications = NotificationService()
        self.notificationCoordinator = coordinator
    }

    /// Initializer to inject arbitrary dependencies (tests/previews).
    init(
        store: GoalStoring,
        healthService: HealthDataProviding,
        progressProvider: ProgressProviding,
        notifications: NotificationScheduling,
        notificationCoordinator: NotificationCoordinator
    ) {
        self.store = store
        self.healthService = healthService
        self.progressProvider = progressProvider
        self.notifications = notifications
        self.notificationCoordinator = notificationCoordinator
    }
}
