import SwiftUI
import SwiftData

@main
struct GoalFitApp: App {
    /// Shared SwiftData container with the app schema.
    let modelContainer: ModelContainer
    /// Dependency container.
    @State private var container: AppContainer

    init() {
        do {
            let modelContainer = try ModelContainer(for: Goal.self)
            self.modelContainer = modelContainer
            _container = State(initialValue: AppContainer(context: modelContainer.mainContext))
        } catch {
            fatalError("Could not create the ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(container)
        }
        .modelContainer(modelContainer)
    }
}
