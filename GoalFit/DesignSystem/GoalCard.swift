import SwiftUI

/// Tarjeta que resume un objetivo y su progreso en el dashboard.
struct GoalCard: View {
    let goal: Goal
    let progress: GoalProgress?

    private var fraction: Double { progress?.fraction ?? 0 }
    private var isCompleted: Bool { progress?.isCompleted ?? false }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ProgressRing(
                fraction: fraction,
                isCompleted: isCompleted,
                lineWidth: 8,
                systemImage: goal.type.systemImage
            )
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(valueText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.Colors.success)
            }
        }
        .padding(Theme.Spacing.md)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .combine)
    }

    private var valueText: String {
        let current = formatted(progress?.currentValue ?? 0)
        let target = formatted(goal.targetValue)
        return "\(current) / \(target) \(goal.unit)"
    }

    private func formatted(_ value: Double) -> String {
        if value >= 100 || value.rounded() == value {
            return value.formatted(.number.precision(.fractionLength(0)))
        }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

#Preview {
    let goal = Goal(title: "Caminar más", type: .steps, targetValue: 10000)
    let progress = GoalProgress(
        goalId: goal.id, currentValue: 6200, targetValue: 10000,
        fraction: 0.62, isCompleted: false,
        periodStart: .now, periodEnd: .now, lastUpdated: .now
    )
    return VStack(spacing: 12) {
        GoalCard(goal: goal, progress: progress)
        GoalCard(goal: Goal(title: "Ejercicio", type: .exerciseMinutes, targetValue: 30),
                 progress: GoalProgress(goalId: UUID(), currentValue: 30, targetValue: 30,
                                        fraction: 1, isCompleted: true,
                                        periodStart: .now, periodEnd: .now, lastUpdated: .now))
    }
    .padding()
}
