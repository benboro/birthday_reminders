import Contacts
import Observation
import SwiftData
import os

// MARK: - Authorization State

/// Maps all five CNAuthorizationStatus cases including iOS 18's .limited.
enum ContactAuthState: Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}

// MARK: - ContactSyncService

/// Wraps CNContactStore with full authorization handling and async contact import.
///
/// Handles all five CNAuthorizationStatus values including iOS 18 `.limited`.
/// Import runs enumeration off the main thread via Task.detached, then upserts
/// into SwiftData on the main actor through ContactBridge.
///
/// IMPORTANT: No URLSession or Network imports (SECR-01).
/// IMPORTANT: All contact data logged with privacy: .private (SECR-04).
@Observable
@MainActor
final class ContactSyncService {

    // MARK: - Published State

    /// Current contact authorization state.
    private(set) var authState: ContactAuthState = .notDetermined

    /// Whether a contact import is currently in progress.
    private(set) var isImporting: Bool = false

    /// Number of contacts with birthdays found during the current import.
    private(set) var importedCount: Int = 0

    /// Most recent error from authorization or import operations.
    private(set) var error: Error? = nil

    // MARK: - Callbacks

    /// Optional callback invoked after a successful import with the number of contacts imported.
    /// Allows the app root to wire up notification rescheduling after any import source.
    var onImportComplete: ((_ importedCount: Int) async -> Void)?

    // MARK: - Dependencies

    /// Optional group sync service. When set, group sync runs automatically after contact import.
    var groupSyncService: GroupSyncService?

    // MARK: - Private

    /// Single CNContactStore instance for all operations.
    private let store = CNContactStore()

    // MARK: - Authorization

    /// Read current authorization status and map to ContactAuthState.
    ///
    /// Call on service init and whenever the app returns to foreground
    /// (e.g., after the user changes permission in Settings).
    func checkAuthorizationStatus() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            authState = .notDetermined
        case .authorized:
            authState = .authorized
        case .limited:
            authState = .limited
        case .denied:
            authState = .denied
        case .restricted:
            authState = .restricted
        @unknown default:
            authState = .denied
        }
    }

    /// Request contact access from the user.
    ///
    /// Presents the system permission dialog if status is .notDetermined.
    /// Updates authState afterward regardless of outcome.
    /// - Returns: true if access was granted (.authorized or .limited).
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            checkAuthorizationStatus()
            return granted
        } catch {
            self.error = error
            Logger.sync.error("Contact access request failed: \(error.localizedDescription)")
            checkAuthorizationStatus()
            return false
        }
    }

    // MARK: - Import

    /// Import all contacts with birthdays into SwiftData.
    ///
    /// Runs CNContactStore.enumerateContacts in a detached task to avoid
    /// blocking the main thread. Filters to only contacts with a birthday
    /// (Gregorian or non-Gregorian). Upserts via ContactBridge and removes
    /// stale contacts no longer present in the Contacts store.
    ///
    /// - Parameter context: The SwiftData ModelContext to import into.
    func importContacts(into context: ModelContext) async {
        isImporting = true
        importedCount = 0
        defer { isImporting = false }

        do {
            let keys: [CNKeyDescriptor] = ContactBridge.keysToFetch()
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .givenName

            // Run enumeration off the main thread -- enumerateContacts is synchronous
            let contacts: [CNContact] = try await Task.detached { [store] in
                var result: [CNContact] = []
                try store.enumerateContacts(with: request) { contact, _ in
                    // Filter: only contacts with a birthday
                    if contact.birthday != nil || contact.nonGregorianBirthday != nil {
                        result.append(contact)
                    }
                }
                return result
            }.value

            // Upsert into SwiftData on the main actor
            var importedIdentifiers = Set<String>()
            for cnContact in contacts {
                ContactBridge.upsert(from: cnContact, into: context)
                importedIdentifiers.insert(cnContact.identifier)
                importedCount += 1
            }

            // Remove contacts no longer in the Contacts store
            ContactBridge.removeStale(
                knownIdentifiers: importedIdentifiers,
                context: context
            )

            try? context.save()

            // Sync groups from iOS Contacts if service is available
            if let groupSyncService {
                do {
                    try groupSyncService.syncGroupsFromContacts(context: context)
                    Logger.sync.info("Group sync completed after contact import")
                } catch {
                    Logger.sync.error("Group sync failed after contact import: \(error.localizedDescription)")
                }
            }

            // Log count only -- names are PII (SECR-04)
            Logger.sync.info("Import complete: \(self.importedCount) contacts with birthdays")

            // Notify listeners (e.g., notification rescheduling)
            await onImportComplete?(importedCount)

        } catch {
            self.error = error
            Logger.sync.error("Contact import failed: \(error.localizedDescription)")
        }
    }
}
