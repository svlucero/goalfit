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

    init(context: ModelContext) {
        let health = HealthKitService()
        self.store = GoalRepository(context: context)
        self.healthService = health
        self.progressProvider = HealthKitProgressProvider(health: health)
    }

    /// Initializer to inject arbitrary dependencies (tests/previews).
    init(
        store: GoalStoring,
        healthService: HealthDataProviding,
        progressProvider: ProgressProviding
    ) {
        self.store = store
        self.healthService = healthService
        self.progressProvider = progressProvider
    }
}
