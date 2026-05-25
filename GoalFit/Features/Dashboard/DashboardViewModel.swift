import Foundation

/// Dashboard ViewModel: loads goals from storage and computes each one's
/// progress through the injected `ProgressProviding`.
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

    /// Number of completed goals out of the total (for the header summary).
    var completedCount: Int {
        goals.filter { progressByGoal[$0.id]?.isCompleted == true }.count
    }

    var isEmpty: Bool { goals.isEmpty }

    /// Loads active goals and their progress.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try store.fetchGoals(activeOnly: true)
            goals = fetched
            await recalculateProgress()
        } catch {
            errorMessage = "Couldn't load goals."
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
            errorMessage = "Couldn't delete the goal."
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { goals[$0] }
        for goal in toDelete {
            do { try store.delete(goal) }
            catch { errorMessage = "Couldn't delete the goal." }
        }
        await load()
    }
}
