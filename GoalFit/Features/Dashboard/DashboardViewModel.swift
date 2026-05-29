import Foundation

/// Dashboard ViewModel: loads goals from storage and computes each one's
/// progress through the injected `ProgressProviding`. Also requests health and
/// notification authorization and fires completion notifications.
@MainActor
@Observable
final class DashboardViewModel {
    private let store: GoalStoring
    private let healthService: HealthDataProviding
    private let progressProvider: ProgressProviding
    private let notifications: NotificationScheduling

    private(set) var goals: [Goal] = []
    private(set) var progressByGoal: [UUID: GoalProgress] = [:]
    private(set) var isLoading = false
    private(set) var didRequestHealthAuthorization = false
    private(set) var didRequestNotificationAuthorization = false
    private(set) var notificationStatus: NotificationAuthorizationStatus = .notDetermined
    var errorMessage: String?

    init(
        store: GoalStoring,
        healthService: HealthDataProviding,
        progressProvider: ProgressProviding,
        notifications: NotificationScheduling
    ) {
        self.store = store
        self.healthService = healthService
        self.progressProvider = progressProvider
        self.notifications = notifications
    }

    /// Whether health data is available on this device.
    var isHealthDataAvailable: Bool { healthService.isHealthDataAvailable }

    /// Whether the user has explicitly denied notification permission.
    var areNotificationsDenied: Bool { notificationStatus == .denied }

    /// Requests HealthKit read authorization once, for every supported metric.
    func requestHealthAuthorizationIfNeeded() async {
        guard !didRequestHealthAuthorization, healthService.isHealthDataAvailable else { return }
        didRequestHealthAuthorization = true
        try? await healthService.requestAuthorization(for: GoalType.allCases)
    }

    /// Asks for notification permission once and refreshes the status.
    func requestNotificationAuthorizationIfNeeded() async {
        notificationStatus = await notifications.authorizationStatus()
        guard !didRequestNotificationAuthorization,
              notificationStatus == .notDetermined else { return }
        didRequestNotificationAuthorization = true
        _ = await notifications.requestAuthorization()
        notificationStatus = await notifications.authorizationStatus()
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
        var newlyCompleted: [(Goal, GoalProgress)] = []
        for goal in goals {
            let progress = await progressProvider.progress(for: goal)
            map[goal.id] = progress
            if progress.isCompleted, shouldNotifyCompletion(for: goal, progress: progress) {
                newlyCompleted.append((goal, progress))
            }
        }
        progressByGoal = map

        for (goal, progress) in newlyCompleted {
            await notifications.notifyGoalCompleted(goal)
            goal.lastCompletedPeriodStart = progress.periodStart
        }
        if !newlyCompleted.isEmpty {
            try? store.save()
        }
    }

    /// True if `goal` just became completed in a period we haven't notified yet.
    private func shouldNotifyCompletion(for goal: Goal, progress: GoalProgress) -> Bool {
        guard progress.isCompleted else { return false }
        switch goal.period {
        case .target:
            // Notify only once for target goals (e.g. reaching weight).
            return goal.lastCompletedPeriodStart == nil
        case .daily, .weekly:
            return goal.lastCompletedPeriodStart != progress.periodStart
        }
    }

    func progress(for goal: Goal) -> GoalProgress? {
        progressByGoal[goal.id]
    }

    func delete(_ goal: Goal) async {
        do {
            await notifications.cancelReminder(for: goal)
            try store.delete(goal)
            await load()
        } catch {
            errorMessage = "Couldn't delete the goal."
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { goals[$0] }
        for goal in toDelete {
            await notifications.cancelReminder(for: goal)
            do { try store.delete(goal) }
            catch { errorMessage = "Couldn't delete the goal." }
        }
        await load()
    }
}
