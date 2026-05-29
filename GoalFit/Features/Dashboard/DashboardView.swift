import SwiftUI
import UIKit

/// Main screen: lists active goals with their progress and allows creating,
/// editing and deleting them.
struct DashboardView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: DashboardViewModel?
    @State private var presentedForm: GoalFormRoute?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("GoalFit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentedForm = .create
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add goal")
                }
            }
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(
                    viewModel: GoalDetailViewModel(goal: goal, health: container.healthService)
                ) {
                    presentedForm = .edit(goal)
                }
            }
            .sheet(item: $presentedForm) { route in
                GoalFormView(
                    viewModel: GoalFormViewModel(
                        store: container.store,
                        goal: route.goal,
                        notifications: container.notifications
                    )
                ) {
                    Task { await viewModel?.load() }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = DashboardViewModel(
                    store: container.store,
                    healthService: container.healthService,
                    progressProvider: container.progressProvider,
                    notifications: container.notifications
                )
            }
            await viewModel?.requestHealthAuthorizationIfNeeded()
            await viewModel?.requestNotificationAuthorizationIfNeeded()
            await viewModel?.load()
        }
        .onChange(of: container.notificationCoordinator.state.pendingGoalId) { _, newValue in
            handleDeepLink(newValue)
        }
    }

    @ViewBuilder
    private func content(_ viewModel: DashboardViewModel) -> some View {
        if viewModel.isEmpty {
            VStack {
                banners(viewModel)
                EmptyStateView(
                    systemImage: "target",
                    title: "No goals yet",
                    message: "Create your first goal to start tracking your health progress.",
                    actionTitle: "Create goal",
                    action: { presentedForm = .create }
                )
            }
        } else {
            List {
                if shouldShowBanners(viewModel) {
                    Section { banners(viewModel).listRowInsets(EdgeInsets()) }
                }
                Section {
                    ForEach(viewModel.goals) { goal in
                        NavigationLink(value: goal) {
                            GoalCard(goal: goal, progress: viewModel.progress(for: goal))
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete { offsets in
                        Task { await viewModel.delete(at: offsets) }
                    }
                } header: {
                    summaryHeader(viewModel)
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.load() }
        }
    }

    private func shouldShowBanners(_ viewModel: DashboardViewModel) -> Bool {
        !viewModel.isHealthDataAvailable || viewModel.areNotificationsDenied
    }

    @ViewBuilder
    private func banners(_ viewModel: DashboardViewModel) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !viewModel.isHealthDataAvailable {
                infoBanner(
                    icon: "heart.text.square",
                    text: "Health data isn't available on this device. Progress may not update.",
                    actionTitle: nil,
                    actionURL: nil
                )
            }
            if viewModel.areNotificationsDenied {
                infoBanner(
                    icon: "bell.slash",
                    text: "Notifications are off. You won't get reminders or goal completion alerts.",
                    actionTitle: "Open Settings",
                    actionURL: URL(string: UIApplication.openSettingsURLString)
                )
            }
        }
    }

    private func infoBanner(icon: String, text: String, actionTitle: String?, actionURL: URL?) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.warning)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let actionTitle, let actionURL {
                    Link(actionTitle, destination: actionURL)
                        .font(.footnote.weight(.semibold))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func summaryHeader(_ viewModel: DashboardViewModel) -> some View {
        HStack {
            Text("\(viewModel.completedCount) of \(viewModel.goals.count) goals on track")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(nil)
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    /// Handles taps on a notification: navigates to the goal detail if found.
    private func handleDeepLink(_ goalId: UUID?) {
        guard let goalId else { return }
        // Reset the pending id so re-taps work.
        container.notificationCoordinator.state.pendingGoalId = nil
        if let goal = try? container.store.goal(with: goalId) {
            navigationPath = NavigationPath()
            navigationPath.append(goal)
        }
    }
}

/// Modal form route: create or edit a specific goal.
enum GoalFormRoute: Identifiable {
    case create
    case edit(Goal)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let goal): return goal.id.uuidString
        }
    }

    var goal: Goal? {
        switch self {
        case .create: return nil
        case .edit(let goal): return goal
        }
    }
}

#Preview {
    let container = AppContainer(
        store: InMemoryGoalStore.previewPopulated(),
        healthService: MockHealthService(),
        progressProvider: MockProgressProvider(),
        notifications: MockNotificationService(),
        notificationCoordinator: NotificationCoordinator()
    )
    return DashboardView()
        .environment(container)
}
