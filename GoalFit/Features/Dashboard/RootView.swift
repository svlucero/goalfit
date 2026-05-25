import SwiftUI
import SwiftData

/// Vista raíz de la app. En el Milestone 0 muestra el dashboard base con los
/// objetivos persistidos (progreso simulado hasta integrar HealthKit en M2).
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    EmptyStateView(
                        systemImage: "target",
                        title: "Sin objetivos todavía",
                        message: "Creá tu primer objetivo para empezar a seguir tu progreso de salud.",
                        actionTitle: "Crear objetivo de ejemplo",
                        action: addSampleGoal
                    )
                } else {
                    List {
                        ForEach(goals) { goal in
                            GoalCard(goal: goal, progress: sampleProgress(for: goal))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete(perform: deleteGoals)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("GoalFit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addSampleGoal) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Agregar objetivo")
                }
            }
        }
    }

    /// Progreso simulado hasta integrar HealthKit (M2). Usa la lógica real de
    /// `ProgressCalculator` con un valor de ejemplo proporcional a la meta.
    private func sampleProgress(for goal: Goal) -> GoalProgress {
        let mockValue = goal.targetValue * 0.62
        return ProgressCalculator.progress(
            for: goal,
            currentValue: mockValue,
            periodStart: .now,
            periodEnd: .now
        )
    }

    private func addSampleGoal() {
        let goal = Goal(title: "Caminar 10.000 pasos", type: .steps, targetValue: 10000)
        modelContext.insert(goal)
    }

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(goals[index])
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Goal.self, inMemory: true)
}
