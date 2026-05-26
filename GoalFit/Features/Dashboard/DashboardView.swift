import SwiftUI

/// Main screen: lists active goals with their progress and allows creating,
/// editing and deleting them.
struct DashboardView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: DashboardViewModel?
    @State private var presentedForm: GoalFormRoute?

    var body: some View {
        NavigationStack {
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
                        goal: route.goal
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
                    progressProvider: container.progressProvider
                )
            }
            await viewModel?.requestHealthAuthorizationIfNeeded()
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: DashboardViewModel) -> some View {
        if viewModel.isEmpty {
            VStack {
                if !viewModel.isHealthDataAvailable { healthBanner }
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
                if !viewModel.isHealthDataAvailable {
                    Section { healthBanner.listRowInsets(EdgeInsets()) }
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

    private var healthBanner: some View {
        Label(
            "Health data isn't available on this device. Progress may not update.",
            systemImage: "heart.text.square"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
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
        progressProvider: MockProgressProvider()
    )
    return DashboardView()
        .environment(container)
}
