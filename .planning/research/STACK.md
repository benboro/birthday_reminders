# Stack Research

**Domain:** Native iOS Birthday Reminder App
**Researched:** 2026-02-15
**Confidence:** HIGH

## Deployment Target Recommendation

**Target iOS 18.0+ (minimum)**

| Factor | Detail |
|--------|--------|
| Current iOS landscape | iOS 26.3 is the latest release (Feb 2026). iOS 26 has 66% adoption across all iPhones, 74% on devices from the last 4 years. iOS 18 had 82%+ adoption before iOS 26 launched. |
| Why not iOS 17 | iOS 18 brought ContactAccessButton, limited contacts access APIs, SwiftData improvements (#Index, #Unique, history API), and significant SwiftUI enhancements. These are critical for this app. |
| Why not iOS 26 only | Too aggressive -- would exclude ~34% of iPhones. iOS 18 gives us SwiftData maturity + new Contacts APIs while covering the vast majority of active devices. |
| App Store requirement | As of April 2025, apps must be built with Xcode 16 / iOS 18 SDK. Starting April 2026, apps must use iOS 26 SDK. Building with the iOS 26 SDK does not require iOS 26 as the deployment target. |

**Confidence: HIGH** -- Verified via Apple developer requirements, TelemetryDeck adoption stats, and MacRumors adoption reports.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.2 | Programming language | Latest stable release (Sept 2025). Improved concurrency model with "single-threaded by default" mode, @concurrent attribute, Inline Arrays, and Span type. Swift 6's strict concurrency checking catches data races at compile time. |
| SwiftUI | iOS 18+ / iOS 26+ | UI framework | The standard for new iOS apps. Apple's primary investment target. Declarative, composable, and deeply integrated with SwiftData and the Observation framework. iOS 18 added improved sheet presentation, mesh gradients, and better UIKit interop. |
| SwiftData | iOS 17+ (target iOS 18+ for maturity) | Data persistence | Apple's modern persistence framework, built on Core Data's SQLite engine but with pure Swift API. iOS 18 added #Unique compound constraints, #Index for faster queries, and the history API. Eliminates Core Data boilerplate entirely. |
| Contacts framework | iOS 9+ | Access phone contacts & groups | The only supported way to read/write iOS contacts. CNContactStore for data access, CNGroup/CNMutableGroup for group management, CNSaveRequest for two-way sync. Mature and stable. |
| UserNotifications | iOS 10+ | Local notifications | Apple's notification framework. Supports time-interval, calendar, and location triggers. Required for birthday reminders (same-day, day-before, weekly/monthly previews). No third-party alternative exists for local notifications on iOS. |
| Observation framework | iOS 17+ | Reactive state management | @Observable macro replaces ObservableObject/@Published pattern. Only re-renders views that read changed properties (not all published properties). Significant performance improvement and less boilerplate. |
| WidgetKit | iOS 14+ | Home screen widgets | Native widget framework using SwiftUI. TimelineProvider-based architecture fits birthday countdown perfectly. Shows upcoming birthdays at a glance without opening the app. |

**Confidence: HIGH** -- All verified via Apple official documentation, WWDC sessions, and developer.apple.com release notes.

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ContactsUI (ContactAccessButton) | iOS 18+ | Incremental contacts access | Use when the user has granted limited contacts access and needs to share additional contacts with the app. New iOS 18 API that handles the privacy UI for you. |
| Swift Testing | Xcode 16+ / Swift 6+ | Unit testing | Use for all new unit tests. Replaces XCTest with @Test macro, #expect assertions, built-in parameterized testing, and parallel execution by default. Coexists with XCTest. |
| XCTest | Built-in | UI testing | Swift Testing does not yet support UI testing or performance testing. Keep XCTest for those specific needs only. |

**Confidence: HIGH** -- Apple first-party frameworks only; no third-party dependencies needed.

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 26.2+ (current stable) | IDE, build system, simulator | Required for iOS 26 SDK. Xcode 26.3 RC available (Feb 2026) with agentic coding support. Use at least Xcode 26.2 for stability. |
| Swift Package Manager | Dependency management | Built into Xcode. No CocoaPods or Carthage needed for this project since we use zero third-party dependencies. SPM is the standard for Swift projects. |
| Xcode Previews | Live UI development | SwiftUI previews with SwiftData support (added in iOS 18 era). Use #Preview macro with in-memory ModelContainer for fast iteration. |
| Instruments | Performance profiling | Profile contact fetching performance, memory usage during bulk operations, and notification scheduling efficiency. |

## Installation

This project uses zero third-party dependencies. All technologies are Apple first-party frameworks included in the iOS SDK.

```swift
// Package.swift or Xcode project -- no external packages needed

// Frameworks to import in code:
import SwiftUI        // UI
import SwiftData      // Persistence
import Contacts       // Contact access
import ContactsUI     // ContactAccessButton (iOS 18+)
import UserNotifications  // Local notifications
import WidgetKit      // Home screen widget (widget extension)
```

**Project setup in Xcode:**
1. Create new iOS App project
2. Select SwiftUI for interface, Swift for language
3. Check "Use SwiftData" for storage
4. Add Widget Extension target (for birthday countdown widget)

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SwiftData | Core Data | Only if you need heavyweight/custom migrations, have an existing Core Data stack to maintain, or must support iOS 15/16. For a greenfield app targeting iOS 18+, SwiftData is the clear choice. |
| SwiftUI | UIKit | Only for specific screens requiring complex custom drawing, advanced collection view layouts, or UIKit-only APIs. SwiftUI can bridge to UIKit via UIViewRepresentable when needed. For this app, pure SwiftUI is sufficient. |
| @Observable | ObservableObject + @Published | Only if you must support iOS 16 or earlier. @Observable is strictly superior: fewer property wrappers, granular view updates, simpler syntax. |
| Swift Testing | XCTest (for unit tests) | Only for UI tests and performance tests, which Swift Testing does not yet support. For all unit/logic tests, Swift Testing is faster to write and more expressive. |
| Local notifications | Push notifications (APNs) | Never for this app. Push notifications require a backend server. This app is purely local with no server component. Local notifications via UNUserNotificationCenter are the correct choice. |
| SwiftData | UserDefaults | Only for simple key-value preferences (like notification timing settings). Never for structured birthday/group data. UserDefaults is not a database. |
| SwiftData | SQLite directly (GRDB, etc.) | Unnecessary complexity. SwiftData provides the ORM layer, SwiftUI integration, and @Query reactivity that raw SQLite cannot. Third-party SQLite wrappers add a dependency for no benefit here. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Core Data (for new code) | Requires NSManagedObject subclasses, .xcdatamodeld files, and verbose boilerplate. SwiftData replaces all of this with @Model macros and pure Swift. For iOS 18+ greenfield, there is no reason to use Core Data directly. | SwiftData |
| Combine | Apple has moved to async/await and the Observation framework. Combine pipelines are harder to debug, have a steep learning curve, and are no longer the recommended pattern for SwiftUI data flow. | async/await + @Observable |
| ObservableObject / @Published | Causes unnecessary view re-renders (any @Published change triggers all subscribers). The @Observable macro provides granular tracking, re-rendering only views that read the changed property. | @Observable macro (Observation framework) |
| Storyboards / Interface Builder | Incompatible with SwiftUI. Apple has not invested in IB for years. SwiftUI previews provide the same live feedback with better code integration. | SwiftUI declarative views |
| CocoaPods / Carthage | Legacy dependency managers. Swift Package Manager is built into Xcode and is Apple's official solution. This project needs no third-party packages anyway. | Swift Package Manager (if needed) |
| EventKit (for reminders) | While EventKit can create calendar events for birthdays, it requires separate permissions and does not provide the notification customization (same-day, day-before, weekly preview) that UNUserNotificationCenter offers. | UserNotifications framework |
| RxSwift / ReactiveCocoa | Heavy third-party reactive frameworks. Swift's built-in async/await, @Observable, and structured concurrency provide everything needed without external dependencies. | Native Swift concurrency |
| Third-party notification libraries | No iOS library can bypass the system notification APIs. Any wrapper just adds indirection over UNUserNotificationCenter. Use the framework directly. | UserNotifications (direct) |

## Key Architecture Patterns

### SwiftData Model Pattern

```swift
import SwiftData

@Model
final class Person {
    var firstName: String
    var lastName: String
    var birthday: DateComponents  // Day + month required, year optional
    var notes: String
    var contactIdentifier: String?  // Links to CNContact

    @Relationship(deleteRule: .nullify, inverse: \BirthdayGroup.members)
    var groups: [BirthdayGroup]

    var nextBirthday: Date {
        // Computed: next occurrence of this birthday
    }

    init(firstName: String, lastName: String, birthday: DateComponents) {
        self.firstName = firstName
        self.lastName = lastName
        self.birthday = birthday
        self.notes = ""
        self.groups = []
    }
}
```

### @Observable ViewModel Pattern

```swift
import Observation
import Contacts

@Observable
@MainActor
final class ContactsManager {
    var authorizationStatus: CNAuthorizationStatus = .notDetermined
    var contacts: [CNContact] = []
    var isLoading = false
    var error: Error?

    private let store = CNContactStore()  // Single instance, reuse

    func requestAccess() async {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        } catch {
            self.error = error
        }
    }

    func fetchContactsWithBirthdays() async {
        isLoading = true
        defer { isLoading = false }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        // Fetch on background -- enumerateContacts is synchronous
        // Wrap in Task.detached or use actor isolation
    }
}
```

### Notification Scheduling Pattern

```swift
import UserNotifications

@Observable
@MainActor
final class NotificationManager {
    var isAuthorized = false

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            // Handle error
        }
    }

    func scheduleBirthdayReminder(
        for person: Person,
        daysBeforeOptions: [Int]  // e.g., [0, 1, 7] for same-day, day-before, week-before
    ) async {
        let center = UNUserNotificationCenter.current()

        for daysBefore in daysBeforeOptions {
            let content = UNMutableNotificationContent()
            content.title = daysBefore == 0
                ? "\(person.firstName)'s Birthday Today!"
                : "\(person.firstName)'s Birthday in \(daysBefore) day(s)"
            content.sound = .default

            var dateComponents = person.birthday
            // Adjust dateComponents by subtracting daysBefore
            // Set hour/minute for preferred notification time

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true  // Repeats annually
            )

            let request = UNNotificationRequest(
                identifier: "\(person.contactIdentifier ?? UUID().uuidString)-\(daysBefore)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }
}
```

## Version Compatibility

| Component | Requires | Compatible With | Notes |
|-----------|----------|-----------------|-------|
| SwiftData @Model | iOS 17+ | Swift 5.9+ / Xcode 15+ | Use iOS 18+ for #Unique, #Index, and history API |
| @Observable macro | iOS 17+ | Swift 5.9+ / Xcode 15+ | Replaces ObservableObject entirely for iOS 17+ targets |
| ContactAccessButton | iOS 18+ | Xcode 16+ | New in iOS 18. Use #available check if supporting iOS 17. Since we target iOS 18+, available everywhere. |
| Swift Testing (@Test) | Swift 6.0+ | Xcode 16+ | Coexists with XCTest in the same test target |
| UNCalendarNotificationTrigger | iOS 10+ | All supported targets | Stable API, unchanged for years |
| CNContactStore async | iOS 15+ (Swift concurrency) | Swift 5.5+ | The store's methods have async overloads via Swift concurrency |
| WidgetKit | iOS 14+ | Xcode 12+ | Use AppIntentConfiguration (iOS 17+) over legacy IntentConfiguration |
| SwiftData #Unique | iOS 18+ | Xcode 16+ | Compound uniqueness constraints for deduplication during contact sync |
| SwiftData #Index | iOS 18+ | Xcode 16+ | Index birthday fields for fast upcoming-birthday queries |

## Stack Patterns by Variant

**If you add iCloud sync later:**
- Use SwiftData with CloudKit integration (ModelConfiguration with cloudKitDatabase)
- Requires an Apple Developer Program membership and CloudKit container setup
- SwiftData handles the sync automatically, but adds complexity around conflict resolution
- Not recommended for MVP; keep it local-only first

**If you want to support iOS 17:**
- Drop iOS 18 minimum to iOS 17
- Lose: ContactAccessButton, SwiftData #Unique/#Index, SwiftData history API
- Gain: ~5% more device coverage (diminishing returns)
- Recommendation: Not worth it. iOS 18 APIs are too valuable for this app's use case.

**If the contact list is very large (10,000+ contacts):**
- Use CNContactFetchRequest with enumerateContacts (streaming, low memory) instead of unifiedContacts(matching:keysToFetch:) (loads all into memory)
- Apply #Index on birthday-related SwiftData fields
- Consider pagination in the UI with LazyVStack

## Sources

- [Apple: What's New in Swift](https://developer.apple.com/swift/whats-new/) -- Swift 6.2 features confirmed (HIGH confidence)
- [Swift.org: Swift 6.2 Released](https://www.swift.org/blog/swift-6.2-released/) -- Release date Sept 15, 2025 (HIGH confidence)
- [Apple: SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui) -- iOS 18 and iOS 26 SwiftUI features (HIGH confidence)
- [Apple: SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) -- @Model, @Query, ModelContainer (HIGH confidence)
- [Apple: WWDC24 What's New in SwiftData](https://developer.apple.com/videos/play/wwdc2024/10137/) -- #Unique, #Index, history API (HIGH confidence)
- [Apple: CNContactStore Documentation](https://developer.apple.com/documentation/contacts/cncontactstore) -- Contact access APIs (HIGH confidence)
- [Apple: CNContact.birthday](https://developer.apple.com/documentation/contacts/cncontact/1403059-birthday) -- DateComponents, day+month required (HIGH confidence)
- [Apple: ContactAccessButton](https://developer.apple.com/documentation/contactsui/contactaccessbutton) -- iOS 18+ limited access UI (HIGH confidence)
- [Apple: Meet the Contact Access Button (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10121/) -- Limited contacts access model (HIGH confidence)
- [Apple: Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro) -- Migration guide (HIGH confidence)
- [Apple: Swift Testing](https://developer.apple.com/xcode/swift-testing) -- @Test, #expect, parameterized testing (HIGH confidence)
- [Apple: Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/) -- Xcode/SDK submission requirements (HIGH confidence)
- [TelemetryDeck: iOS Version Market Share](https://telemetrydeck.com/survey/apple/iOS/majorSystemVersions/) -- iOS 26 at 66% adoption Feb 2026 (MEDIUM confidence)
- [Hacking with Swift: ContactAccessButton](https://www.hackingwithswift.com/quick-start/swiftui/how-to-read-user-contacts-with-contactaccessbutton) -- Usage examples (MEDIUM confidence)
- [Hacking with Swift: SwiftData by Example](https://www.hackingwithswift.com/quick-start/swiftdata) -- Practical patterns (MEDIUM confidence)
- [Donny Wals: @Observable explained](https://www.donnywals.com/comparing-observable-to-observableobjects/) -- Performance comparison (MEDIUM confidence)
- [SwiftData Architecture Patterns (AzamSharp, March 2025)](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html) -- @Query architecture (MEDIUM confidence)

---
*Stack research for: Birthday Reminders -- Native iOS App*
*Researched: 2026-02-15*
