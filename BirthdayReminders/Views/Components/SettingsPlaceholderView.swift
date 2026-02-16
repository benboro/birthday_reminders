import SwiftUI
import SwiftData

/// Full settings screen with Contacts and Notifications sections.
///
/// Replaces the former SettingsPlaceholderView stub now that Phase 2
/// delivers notification configuration. Contains the manual re-import
/// button and embeds NotificationSettingsView for delivery time and
/// permission management.
struct SettingsView: View {
    var syncService: ContactSyncService
    var notificationScheduler: NotificationScheduler
    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false
    @State private var lastImportCount: Int?

    var body: some View {
        List {
            Section("Contacts") {
                Button {
                    Task {
                        isImporting = true
                        lastImportCount = nil
                        await syncService.importContacts(into: modelContext)
                        lastImportCount = syncService.importedCount
                        isImporting = false

                        // Reschedule notifications after re-import
                        await rescheduleAfterImport()
                    }
                } label: {
                    HStack {
                        Label("Re-import Contacts", systemImage: "arrow.triangle.2.circlepath")

                        Spacer()

                        if isImporting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isImporting)

                if let count = lastImportCount {
                    Text("Imported \(count) contacts with birthdays")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            NotificationSettingsView(notificationScheduler: notificationScheduler)
        }
        .navigationTitle("Settings")
    }

    // MARK: - Post-Import Rescheduling

    /// Reads delivery time from UserDefaults and reschedules all notifications.
    private func rescheduleAfterImport() async {
        let hour = UserDefaults.standard.object(forKey: "notificationHour") as? Int ?? 9
        let minute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? 0
        let descriptor = FetchDescriptor<Person>()
        guard let people = try? modelContext.fetch(descriptor) else { return }
        await notificationScheduler.reschedule(
            people: people,
            deliveryHour: hour,
            deliveryMinute: minute
        )
    }
}
