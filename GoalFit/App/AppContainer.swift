import Foundation
import SwiftData

/// Contenedor de dependencias de la app. Crea e inyecta los servicios a partir
/// del `ModelContext` de SwiftData. Se expone vía el `Environment` de SwiftUI.
@MainActor
@Observable
final class AppContainer {
    let store: GoalStoring
    let progressProvider: ProgressProviding

    init(context: ModelContext) {
        self.store = GoalRepository(context: context)
        self.progressProvider = MockProgressProvider()
    }

    /// Inicializador para inyectar dependencias arbitrarias (tests/previews).
    init(store: GoalStoring, progressProvider: ProgressProviding) {
        self.store = store
        self.progressProvider = progressProvider
    }
}
