import SwiftUI
import SwiftData

@main
struct GoalFitApp: App {
    /// Contenedor compartido de SwiftData con el esquema de la app.
    let modelContainer: ModelContainer
    /// Contenedor de dependencias.
    @State private var container: AppContainer

    init() {
        do {
            let modelContainer = try ModelContainer(for: Goal.self)
            self.modelContainer = modelContainer
            _container = State(initialValue: AppContainer(context: modelContainer.mainContext))
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
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
