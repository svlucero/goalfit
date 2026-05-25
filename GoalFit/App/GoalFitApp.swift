import SwiftUI
import SwiftData

@main
struct GoalFitApp: App {
    /// Contenedor compartido de SwiftData con el esquema de la app.
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Goal.self)
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
