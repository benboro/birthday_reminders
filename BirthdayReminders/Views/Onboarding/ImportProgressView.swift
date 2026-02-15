import SwiftUI
import SwiftData

/// Import progress screen with indeterminate spinner and live count.
///
/// Triggers the contact import on appear and advances to the next step
/// when the import completes. Shows an indeterminate ProgressView since
/// the import typically takes less than 3 seconds.
struct ImportProgressView: View {
    /// The sync service performing the import.
    var syncService: ContactSyncService

    /// Callback when the import finishes successfully.
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            Text("Importing contacts...")
                .font(.title3)
                .fontWeight(.medium)

            if syncService.importedCount > 0 {
                Text("Found \(syncService.importedCount) birthdays...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .task {
            await syncService.importContacts(into: modelContext)
            onComplete()
        }
    }
}
