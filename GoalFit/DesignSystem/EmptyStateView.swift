import SwiftUI

/// Reusable empty state with icon, title, message and optional action.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "target",
        title: "No goals yet",
        message: "Create your first goal to start tracking your progress.",
        actionTitle: "Create goal",
        action: {}
    )
}
