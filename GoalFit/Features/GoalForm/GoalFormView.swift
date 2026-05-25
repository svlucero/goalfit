import SwiftUI

/// Form to create or edit a goal.
struct GoalFormView: View {
    @State var viewModel: GoalFormViewModel
    /// Called after saving/deleting so the dashboard reloads.
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
            .navigationTitle(viewModel.isEditing ? "Edit goal" : "New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: handleSave)
                        .disabled(!viewModel.canSave)
                }
            }
            .confirmationDialog(
                "Delete this goal?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: handleDelete)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    private var typeSection: some View {
        Section("Type") {
            Picker("Goal type", selection: $viewModel.type) {
                ForEach(GoalType.allCases) { type in
                    Label(type.displayName, systemImage: type.systemImage).tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var goalSection: some View {
        Section("Goal") {
            TextField("Title", text: $viewModel.title, prompt: Text(viewModel.suggestedTitle()))

            HStack {
                Text("Target")
                Spacer()
                TextField("Target", value: $viewModel.targetValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                Text(viewModel.unit).foregroundStyle(.secondary)
            }

            if viewModel.type != .bodyMass {
                Picker("Period", selection: $viewModel.period) {
                    Text("Daily").tag(GoalPeriod.daily)
                    Text("Weekly").tag(GoalPeriod.weekly)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var startSection: some View {
        Section {
            HStack {
                Text("Current weight")
                Spacer()
                TextField("Weight", value: $viewModel.startValue, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                Text("kg").foregroundStyle(.secondary)
            }
        } header: {
            Text("Start value")
        } footer: {
            Text("Used to calculate your progress toward the target weight.")
        }
    }

    private var deadlineSection: some View {
        Section {
            Toggle("Deadline", isOn: $viewModel.hasDeadline)
            if viewModel.hasDeadline {
                DatePicker("Date", selection: $viewModel.deadline, in: Date()..., displayedComponents: .date)
            }
        }
    }

    private var reminderSection: some View {
        Section("Reminder") {
            Toggle("Remind me", isOn: $viewModel.reminderEnabled)
            if viewModel.reminderEnabled {
                DatePicker("Time", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete goal", role: .destructive) {
                showDeleteConfirm = true
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func handleSave() {
        do {
            try viewModel.save()
            onFinish()
            dismiss()
        } catch {
            // In M1 persistence errors are unlikely; ignored for now.
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

#Preview("Create") {
    GoalFormView(viewModel: GoalFormViewModel(store: InMemoryGoalStore())) {}
}

#Preview("Edit") {
    let goal = Goal(title: "Walk", type: .steps, targetValue: 10000)
    return GoalFormView(viewModel: GoalFormViewModel(store: InMemoryGoalStore(), goal: goal)) {}
}
