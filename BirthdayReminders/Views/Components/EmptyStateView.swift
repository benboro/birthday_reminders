import SwiftUI

/// Empty state shown when no contacts have been imported yet.
///
/// Displays a friendly message with guidance and an optional re-import button.
/// System styling, works in both light and dark mode.
struct EmptyStateView: View {
    var syncService: ContactSyncService
    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false

    var body: some View {
        ContentUnavailableView {
            Label("No Birthdays Yet", systemImage: "gift")
        } description: {
            Text("Import your contacts to see upcoming birthdays.")
        } actions: {
            Button {
                Task {
                    isImporting = true
                    await syncService.importContacts(into: modelContext)
                    isImporting = false
                }
            } label: {
                if isImporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Import Contacts")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
        }
    }
}
