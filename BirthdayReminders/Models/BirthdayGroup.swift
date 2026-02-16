import SwiftData

/// Notification preference options for a group.
///
/// Controls whether contacts in this group receive day-of notifications,
/// day-before notifications, or both.
enum NotificationPreference: String, Codable, CaseIterable {
    case dayOfOnly = "Day of only"
    case dayBeforeOnly = "Day before only"
    case both = "Both"
}

/// A group of contacts with a shared notification preference, synced bidirectionally with iOS Contacts.
///
/// Stores the CNGroup.identifier for linkage to the system Contacts store.
/// The notification preference (GRPS-03) controls which notification types
/// are generated for members of this group.
///
/// IMPORTANT: All group names logged with privacy: .private (SECR-04).
@Model
final class BirthdayGroup {

    /// The CNGroup.identifier from iOS Contacts. Used for bidirectional sync.
    @Attribute(.unique)
    var groupIdentifier: String

    /// Display name, synced from/to CNGroup.name.
    var name: String

    /// Per-group notification preference (GRPS-03).
    /// Defaults to .both for backward compatibility with Phase 2 behavior.
    var notificationPreference: NotificationPreference

    /// Many-to-many relationship with Person.
    /// Nullify delete rule preserves Person records when a group is deleted.
    @Relationship(deleteRule: .nullify, inverse: \Person.groups)
    var members: [Person]

    init(
        groupIdentifier: String,
        name: String,
        notificationPreference: NotificationPreference = .both
    ) {
        self.groupIdentifier = groupIdentifier
        self.name = name
        self.notificationPreference = notificationPreference
        self.members = []
    }
}
