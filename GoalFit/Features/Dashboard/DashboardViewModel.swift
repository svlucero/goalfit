import Foundation

/// ViewModel del dashboard: carga los objetivos desde el almacenamiento y calcula
/// el progreso de cada uno mediante el `ProgressProviding` inyectado.
@MainActor
@Observable
final class DashboardViewModel {
    private let store: GoalStoring
    private let progressProvider: ProgressProviding

    private(set) var goals: [Goal] = []
    private(set) var progressByGoal: [UUID: GoalProgress] = [:]
    private(set) var isLoading = false
    var errorMessage: String?

    init(store: GoalStoring, progressProvider: ProgressProviding) {
        self.store = store
        self.progressProvider = progressProvider
    }

    /// Cantidad de objetivos completados sobre el total (para el resumen del header).
    var completedCount: Int {
        goals.filter { progressByGoal[$0.id]?.isCompleted == true }.count
    }

    var isEmpty: Bool { goals.isEmpty }

    /// Carga objetivos activos y su progreso.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try store.fetchGoals(activeOnly: true)
            goals = fetched
            await recalculateProgress()
        } catch {
            errorMessage = "No se pudieron cargar los objetivos."
        }
    }

    func recalculateProgress() async {
        var map: [UUID: GoalProgress] = [:]
        for goal in goals {
            map[goal.id] = await progressProvider.progress(for: goal)
        }
        progressByGoal = map
    }

    func progress(for goal: Goal) -> GoalProgress? {
        progressByGoal[goal.id]
    }

    func delete(_ goal: Goal) async {
        do {
            try store.delete(goal)
            await load()
        } catch {
            errorMessage = "No se pudo eliminar el objetivo."
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { goals[$0] }
        for goal in toDelete {
            do { try store.delete(goal) }
            catch { errorMessage = "No se pudo eliminar el objetivo." }
        }
        await load()
    }
}
