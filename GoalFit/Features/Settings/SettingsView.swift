import SwiftUI
import UIKit

/// Settings: permission overview, global notifications switch, about info.
struct SettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel?
    /// Global notifications switch. Off means we cancel every reminder.
    @AppStorage(SettingsKeys.notificationsEnabled) private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SettingsViewModel(
                    store: container.store,
                    healthService: container.healthService,
                    notifications: container.notifications
                )
            }
            await viewModel?.refresh()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: SettingsViewModel) -> some View {
        Form {
            permissionsSection(viewModel)
            remindersSection(viewModel)
            aboutSection
        }
    }

    // MARK: - Sections

    private func permissionsSection(_ viewModel: SettingsViewModel) -> some View {
        Section("Permissions") {
            permissionRow(
                icon: "heart.text.square",
                title: "Apple Health",
                detail: viewModel.isHealthDataAvailable ? "Available" : "Not available on this device"
            )
            permissionRow(
                icon: "bell.badge",
                title: "Notifications",
                detail: viewModel.notificationStatusText
            )
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Open system settings", destination: url)
            }
        }
    }

    private func remindersSection(_ viewModel: SettingsViewModel) -> some View {
        Section {
            Toggle("Enable notifications", isOn: Binding(
                get: { notificationsEnabled },
                set: { newValue in
                    notificationsEnabled = newValue
                    Task { await viewModel.applyGlobalNotificationsToggle(newValue) }
                }
            ))
        } header: {
            Text("Reminders")
        } footer: {
            Text("Turning this off cancels every reminder. Per-goal reminder settings are remembered.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersionText).foregroundStyle(.secondary).monospacedDigit()
            }
            Label(
                "Health data stays on your device.",
                systemImage: "lock.shield"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Building blocks

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(detail).foregroundStyle(.secondary)
        }
    }

    private var appVersionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

enum SettingsKeys {
    static let notificationsEnabled = "settings.notificationsEnabled"
}

#Preview {
    let container = AppContainer(
        store: InMemoryGoalStore.previewPopulated(),
        healthService: MockHealthService(),
        progressProvider: MockProgressProvider(),
        notifications: MockNotificationService(),
        notificationCoordinator: NotificationCoordinator()
    )
    return SettingsView()
        .environment(container)
}
