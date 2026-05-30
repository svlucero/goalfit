import SwiftUI

/// 4-step welcome flow shown on first launch. Sets `hasCompletedOnboarding`
/// when finished or skipped.
struct OnboardingView: View {
    @Environment(AppContainer.self) private var container
    @AppStorage(OnboardingFlag.key) private var hasCompletedOnboarding = false
    @State private var viewModel: OnboardingViewModel?
    @State private var presentGoalForm = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = OnboardingViewModel(
                    healthService: container.healthService,
                    notifications: container.notifications
                )
            }
        }
        .sheet(isPresented: $presentGoalForm, onDismiss: complete) {
            GoalFormView(
                viewModel: GoalFormViewModel(
                    store: container.store,
                    notifications: container.notifications
                )
            ) {}
        }
    }

    @ViewBuilder
    private func content(_ viewModel: OnboardingViewModel) -> some View {
        VStack {
            // Top bar with skip on the right (except on welcome).
            HStack {
                if viewModel.step != .welcome {
                    Button("Back") { viewModel.goBack() }
                }
                Spacer()
                if !viewModel.isLastStep {
                    Button("Skip", action: complete)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)

            Spacer()

            stepBody(viewModel)
                .padding(.horizontal, Theme.Spacing.xl)
                .animation(.easeInOut(duration: 0.2), value: viewModel.step)

            Spacer()

            pageIndicator(current: viewModel.step.rawValue, total: OnboardingViewModel.Step.allCases.count)
                .padding(.bottom, Theme.Spacing.md)

            primaryButton(for: viewModel)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
    }

    // MARK: - Step body

    @ViewBuilder
    private func stepBody(_ viewModel: OnboardingViewModel) -> some View {
        switch viewModel.step {
        case .welcome:
            stepCard(
                icon: "target",
                title: "Welcome to GoalFit",
                message: "Set simple health goals and watch your progress, powered by your iPhone's Health data."
            )
        case .health:
            stepCard(
                icon: "heart.text.square",
                title: "Connect to Apple Health",
                message: "GoalFit reads steps, distance, calories, exercise minutes and weight to compute your progress. Your data never leaves your device."
            )
        case .notifications:
            stepCard(
                icon: "bell.badge",
                title: "Stay on track",
                message: "Get a gentle daily reminder at the time you choose, and a celebration when you reach a goal."
            )
        case .firstGoal:
            stepCard(
                icon: "checkmark.circle",
                title: "Set your first goal",
                message: "Pick a goal type, set a target, and you're ready to go. You can change it anytime."
            )
        }
    }

    private func stepCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Footer

    private func pageIndicator(current: Int, total: Int) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Theme.Colors.accent : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }

    @ViewBuilder
    private func primaryButton(for viewModel: OnboardingViewModel) -> some View {
        switch viewModel.step {
        case .welcome:
            primary(title: "Get started") { viewModel.advance() }
        case .health:
            primary(title: "Allow Health access") {
                Task { await viewModel.requestHealthAndAdvance() }
            }
        case .notifications:
            primary(title: "Allow notifications") {
                Task { await viewModel.requestNotificationsAndAdvance() }
            }
        case .firstGoal:
            VStack(spacing: Theme.Spacing.sm) {
                primary(title: "Create my first goal") { presentGoalForm = true }
                Button("Maybe later", action: complete)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func primary(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.Colors.accent)
    }

    private func complete() {
        hasCompletedOnboarding = true
    }
}

/// Centralises the flag key so app + tests stay in sync.
enum OnboardingFlag {
    static let key = "hasCompletedOnboarding"
}

#Preview {
    let container = AppContainer(
        store: InMemoryGoalStore(),
        healthService: MockHealthService(),
        progressProvider: MockProgressProvider(),
        notifications: MockNotificationService(),
        notificationCoordinator: NotificationCoordinator()
    )
    return OnboardingView()
        .environment(container)
}
