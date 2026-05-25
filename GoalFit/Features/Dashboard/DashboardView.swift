import SwiftUI

/// Pantalla principal: lista los objetivos activos con su progreso y permite
/// crear, editar y eliminar.
struct DashboardView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: DashboardViewModel?
    @State private var presentedForm: GoalFormRoute?
    @State private var editingGoal: Goal?

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
                    .accessibilityLabel("Agregar objetivo")
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
                    progressProvider: container.progressProvider
                )
            }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: DashboardViewModel) -> some View {
        if viewModel.isEmpty {
            EmptyStateView(
                systemImage: "target",
                title: "Sin objetivos todavía",
                message: "Creá tu primer objetivo para empezar a seguir tu progreso de salud.",
                actionTitle: "Crear objetivo",
                action: { presentedForm = .create }
            )
        } else {
            List {
                Section {
                    ForEach(viewModel.goals) { goal in
                        Button {
                            presentedForm = .edit(goal)
                        } label: {
                            GoalCard(goal: goal, progress: viewModel.progress(for: goal))
                        }
                        .buttonStyle(.plain)
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

    private func summaryHeader(_ viewModel: DashboardViewModel) -> some View {
        HStack {
            Text("\(viewModel.completedCount) de \(viewModel.goals.count) objetivos al día")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(nil)
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

/// Ruta del formulario modal: crear o editar un objetivo concreto.
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
        progressProvider: MockProgressProvider()
    )
    return DashboardView()
        .environment(container)
}
