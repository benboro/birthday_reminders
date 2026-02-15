import os

extension Logger {
    /// General app lifecycle logging.
    static let app = Logger(subsystem: "com.birthdayreminders", category: "app")

    /// Contact sync and import operations.
    /// All contact data MUST use privacy: .private per SECR-04.
    static let sync = Logger(subsystem: "com.birthdayreminders", category: "sync")
}
