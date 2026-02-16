import os

extension Logger {
    /// General app lifecycle logging.
    static let app = Logger(subsystem: "com.birthdayreminders", category: "app")

    /// Contact sync and import operations.
    /// All contact data MUST use privacy: .private per SECR-04.
    static let sync = Logger(subsystem: "com.birthdayreminders", category: "sync")

    /// Notification scheduling and permission operations.
    /// All person names MUST use privacy: .private per SECR-04.
    static let notifications = Logger(subsystem: "com.birthdayreminders", category: "notifications")

    /// Group management and sync operations.
    /// All group names MUST use privacy: .private per SECR-04.
    static let groups = Logger(subsystem: "com.birthdayreminders", category: "groups")
}
