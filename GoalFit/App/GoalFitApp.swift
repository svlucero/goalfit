import SwiftUI
import SwiftData

@main
struct GoalFitApp: App {
    /// Shared SwiftData container with the app schema.
    let modelContainer: ModelContainer
    /// Dependency container.
    @State private var container: AppContainer

    init() {
        let modelContainer = Self.makeModelContainer()
        self.modelContainer = modelContainer
        _container = State(initialValue: AppContainer(context: modelContainer.mainContext))
    }

    /// Builds the SwiftData container, falling back to an in-memory store if the
    /// on-disk store can't be opened (e.g. corrupted file or disk pressure).
    /// Without this fallback any I/O error at launch would crash the app.
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Goal.self])
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema)]
            )
        } catch {
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
            } catch {
                fatalError("Could not create even the in-memory ModelContainer: \(error)")
            }
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
