import SwiftUI

/// Formulario para crear o editar un objetivo.
struct GoalFormView: View {
    @State var viewModel: GoalFormViewModel
    /// Se llama tras guardar/eliminar para que el dashboard recargue.
    var onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                goalSection
                if viewModel.requiresStartValue { startSection }
                if viewModel.type == .bodyMass { deadlineSection }
                reminderSection
                if viewModel.isEditing { deleteSection }
            }
            .navigationTitle(viewModel.isEditing ? "Editar objetivo" : "Nuevo objetivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: handleSave)
                        .disabled(!viewModel.canSave)
                }
            }
            .confirmationDialog(
                "¿Eliminar este objetivo?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive, action: handleDelete)
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    // MARK: - Secciones

    private var typeSection: some View {
        Section("Tipo") {
            Picker("Tipo de objetivo", selection: $viewModel.type) {
                ForEach(GoalType.allCases) { type in
                    Label(type.displayName, systemImage: type.systemImage).tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var goalSection: some View {
        Section("Objetivo") {
            TextField("Título", text: $viewModel.title, prompt: Text(viewModel.suggestedTitle()))

            HStack {
                Text("Meta")
                Spacer()
                TextField("Meta", value: $viewModel.targetValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                Text(viewModel.unit).foregroundStyle(.secondary)
            }

            if viewModel.type != .bodyMass {
                Picker("Período", selection: $viewModel.period) {
                    Text("Diario").tag(GoalPeriod.daily)
                    Text("Semanal").tag(GoalPeriod.weekly)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var startSection: some View {
        Section {
            HStack {
                Text("Peso actual")
                Spacer()
                TextField("Peso", value: $viewModel.startValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                Text("kg").foregroundStyle(.secondary)
            }
        } header: {
            Text("Valor de partida")
        } footer: {
            Text("Se usa para calcular tu progreso hacia el peso objetivo.")
        }
    }

    private var deadlineSection: some View {
        Section {
            Toggle("Fecha límite", isOn: $viewModel.hasDeadline)
            if viewModel.hasDeadline {
                DatePicker("Fecha", selection: $viewModel.deadline, in: Date()..., displayedComponents: .date)
            }
        }
    }

    private var reminderSection: some View {
        Section("Recordatorio") {
            Toggle("Recordarme", isOn: $viewModel.reminderEnabled)
            if viewModel.reminderEnabled {
                DatePicker("Hora", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Eliminar objetivo", role: .destructive) {
                showDeleteConfirm = true
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Acciones

    private func handleSave() {
        do {
            try viewModel.save()
            onFinish()
            dismiss()
        } catch {
            // En M1 los errores de persistencia son improbables; se ignoran de momento.
        }
    }

    private func handleDelete() {
        do {
            try viewModel.delete()
            onFinish()
            dismiss()
        } catch {}
    }
}

#Preview("Crear") {
    GoalFormView(viewModel: GoalFormViewModel(store: InMemoryGoalStore())) {}
}

#Preview("Editar") {
    let goal = Goal(title: "Caminar", type: .steps, targetValue: 10000)
    return GoalFormView(viewModel: GoalFormViewModel(store: InMemoryGoalStore(), goal: goal)) {}
}
