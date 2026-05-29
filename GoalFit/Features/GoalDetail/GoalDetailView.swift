import SwiftUI
import Charts

/// Goal detail: large progress ring, value vs target, and a history chart.
struct GoalDetailView: View {
    @State var viewModel: GoalDetailViewModel
    /// Called when the user taps Edit.
    var onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                progressHeader
                statsRow
                chartSection
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(viewModel.goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: onEdit)
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var progressHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressRing(
                fraction: viewModel.progress?.fraction ?? 0,
                isCompleted: viewModel.progress?.isCompleted ?? false,
                lineWidth: 14,
                systemImage: viewModel.goal.type.systemImage
            )
            .frame(width: 140, height: 140)

            Text(valueText)
                .font(.title3.weight(.semibold))
                .monospacedDigit()

            Text(viewModel.goal.type.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.md)
    }

    private var statsRow: some View {
        HStack {
            stat("Average", value: viewModel.averageValue)
            Divider()
            stat(viewModel.isCumulative ? "Best day" : "Peak", value: viewModel.bestValue)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func stat(_ title: String, value: Double?) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.map { format($0) } ?? "—")
                .font(.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Last 7 days").font(.headline)

            if viewModel.series.isEmpty {
                Text("No data for this period yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(viewModel.series) { point in
                    if viewModel.isCumulative {
                        BarMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Theme.Colors.accent)
                    } else {
                        LineMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Theme.Colors.accent)
                        PointMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var valueText: String {
        let current = format(viewModel.progress?.currentValue ?? 0)
        let target = format(viewModel.goal.targetValue)
        return "\(current) / \(target) \(viewModel.goal.unit)"
    }

    private func format(_ value: Double) -> String {
        if value >= 100 || value.rounded() == value {
            return value.formatted(.number.precision(.fractionLength(0)))
        }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(
            viewModel: GoalDetailViewModel(
                goal: Goal(title: "Walk 10,000 steps", type: .steps, targetValue: 10000),
                health: MockHealthService()
            )
        ) {}
    }
}
