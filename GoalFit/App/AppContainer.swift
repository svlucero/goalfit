import Foundation
import SwiftData

/// App dependency container. Creates and injects services from SwiftData's
/// `ModelContext`. Exposed via SwiftUI's `Environment`.
@MainActor
@Observable
final class AppContainer {
    let store: GoalStoring
    let progressProvider: ProgressProviding

    init(context: ModelContext) {
        self.store = GoalRepository(context: context)
        self.progressProvider = MockProgressProvider()
    }

    /// Initializer to inject arbitrary dependencies (tests/previews).
    init(store: GoalStoring, progressProvider: ProgressProviding) {
        self.store = store
        self.progressProvider = progressProvider
    }
}
