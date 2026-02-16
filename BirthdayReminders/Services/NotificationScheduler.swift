@preconcurrency import UserNotifications
import SwiftData
import os

/// Actor-isolated notification scheduler that manages the iOS 64-notification ceiling.
///
/// Sorts contacts by nearest birthday, generates day-of and day-before notification
/// requests, and caps the total at 64 (iOS hard limit). Uses deterministic request
/// identifiers so rescheduling naturally replaces previous notifications.
actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission Management

    /// Returns the current notification authorization status.
    func checkStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// Requests notification permission from the user.
    ///
    /// Returns `true` if granted, `false` otherwise. If the status is already `.denied`,
    /// returns `false` without calling `requestAuthorization` (the system dialog will
    /// not appear again once denied).
    func requestPermission() async -> Bool {
        let status = await checkStatus()

        if status == .denied {
            Logger.notifications.info("Notification permission previously denied, skipping request")
            return false
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            Logger.notifications.info("Notification permission request result: \(granted)")
            return granted
        } catch {
            Logger.notifications.error("Notification permission request failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Scheduling

    /// Reschedules all birthday notifications, sorted by proximity.
    ///
    /// Removes all pending notifications, then schedules up to 64 new ones
    /// (day-of and day-before for the nearest birthdays). Contacts are sorted
    /// by `daysUntilBirthday` ascending so the nearest birthdays get priority.
    ///
    /// - Parameters:
    ///   - people: All Person records to consider for scheduling.
    ///   - deliveryHour: Hour (0-23) to deliver notifications. Defaults to 9.
    ///   - deliveryMinute: Minute (0-59) to deliver notifications. Defaults to 0.
    func reschedule(people: [Person], deliveryHour: Int = 9, deliveryMinute: Int = 0) async {
        // 1. Clear all existing notifications
        center.removeAllPendingNotificationRequests()

        // 2. Check authorization
        let status = await checkStatus()
        guard status == .authorized || status == .provisional else {
            Logger.notifications.info("Notifications not authorized (status: \(String(describing: status))), skipping reschedule")
            return
        }

        // 3. Sort by nearest birthday
        let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }

        // 4. Generate requests, capped at 64, filtered by per-group notification preference
        var requests: [UNNotificationRequest] = []
        for person in sorted {
            if requests.count >= 64 { break }

            let preference = effectivePreference(for: person)

            // Day-before notification (check first since it fires earlier)
            if preference == .dayBeforeOnly || preference == .both {
                if let dayBefore = makeRequest(person: person, offsetDays: -1, hour: deliveryHour, minute: deliveryMinute) {
                    requests.append(dayBefore)
                }
            }

            if requests.count >= 64 { break }

            // Day-of notification
            if preference == .dayOfOnly || preference == .both {
                if let dayOf = makeRequest(person: person, offsetDays: 0, hour: deliveryHour, minute: deliveryMinute) {
                    requests.append(dayOf)
                }
            }
        }

        // 5. Schedule all requests
        for request in requests {
            do {
                try await center.add(request)
            } catch {
                Logger.notifications.error("Failed to schedule notification \(request.identifier): \(error.localizedDescription)")
            }
        }

        Logger.notifications.info("Scheduled \(requests.count) notifications for \(people.count) contacts")
    }

    // MARK: - Group Preferences

    /// Determines the effective notification preference for a person
    /// based on their group memberships.
    ///
    /// Resolution rules:
    /// - Ungrouped contacts default to .both (backward compatible with Phase 2).
    /// - If any group has .both, returns .both.
    /// - If groups contain both .dayOfOnly and .dayBeforeOnly, returns .both (most permissive).
    /// - Otherwise returns whichever single preference exists.
    func effectivePreference(for person: Person) -> NotificationPreference {
        let groups = person.groups
        if groups.isEmpty { return .both }

        // Most permissive wins: if any group says .both, use .both
        if groups.contains(where: { $0.notificationPreference == .both }) {
            return .both
        }

        // If both dayOfOnly and dayBeforeOnly exist across groups, that means .both
        let hasDayOf = groups.contains(where: { $0.notificationPreference == .dayOfOnly })
        let hasDayBefore = groups.contains(where: { $0.notificationPreference == .dayBeforeOnly })
        if hasDayOf && hasDayBefore { return .both }

        // Otherwise, return whichever is set
        if hasDayBefore { return .dayBeforeOnly }
        return .dayOfOnly
    }

    // MARK: - Private Helpers

    /// Creates a notification request for a person's birthday with an optional day offset.
    ///
    /// Returns `nil` if the computed target date is in the past (notification would never fire).
    ///
    /// - Parameters:
    ///   - person: The person whose birthday to schedule for.
    ///   - offsetDays: 0 for day-of, -1 for day-before.
    ///   - hour: Delivery hour (0-23).
    ///   - minute: Delivery minute (0-59).
    /// - Returns: A configured notification request, or nil if the target is in the past.
    private func makeRequest(person: Person, offsetDays: Int, hour: Int, minute: Int) -> UNNotificationRequest? {
        let calendar = Calendar.current
        let now = Date.now
        let startOfToday = calendar.startOfDay(for: now)

        // Compute target date from next birthday
        let birthdayDate = BirthdayCalculator.nextBirthday(month: person.birthdayMonth, day: person.birthdayDay)
        guard let targetDate = calendar.date(byAdding: .day, value: offsetDays, to: birthdayDate) else {
            return nil
        }

        // Skip if target date is in the past
        if targetDate < startOfToday {
            return nil
        }

        // For day-of: if the birthday is today and the delivery time has passed, skip
        if offsetDays == 0 && calendar.isDateInToday(targetDate) {
            var deliveryComponents = calendar.dateComponents([.year, .month, .day], from: now)
            deliveryComponents.hour = hour
            deliveryComponents.minute = minute
            if let deliveryTime = calendar.date(from: deliveryComponents), now >= deliveryTime {
                return nil
            }
        }

        // For day-before: if the target is today and the delivery time has passed, skip
        if offsetDays == -1 && calendar.isDateInToday(targetDate) {
            var deliveryComponents = calendar.dateComponents([.year, .month, .day], from: now)
            deliveryComponents.hour = hour
            deliveryComponents.minute = minute
            if let deliveryTime = calendar.date(from: deliveryComponents), now >= deliveryTime {
                return nil
            }
        }

        // Build notification content
        let content = UNMutableNotificationContent()
        if offsetDays == 0 {
            content.title = "\(person.displayName)'s Birthday!"
            content.body = "Today is \(person.displayName)'s birthday!"
        } else {
            content.title = "Birthday Tomorrow"
            content.body = "\(person.displayName)'s birthday is tomorrow!"
        }
        content.sound = .default
        content.userInfo = ["contactIdentifier": person.contactIdentifier]

        // Build calendar trigger with explicit year, month, day, hour, minute
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Deterministic identifier
        let suffix = offsetDays == 0 ? "dayof" : "daybefore"
        let identifier = "\(person.contactIdentifier)-birthday-\(suffix)"

        Logger.notifications.debug("Scheduling \(suffix) for \(person.displayName, privacy: .private) on \(dateComponents.month ?? 0)/\(dateComponents.day ?? 0)")

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
