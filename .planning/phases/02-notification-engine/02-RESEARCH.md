# Phase 2: Notification Engine - Research

**Researched:** 2026-02-15
**Domain:** iOS Local Notifications with UNUserNotificationCenter, priority-based scheduling under the 64-notification ceiling
**Confidence:** HIGH

## Summary

This phase adds the core value proposition of the app: timely birthday notifications. iOS imposes a hard limit of 64 locally scheduled notifications per app at any time. The system keeps the soonest-firing 64 and silently discards the rest. Since each contact generates two notifications (day-of and day-before), the app can only cover 32 contacts in a single scheduling pass. For users with more than 32 birthday contacts, a priority-based scheduler must sort all upcoming birthdays by proximity, schedule the top 64, and backfill freed slots whenever the app returns to the foreground.

The entire notification stack is built on Apple's UserNotifications framework (`UNUserNotificationCenter`, `UNCalendarNotificationTrigger`, `UNMutableNotificationContent`). No third-party dependencies are needed. The user's preferred delivery time is stored as hour+minute integers in `@AppStorage`/UserDefaults and used as the hour/minute in every `DateComponents` trigger. A pre-permission primer screen (custom SwiftUI view) is shown before the system alert to maximize opt-in rates.

The project uses Swift 6.0 strict concurrency, which introduces specific challenges with `UNUserNotificationCenterDelegate`. The delegate methods must use `@preconcurrency import UserNotifications` and `nonisolated` annotations. A serial scheduling queue (Swift actor) prevents race conditions when concurrent reschedule calls occur.

**Primary recommendation:** Build a `NotificationScheduler` actor that owns all interactions with `UNUserNotificationCenter`, implements priority-based scheduling with the 64-notification ceiling, and is triggered on app foreground and after any data change.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | iOS 18.0+ | Schedule and manage local notifications | Apple's only API for local notifications |
| SwiftUI DatePicker | iOS 18.0+ | Time-of-day picker for delivery time setting | `.hourAndMinute` displayedComponents |
| @AppStorage | iOS 18.0+ | Persist notification hour/minute preference | Lightweight, reactive, built into SwiftUI |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| os.Logger | iOS 18.0+ | Structured logging for notification operations | All scheduling, permission, and error events |
| SwiftData | iOS 18.0+ | Query Person records for scheduling | Already in use from Phase 1 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @AppStorage for time | SwiftData model for settings | Overkill for two integers; @AppStorage is simpler and reactive |
| UNCalendarNotificationTrigger | UNTimeIntervalNotificationTrigger | Calendar trigger matches exact dates; interval trigger requires computing seconds |
| Actor for scheduler | GCD serial queue | Actor is Swift-native, integrates with async/await, and is the modern pattern |

**Installation:** No additional dependencies. UserNotifications is a system framework.

## Architecture Patterns

### Recommended Project Structure
```
BirthdayReminders/
├── Services/
│   ├── NotificationScheduler.swift    # Actor: scheduling logic, 64-limit management
│   └── NotificationPermission.swift   # Permission checking and requesting
├── Views/
│   ├── Onboarding/
│   │   └── NotificationPermissionView.swift  # Pre-permission primer screen
│   └── Settings/
│       └── NotificationSettingsView.swift     # Delivery time picker (replaces placeholder)
├── Extensions/
│   └── Logger+App.swift               # Add .notifications category
└── App/
    └── BirthdayRemindersApp.swift      # Wire up scenePhase observer + delegate
```

### Pattern 1: Priority-Based Notification Scheduler (Actor)
**What:** A Swift actor that serializes all notification scheduling operations, preventing race conditions from concurrent reschedule calls. It queries SwiftData for all Person records, sorts by `daysUntilBirthday`, generates up to 64 notification requests (day-before + day-of for the nearest birthdays), and submits them to `UNUserNotificationCenter`.
**When to use:** Every time notifications need to be refreshed -- app foreground, after contact import, after settings change.
**Example:**
```swift
// Source: Todoist pattern (https://www.doist.dev/implementing-a-local-notification-scheduler-in-todoist-ios/)
// + Apple UNUserNotificationCenter docs
actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    func reschedule(people: [Person], deliveryHour: Int, deliveryMinute: Int) async {
        // 1. Remove all existing scheduled notifications
        center.removeAllPendingNotificationRequests()

        // 2. Sort by nearest birthday first
        let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }

        // 3. Generate requests, capped at 64
        var requests: [UNNotificationRequest] = []
        for person in sorted {
            if requests.count >= 64 { break }

            // Day-of notification
            let dayOf = makeRequest(
                person: person,
                offsetDays: 0,
                hour: deliveryHour,
                minute: deliveryMinute
            )
            requests.append(dayOf)

            if requests.count >= 64 { break }

            // Day-before notification
            let dayBefore = makeRequest(
                person: person,
                offsetDays: -1,
                hour: deliveryHour,
                minute: deliveryMinute
            )
            requests.append(dayBefore)
        }

        // 4. Schedule all
        for request in requests {
            do {
                try await center.add(request)
            } catch {
                Logger.notifications.error("Failed to schedule: \(error.localizedDescription)")
            }
        }
    }
}
```

### Pattern 2: Deterministic Notification Identifiers
**What:** Use predictable identifiers based on contactIdentifier + notification type so that rescheduling naturally replaces previous notifications without duplicates.
**When to use:** Always, for every notification request.
**Example:**
```swift
// Deterministic ID = contactIdentifier + type suffix
let dayOfId = "\(person.contactIdentifier)-birthday-dayof"
let dayBeforeId = "\(person.contactIdentifier)-birthday-daybefore"

let request = UNNotificationRequest(
    identifier: dayOfId,
    content: content,
    trigger: trigger
)
// If a notification with this ID already exists, it is replaced (not duplicated)
```

### Pattern 3: ScenePhase-Triggered Rescheduling
**What:** Observe `scenePhase` changes in the app root and trigger rescheduling when the app enters the foreground. This is the primary backfill mechanism -- as notifications fire and free up slots, the next foreground entry reschedules the full set.
**When to use:** In `BirthdayRemindersApp.swift`.
**Example:**
```swift
@main
struct BirthdayRemindersApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // ...
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await notificationScheduler.reschedule(/* ... */)
                }
            }
        }
    }
}
```

### Pattern 4: Pre-Permission Primer Screen
**What:** A custom SwiftUI view shown before the system notification permission alert. Explains why notifications are valuable, giving the user context. Only triggers the system alert when the user taps "Enable Notifications". If user declines, skip gracefully.
**When to use:** First launch after onboarding, or when notification permission is `.notDetermined`.
**Example:**
```swift
struct NotificationPermissionView: View {
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Never Miss a Birthday")
                .font(.title2.bold())

            Text("Get notified the day before and the day of each birthday so you always have time to prepare.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Enable Notifications") { onEnable() }
                .buttonStyle(.borderedProminent)

            Button("Maybe Later") { onSkip() }
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

### Pattern 5: UNCalendarNotificationTrigger with DateComponents
**What:** Create calendar-based triggers using DateComponents to fire at a specific month, day, hour, and minute. Set `repeats: false` for birthday notifications since they are rescheduled each time.
**When to use:** For every individual birthday notification.
**Example:**
```swift
// Source: https://www.createwithswift.com/notifications-tutorial-creating-and-scheduling-user-notifications-with-async-await/
func makeRequest(person: Person, offsetDays: Int, hour: Int, minute: Int) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = offsetDays == 0
        ? "\(person.displayName)'s Birthday!"
        : "Birthday Tomorrow"
    content.body = offsetDays == 0
        ? "Today is \(person.displayName)'s birthday!"
        : "\(person.displayName)'s birthday is tomorrow!"
    content.sound = .default

    // Compute the target date
    let calendar = Calendar.current
    let birthdayDate = BirthdayCalculator.nextBirthday(month: person.birthdayMonth, day: person.birthdayDay)
    guard let targetDate = calendar.date(byAdding: .day, value: offsetDays, to: birthdayDate) else {
        // Fallback: use birthday date directly
        var dc = calendar.dateComponents([.month, .day], from: birthdayDate)
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let id = "\(person.contactIdentifier)-birthday-\(offsetDays == 0 ? "dayof" : "daybefore")"
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
    dateComponents.hour = hour
    dateComponents.minute = minute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let id = "\(person.contactIdentifier)-birthday-\(offsetDays == 0 ? "dayof" : "daybefore")"
    return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
}
```

### Anti-Patterns to Avoid
- **Using repeating triggers for birthdays:** Repeating calendar triggers with month+day only fire once per year at most, but they permanently consume a notification slot. Use non-repeating triggers with explicit year+month+day and reschedule yearly.
- **Using random UUIDs for notification identifiers:** Random IDs make it impossible to update or deduplicate notifications. Use deterministic IDs based on contactIdentifier + type.
- **Scheduling notifications without clearing first:** Always call `removeAllPendingNotificationRequests()` before a full reschedule pass. Without this, stale notifications accumulate and consume slots.
- **Requesting system permission on first launch without context:** Users deny permissions they don't understand. Always show a primer screen first.
- **Scheduling in a non-serialized way:** Multiple concurrent reschedule calls create race conditions. Use an actor to serialize.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local notification scheduling | Custom timer/background task system | UNUserNotificationCenter + UNCalendarNotificationTrigger | Apple's system handles device sleep, reboots, timezone changes |
| Notification permission flow | Custom permission state tracking | UNUserNotificationCenter.notificationSettings() | System tracks the actual state; your copy will drift |
| Serial async queue | Custom lock/semaphore | Swift actor | Language-level guarantee of serial execution with async/await |
| Time picker UI | Custom hour/minute wheel | SwiftUI DatePicker with `.hourAndMinute` | Handles localization (12h/24h), accessibility, VoiceOver |
| Date math for triggers | Manual month/day arithmetic | Calendar.dateComponents + BirthdayCalculator | Edge cases: DST, leap years, month boundaries |

**Key insight:** The UserNotifications framework handles all system-level complexity (device sleep, reboot persistence, timezone changes). The only custom logic needed is the priority sorting and 64-notification ceiling management.

## Common Pitfalls

### Pitfall 1: Ignoring the 64-Notification Hard Limit
**What goes wrong:** App schedules more than 64 notifications. iOS silently discards all beyond 64 (keeping the 64 soonest). Users with many contacts miss birthday notifications for contacts further out.
**Why it happens:** Developers test with small datasets (< 32 contacts) and never hit the limit.
**How to avoid:** Always sort by proximity, cap at 64 total, and reschedule on every foreground entry to backfill as notifications fire.
**Warning signs:** Users reporting missed notifications for contacts whose birthdays are more than a month away.

### Pitfall 2: Missing Timezone in DateComponents
**What goes wrong:** Notifications fire at the wrong time because DateComponents defaults to GMT/UTC when no timezone is set on the calendar.
**Why it happens:** Donnywals.com documents this: "if you didn't specify a timezone for the calendar...it defaults to GMT."
**How to avoid:** Use `Calendar.current` for all DateComponents extraction (which includes the user's timezone). Alternatively, explicitly set `dateComponents.timeZone = .current`.
**Warning signs:** Notifications firing at unexpected hours, especially for users in timezones far from UTC.

### Pitfall 3: Swift 6 Strict Concurrency with UNUserNotificationCenterDelegate
**What goes wrong:** Compile errors or crashes when implementing `UNUserNotificationCenterDelegate` methods with Swift 6's strict concurrency checking.
**Why it happens:** The UserNotifications framework predates Swift concurrency and its delegate methods are not annotated for modern concurrency.
**How to avoid:** Use `@preconcurrency import UserNotifications`. Mark delegate methods as `nonisolated`. Use `Task { @MainActor in ... }` for any MainActor-isolated work inside delegate callbacks.
**Warning signs:** Compiler warnings about "main actor-isolated instance method cannot satisfy nonisolated requirement."

### Pitfall 4: Day-Before Notification for January 1 Birthdays
**What goes wrong:** The day-before notification for a Jan 1 birthday falls on Dec 31 of the previous year. If rescheduling happens in early January, the day-before date is in the past and the notification is silently dropped.
**Why it happens:** Date arithmetic across year boundaries.
**How to avoid:** After computing the target date, check if it is in the past. If so, skip that notification (it already would have fired or is irrelevant).
**Warning signs:** Missing day-before notifications for birthdays in early January.

### Pitfall 5: Not Rescheduling After Contact Import
**What goes wrong:** User imports new contacts with upcoming birthdays, but no notifications are scheduled for them until the next app foreground cycle.
**Why it happens:** Scheduling only triggers on scenePhase change, not on data changes.
**How to avoid:** Also trigger rescheduling after contact import completes and after any settings change (delivery time).
**Warning signs:** Newly imported contacts' birthdays are missed on the first day.

### Pitfall 6: Requesting Permission When Already Denied
**What goes wrong:** Calling `requestAuthorization` when status is `.denied` does nothing (the system dialog does not appear again). The user sees no response to tapping "Enable".
**Why it happens:** iOS only shows the system permission dialog once (when status is `.notDetermined`).
**How to avoid:** Check `notificationSettings().authorizationStatus` before requesting. If `.denied`, show a message directing the user to Settings > App > Notifications.
**Warning signs:** "Enable Notifications" button appears to do nothing for users who previously denied.

## Code Examples

Verified patterns from official sources and community best practices:

### Requesting Notification Permission (async/await)
```swift
// Source: https://www.createwithswift.com/notifications-tutorial-requesting-user-authorization-for-notifications-with-async-await/
import UserNotifications

func requestNotificationPermission() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    } catch {
        Logger.notifications.error("Permission request failed: \(error.localizedDescription)")
        return false
    }
}
```

### Checking Current Authorization Status
```swift
// Source: https://www.createwithswift.com/notifications-tutorial-requesting-user-authorization-for-notifications-with-async-await/
func checkNotificationStatus() async -> UNAuthorizationStatus {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    return settings.authorizationStatus
    // .notDetermined -> can request
    // .authorized -> good to go
    // .denied -> direct to Settings
    // .provisional -> quietly delivered
    // .ephemeral -> App Clips only
}
```

### Foreground Notification Display (Swift 6 Compatible)
```swift
@preconcurrency import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Handle notification tap -- could navigate to birthday detail
        let userInfo = response.notification.request.content.userInfo
        // Extract contactIdentifier from userInfo if stored
    }
}
```

### DatePicker for Notification Delivery Time
```swift
// Source: https://www.hackingwithswift.com/books/ios-swiftui/selecting-dates-and-times-with-datepicker
struct NotificationTimePickerView: View {
    @AppStorage("notificationHour") private var notificationHour: Int = 9
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0

    // Bridge to Date for DatePicker binding
    private var deliveryTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = notificationHour
                components.minute = notificationMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                notificationHour = components.hour ?? 9
                notificationMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        DatePicker(
            "Notification Time",
            selection: deliveryTime,
            displayedComponents: .hourAndMinute
        )
    }
}
```

### Logger Extension for Notifications
```swift
extension Logger {
    /// Notification scheduling and permission operations.
    static let notifications = Logger(subsystem: "com.birthdayreminders", category: "notifications")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UILocalNotification | UNUserNotificationCenter | iOS 10 (2016) | UILocalNotification fully deprecated |
| Completion handler-based delegate | Async/await delegate methods | iOS 15 / Swift 5.5 | Cleaner code, required for Swift 6 |
| `.alert` presentation option | `.banner` + `.list` presentation options | iOS 14 | `.alert` deprecated; use `.banner` and `.list` |
| No concurrency annotations | `@preconcurrency import` + `nonisolated` | Swift 6.0 | Required for strict concurrency checking |

**Deprecated/outdated:**
- `UILocalNotification`: Fully deprecated since iOS 10. Use `UNNotificationRequest` with `UNUserNotificationCenter`.
- `.alert` in `UNNotificationPresentationOptions`: Deprecated. Use `.banner` and `.list` instead.
- Completion handler versions of `requestAuthorization` and delegate methods: Still work but cause crashes in Swift 6 strict concurrency mode. Use async/await versions.

## Open Questions

1. **Per-group notification preferences (Phase 3 interaction)**
   - What we know: Phase 3 will add per-group notification preferences (same day, day before, or both). The scheduler must be designed to accept per-person notification type preferences.
   - What's unclear: The exact data model for per-group preferences.
   - Recommendation: Design the scheduler to accept a notification type parameter per person (dayOf, dayBefore, both) so Phase 3 can plug in without refactoring. Default to "both" for Phase 2.

2. **Notification tap navigation**
   - What we know: `userNotificationCenter(_:didReceive:)` receives the notification response when the user taps.
   - What's unclear: Whether Phase 2 should implement deep linking to the birthday detail view, or defer to a later phase.
   - Recommendation: Store `contactIdentifier` in the notification's `userInfo` dictionary now. Implement basic navigation if straightforward; defer complex deep linking if not.

3. **Whether NSUserNotificationsUsageDescription is required in Info.plist**
   - What we know: This key was introduced in iOS 15.4 and provides a custom message in the permission dialog. It is not strictly required -- a default message is used if absent.
   - What's unclear: Whether iOS 18 has changed this requirement.
   - Recommendation: Add the key to Info.plist with a descriptive message. It is a best practice regardless of whether it is mandatory.

## Sources

### Primary (HIGH confidence)
- UNUserNotificationCenter API -- Apple Developer Documentation (https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
- UNCalendarNotificationTrigger -- Apple Developer Documentation (https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger)
- UNMutableNotificationContent -- Apple Developer Documentation (https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent)
- UNNotificationPresentationOptions -- Apple Developer Documentation (https://developer.apple.com/documentation/usernotifications/unnotificationpresentationoptions)

### Secondary (MEDIUM confidence)
- Todoist iOS notification scheduler architecture (https://www.doist.dev/implementing-a-local-notification-scheduler-in-todoist-ios/) -- Verified architecture pattern used in production app
- CreateWithSwift async/await notification tutorial (https://www.createwithswift.com/notifications-tutorial-creating-and-scheduling-user-notifications-with-async-await/) -- Code examples verified against Apple API signatures
- Donny Wals: DateComponents timezone pitfall (https://www.donnywals.com/scheduling-daily-notifications-on-ios-using-calendar-and-datecomponents/) -- Timezone default to GMT verified
- Swift 6 UNUserNotificationCenterDelegate issues (https://github.com/swiftlang/swift/issues/78833) -- Framework concurrency gap confirmed by Swift team
- Apple Developer Forums: Swift 6 delegate crash (https://developer.apple.com/forums/thread/796407) -- nonisolated solution confirmed

### Tertiary (LOW confidence)
- NSUserNotificationsUsageDescription requirement status for iOS 18 -- Could not verify from official docs whether this is now mandatory. Best practice to include regardless.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - UserNotifications is the only Apple-sanctioned local notification framework, no alternatives exist
- Architecture: HIGH - Priority-based scheduling with actor serialization follows the Todoist production pattern and Swift concurrency best practices
- Pitfalls: HIGH - 64-notification limit is well-documented by Apple; timezone issue verified by multiple sources; Swift 6 delegate issue confirmed by Swift team
- Code examples: HIGH - All examples verified against Apple API signatures and async/await patterns

**Research date:** 2026-02-15
**Valid until:** 2026-03-15 (stable domain -- UserNotifications framework changes slowly)
