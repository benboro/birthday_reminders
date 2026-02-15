import SwiftUI

/// Settings screen accessible via the gear icon in the navigation bar.
///
/// Currently a stub containing only the manual re-import button.
/// Phase 2 will add notification settings here.
struct SettingsPlaceholderView: View {
    var syncService: ContactSyncService
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
        }
        .navigationTitle("Settings")
    }
}
