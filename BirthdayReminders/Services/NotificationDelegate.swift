@preconcurrency import UserNotifications
import os

/// Handles notification presentation when the app is in the foreground and
/// notification tap actions.
///
/// Assigned as the delegate on `UNUserNotificationCenter.current()` at app launch.
/// Uses `nonisolated` methods for Swift 6 strict concurrency compatibility.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {

    /// Display notifications as banners with sound when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        Logger.notifications.info("Presenting notification in foreground: \(notification.request.identifier)")
        return [.banner, .sound, .list]
    }

    /// Handle notification tap. Extracts contactIdentifier for future navigation.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let contactId = userInfo["contactIdentifier"] as? String {
            Logger.notifications.info("Notification tapped for contact: \(contactId, privacy: .private)")
        } else {
            Logger.notifications.info("Notification tapped without contact identifier")
        }
        // Navigation to birthday detail will be wired in a future phase.
    }
}
