# Architecture Research

**Domain:** iOS Birthday Reminder App (local-only, SwiftUI)
**Researched:** 2026-02-15
**Confidence:** HIGH

## Standard Architecture

Use **MVVM with Service Layer** -- the modern SwiftUI variant powered by `@Observable` (not the legacy `ObservableObject` + `@Published` pattern). SwiftUI's 2023+ observation system makes MVVM natural: Views observe `@Observable` ViewModels, ViewModels delegate to injected Services, Services own framework interactions (Contacts, Notifications, SwiftData).

This is not the bloated "ViewModel-per-view" MVVM of UIKit days. Modern SwiftUI MVVM means: ViewModels only where real business logic exists. Pure display views (lists, detail cards) read `@Query` or `@Bindable` directly. ViewModels coordinate multi-service operations like "sync contacts then reschedule notifications."

### System Overview

```
+-----------------------------------------------------------------+
|                      PRESENTATION LAYER                         |
|  +------------+  +-------------+  +------------+  +---------+  |
|  | Birthday   |  | Group       |  | Settings   |  | Notif.  |  |
|  | List View  |  | Mgmt View  |  | View       |  | Prefs   |  |
|  +-----+------+  +------+------+  +-----+------+  +----+----+  |
|        |                |               |               |       |
+--------+----------------+---------------+---------------+-------+
|                      VIEWMODEL LAYER                            |
|  +------------+  +-------------+  +---------------------------+ |
|  | Birthday   |  | Group       |  | Settings                  | |
|  | ListVM     |  | Manager VM  |  | ViewModel                 | |
|  +-----+------+  +------+------+  +------------+--------------+ |
|        |                |                       |               |
+--------+----------------+-----------------------+---------------+
|                      SERVICE LAYER                              |
|  +----------------+  +----------------+  +------------------+   |
|  | ContactSync    |  | Notification   |  | Birthday         |   |
|  | Service        |  | Scheduler      |  | Calculator       |   |
|  +-------+--------+  +-------+--------+  +--------+---------+   |
|          |                    |                     |            |
+----------+--------------------+---------------------+-----------+
|                      DATA LAYER                                 |
|  +----------------+  +----------------+  +------------------+   |
|  | SwiftData      |  | CNContactStore |  | UNUserNotif.     |   |
|  | ModelContainer |  | (iOS Contacts) |  | Center           |   |
|  +----------------+  +----------------+  +------------------+   |
+-----------------------------------------------------------------+
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **BirthdayListView** | Display upcoming birthdays grouped by timeframe (today, this week, this month) | SwiftUI View with `@Query` for SwiftData, sorted by next-birthday date |
| **GroupManagementView** | Create/edit/delete groups, assign contacts to groups | SwiftUI View bound to GroupManagerVM |
| **SettingsView** | Configure notification timing per group, app preferences | SwiftUI Form bound to SettingsViewModel |
| **BirthdayListVM** | Coordinate birthday display, trigger syncs, handle search/filter | `@Observable` class, owns no data directly, delegates to services |
| **GroupManagerVM** | Orchestrate group CRUD with two-way Contacts sync | `@Observable` class, coordinates ContactSyncService + SwiftData |
| **SettingsViewModel** | Manage notification preferences, trigger notification rescheduling | `@Observable` class, writes to UserDefaults/SwiftData, calls NotificationScheduler |
| **ContactSyncService** | Import contacts from iOS Contacts, sync groups bidirectionally | Wraps CNContactStore, handles authorization, maps CNContact to app models |
| **NotificationScheduler** | Schedule/cancel local notifications respecting the 64-notification limit | Wraps UNUserNotificationCenter, implements priority queue for overflow |
| **BirthdayCalculator** | Pure logic: compute next birthday, days until, age turning | Pure functions, no dependencies, highly testable |
| **SwiftData ModelContainer** | Persist app's contact records, groups, notification preferences | `@Model` classes: Person, BirthdayGroup, NotificationPreference |
| **CNContactStore** | iOS system Contacts database | Apple framework -- read/write contacts and groups |
| **UNUserNotificationCenter** | iOS system notification scheduling | Apple framework -- schedule up to 64 pending local notifications |

## Recommended Project Structure

```
BirthdayReminders/
+-- App/
|   +-- BirthdayRemindersApp.swift     # @main entry, ModelContainer setup
|   +-- AppDelegate.swift              # UNUserNotificationCenter delegate
+-- Models/
|   +-- Person.swift                   # @Model: synced contact with birthday
|   +-- BirthdayGroup.swift            # @Model: group with notification prefs
|   +-- NotificationPreference.swift   # @Model: timing config per group
|   +-- ContactBridge.swift            # Maps CNContact <-> Person
+-- ViewModels/
|   +-- BirthdayListViewModel.swift    # Upcoming birthdays coordination
|   +-- GroupManagerViewModel.swift    # Group CRUD + two-way sync
|   +-- SettingsViewModel.swift        # Notification prefs management
+-- Views/
|   +-- BirthdayList/
|   |   +-- BirthdayListView.swift     # Main list with sections
|   |   +-- BirthdayRowView.swift      # Single birthday row
|   |   +-- BirthdayDetailView.swift   # Contact detail with edit
|   +-- Groups/
|   |   +-- GroupListView.swift        # All groups
|   |   +-- GroupDetailView.swift      # Group members + prefs
|   |   +-- GroupEditorView.swift      # Create/edit group
|   +-- Settings/
|   |   +-- SettingsView.swift         # App settings
|   |   +-- NotificationTimingView.swift # Per-group notification config
|   +-- Onboarding/
|   |   +-- ContactPermissionView.swift # Authorization request flow
|   +-- Components/
|       +-- AvatarView.swift           # Contact photo display
|       +-- CountdownBadge.swift       # Days-until badge
+-- Services/
|   +-- ContactSyncService.swift       # CNContactStore wrapper
|   +-- NotificationScheduler.swift    # UNUserNotificationCenter wrapper
|   +-- BirthdayCalculator.swift       # Date math utilities
|   +-- ContactChangeObserver.swift    # CNContactStoreDidChange listener
+-- Extensions/
|   +-- Date+Birthday.swift            # Date helpers for birthday math
|   +-- Color+Theme.swift              # App color palette
+-- Resources/
    +-- Assets.xcassets                # App icons, colors
    +-- Localizable.strings            # Localization
```

### Structure Rationale

- **Models/**: Separated because they serve both Views (via `@Query`) and Services (via ModelContext). The ContactBridge mapper is here because it is a data-level concern (translating between CNContact and the app's Person model).
- **ViewModels/**: Only three ViewModels for the three major feature areas. Not every view gets a ViewModel -- `BirthdayRowView` and `AvatarView` are pure display components that take model objects directly.
- **Services/**: The core business logic. These are `@Observable` classes injected via SwiftUI `.environment()`. They wrap iOS frameworks and can be replaced with mocks for testing.
- **Views/**: Feature-grouped, not type-grouped. Each feature folder contains all views for that flow.

## Architectural Patterns

### Pattern 1: @Observable Service Injection via Environment

**What:** Services are `@Observable` classes created at the App level and injected into the view hierarchy via `.environment()`. Views and ViewModels access them through `@Environment`.
**When to use:** For all shared services (ContactSyncService, NotificationScheduler).
**Trade-offs:** Simple setup, testable via environment overrides, but all services are created at app launch regardless of whether they are needed immediately.

**Example:**
```swift
// Service definition
@Observable
class ContactSyncService {
    private let store = CNContactStore()
    private(set) var syncStatus: SyncStatus = .idle
    private(set) var lastSyncDate: Date?

    func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }

    func syncContacts(into context: ModelContext) async throws {
        syncStatus = .syncing
        defer { syncStatus = .idle }
        // fetch from CNContactStore, upsert into SwiftData
    }
}

// App-level injection
@main
struct BirthdayRemindersApp: App {
    @State private var contactSync = ContactSyncService()
    @State private var notificationScheduler = NotificationScheduler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(contactSync)
                .environment(notificationScheduler)
        }
        .modelContainer(for: [Person.self, BirthdayGroup.self])
    }
}

// View consumption
struct BirthdayListView: View {
    @Environment(ContactSyncService.self) private var contactSync
    @Query(sort: \Person.nextBirthdayDate) private var people: [Person]

    var body: some View {
        List(people) { person in
            BirthdayRowView(person: person)
        }
        .task {
            try? await contactSync.syncContacts(into: modelContext)
        }
    }
}
```

### Pattern 2: Notification Overflow Queue (Todoist Pattern)

**What:** iOS limits apps to 64 pending local notifications. The NotificationScheduler maintains a priority queue: the 64 soonest notifications are scheduled with the OS, and the rest are persisted to SwiftData. When the app launches or a notification fires, the scheduler backfills from the overflow queue.
**When to use:** Any birthday app with more than ~20 contacts (since each contact may need 2-3 notifications: day-before, same-day, weekly preview).
**Trade-offs:** Adds complexity but is architecturally necessary. Without this, users with many contacts silently lose notifications.

**Example:**
```swift
@Observable
class NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    func rescheduleAll(people: [Person], groups: [BirthdayGroup],
                       context: ModelContext) async throws {
        // 1. Remove all pending
        center.removeAllPendingNotificationRequests()

        // 2. Generate ALL notification intents
        var allNotifications = generateNotifications(
            people: people, groups: groups
        )

        // 3. Sort by fire date (soonest first)
        allNotifications.sort { $0.fireDate < $1.fireDate }

        // 4. Schedule first 64 with OS
        let scheduled = Array(allNotifications.prefix(64))
        for notif in scheduled {
            let request = notif.toUNNotificationRequest()
            try await center.add(request)
        }

        // 5. Persist overflow to SwiftData for later backfill
        let overflow = Array(allNotifications.dropFirst(64))
        persistOverflow(overflow, context: context)
    }
}
```

### Pattern 3: ContactBridge Mapper (CNContact to App Model)

**What:** A stateless mapper that converts between `CNContact` (iOS framework type, immutable, key-based property access) and the app's `Person` SwiftData model. This boundary prevents iOS framework types from leaking into the view layer.
**When to use:** Every contact sync operation. The bridge is the single point of truth for field mapping.
**Trade-offs:** Small overhead, but isolates the app from Contacts framework changes and makes testing straightforward.

**Example:**
```swift
struct ContactBridge {
    static func person(from contact: CNContact) -> Person {
        let person = Person()
        person.contactIdentifier = contact.identifier
        person.firstName = contact.givenName
        person.lastName = contact.familyName
        person.birthday = contact.birthday?.date
        person.thumbnailImageData = contact.thumbnailImageData
        return person
    }

    static func update(_ person: Person, from contact: CNContact) {
        person.firstName = contact.givenName
        person.lastName = contact.familyName
        person.birthday = contact.birthday?.date
        person.thumbnailImageData = contact.thumbnailImageData
    }

    static func keysToFetch() -> [CNKeyDescriptor] {
        [
            CNContactIdentifierKey,
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactBirthdayKey,
            CNContactThumbnailImageDataKey,
        ] as [CNKeyDescriptor]
    }
}
```

### Pattern 4: Two-Way Group Sync

**What:** Groups exist in both the app (SwiftData) and iOS Contacts (CNGroup). Changes in either direction must propagate. The app is the initiator of sync, but must respect that the user may modify groups outside the app.
**When to use:** On every app foreground and on `CNContactStoreDidChange` notification.
**Trade-offs:** Most complex part of the architecture. Conflict resolution is necessary (what if a group is renamed in both places?).

**Strategy:**
1. App groups store a `contactGroupIdentifier` linking to the corresponding `CNGroup`.
2. On sync: fetch all CNGroups, diff against local BirthdayGroups.
3. New local group -> create CNGroup via CNSaveRequest.
4. New CNGroup (created outside app) -> optionally surface to user.
5. Membership changes -> update CNSaveRequest to add/remove members.
6. Conflict resolution: last-write-wins with the app's version taking priority (since the app is the active editor).

## Data Flow

### Contact Sync Flow

```
[App Launch / Foreground]
    |
    v
[ContactSyncService.syncContacts()]
    |
    +-- Check CNAuthorizationStatus
    |       |
    |       +-- .notDetermined -> requestAccess() -> prompt user
    |       +-- .authorized -> proceed with full sync
    |       +-- .limited -> proceed (only see selected contacts)
    |       +-- .denied -> show settings redirect
    |
    +-- Fetch CNContacts with birthday key
    |       |
    |       +-- enumerateContacts(with:) on background thread
    |       +-- Filter: only contacts WITH a birthday set
    |
    +-- ContactBridge.person(from:) for each contact
    |
    +-- Upsert into SwiftData (match on contactIdentifier)
    |       |
    |       +-- New contact -> insert Person
    |       +-- Existing contact -> update fields
    |       +-- Missing from Contacts -> mark as deleted / remove
    |
    +-- Sync groups bidirectionally
    |
    +-- Trigger NotificationScheduler.rescheduleAll()
```

### Notification Scheduling Flow

```
[Trigger: sync complete, preference change, app foreground]
    |
    v
[NotificationScheduler.rescheduleAll()]
    |
    +-- Fetch all Person records with birthdays
    +-- Fetch all BirthdayGroup records with notification prefs
    |
    +-- For each Person:
    |       +-- Determine which groups they belong to
    |       +-- For each group's notification preferences:
    |           +-- Generate notification intents:
    |               - Same-day morning notification
    |               - Day-before notification
    |               - Week-before notification (if configured)
    |               - Monthly preview (if configured)
    |
    +-- Sort all intents by fire date (soonest first)
    +-- Schedule top 64 via UNUserNotificationCenter
    +-- Persist remainder to SwiftData overflow table
    +-- Store scheduled identifiers for later cancellation
```

### Group Management Flow

```
[User creates/edits group in app]
    |
    v
[GroupManagerViewModel]
    |
    +-- Create/update BirthdayGroup in SwiftData
    |
    +-- ContactSyncService.syncGroupToContacts(group)
    |       |
    |       +-- If group.contactGroupIdentifier == nil:
    |       |       Create CNMutableGroup -> CNSaveRequest -> execute
    |       |       Store resulting identifier back on BirthdayGroup
    |       |
    |       +-- If group has identifier:
    |               Update CNGroup name if changed
    |               Diff members -> add/remove via CNSaveRequest
    |
    +-- NotificationScheduler.rescheduleAll()
        (because group prefs may have changed)
```

### Key Data Flows

1. **Contact Import:** CNContactStore -> ContactBridge -> SwiftData Person records. One-directional for contact data (app reads from Contacts, never writes contact details back). Runs on background thread to avoid blocking UI.

2. **Group Sync:** Bidirectional. App creates/modifies BirthdayGroup in SwiftData AND corresponding CNGroup in Contacts. On app foreground, reads CNGroups to detect external changes.

3. **Notification Scheduling:** Purely derived from SwiftData state. Any change to persons, groups, or preferences triggers a full reschedule. The scheduler is stateless regarding what "should" be scheduled -- it recomputes from source of truth every time.

4. **Birthday Calculation:** Pure function layer. `BirthdayCalculator.nextBirthday(from: Date) -> Date` and `daysUntil(birthday: Date) -> Int`. Called by Views for display and by NotificationScheduler for trigger dates.

## Scaling Considerations

This is a local-only single-user app. "Scaling" means handling large contact lists gracefully, not multi-server deployment.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-50 contacts | No special handling needed. Full sync on every foreground is fine. All notifications fit in the 64 limit. |
| 50-200 contacts | Notification overflow queue becomes essential (~3 notifications per contact = 150-600 intents). Background sync should be incremental if possible. |
| 200-1000 contacts | Contact sync must use batch processing. UI must use pagination or lazy loading. Consider using `CNChangeHistoryFetchRequest` (via Objective-C bridge) for incremental sync instead of full re-fetch. |
| 1000+ contacts | Rare for birthday tracking but possible. Full sync on every foreground becomes expensive. Must implement differential sync with stored history token. Consider showing only contacts with birthdays set (typically 20-40% of contacts). |

### Scaling Priorities

1. **First bottleneck:** Notification 64-limit. Hits at ~20 contacts with multi-notification preferences. Must be handled from day one.
2. **Second bottleneck:** Contact sync time on large address books. Mitigate by filtering contacts-with-birthdays server-side in the fetch predicate and running on a background thread.

## Anti-Patterns

### Anti-Pattern 1: ViewModel Per View

**What people do:** Create a ViewModel for every single SwiftUI view, including simple display views like a birthday row.
**Why it's wrong:** In modern SwiftUI, `@Query` and `@Bindable` handle simple data display without a ViewModel. Over-abstracting creates unnecessary indirection, makes code harder to follow, and inflates the codebase.
**Do this instead:** Only create ViewModels for views that coordinate multiple services or contain complex business logic. Pure display views should bind directly to model objects or use `@Query`.

### Anti-Pattern 2: Storing Notification State as Source of Truth

**What people do:** Track which notifications are scheduled in their own database and try to keep it in sync with `UNUserNotificationCenter`.
**Why it's wrong:** The OS can silently remove notifications (app update, OS restart, Settings changes). Your database will drift from reality. Debugging becomes a nightmare.
**Do this instead:** Treat notifications as derived state. On every relevant change, call `removeAllPendingNotificationRequests()` then reschedule everything from SwiftData. The overflow queue persists intents (not scheduled state), and the scheduler is purely idempotent.

### Anti-Pattern 3: Fetching All CNContact Properties

**What people do:** Use `[CNContactVCardSerialization.descriptorForRequiredKeys()]` or request all keys when fetching contacts.
**Why it's wrong:** Massively increases memory usage and fetch time. Most properties are irrelevant for a birthday app. Apple explicitly warns against this.
**Do this instead:** Specify only the keys you need via `keysToFetch`: identifier, given name, family name, birthday, and thumbnail image data. Use `ContactBridge.keysToFetch()` as the single source of truth for required keys.

### Anti-Pattern 4: Synchronous Contact Fetching on Main Thread

**What people do:** Call `CNContactStore.enumerateContacts(with:)` on the main thread.
**Why it's wrong:** Contact enumeration on large address books can take several seconds, freezing the entire UI.
**Do this instead:** Always run contact operations in a `Task { }` or on a background actor. Show a loading indicator during sync.

### Anti-Pattern 5: Ignoring Limited Contact Access (iOS 18+)

**What people do:** Only handle `.authorized` and `.denied`, assuming full contact access.
**Why it's wrong:** iOS 18 introduced `.limited` authorization where users grant access to a subset of contacts. If you ignore this, the app appears broken for users who choose limited access.
**Do this instead:** Handle all four `CNAuthorizationStatus` cases: `.notDetermined`, `.authorized`, `.limited`, `.denied`. For `.limited`, work normally with the subset of contacts the user selected, and offer a button to modify the selection via the Contact Access Picker.

## Integration Points

### External Services (iOS Frameworks)

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **CNContactStore** | Singleton instance in ContactSyncService, accessed on background thread | Must handle `.limited` auth (iOS 18+). Use single instance per Apple's guidance. Group sync requires `CNSaveRequest` with container identifier. |
| **UNUserNotificationCenter** | `.current()` singleton in NotificationScheduler | 64-notification hard limit. Calendar triggers for birthday dates. Must set delegate in AppDelegate for foreground notification handling. |
| **NotificationCenter** (Foundation) | Observe `CNContactStoreDidChange` for external contact modifications | Fires for ALL changes including your own. Filter by checking if the app initiated the change. Consider ContactsChangeNotifier library. |
| **SwiftData ModelContainer** | Created once in App struct, injected via `.modelContainer()` modifier | `ModelContext` available via `@Environment(\.modelContext)`. Use `@Query` in views, explicit `ModelContext` in services. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| View <-> ViewModel | `@Observable` + `@Bindable` / `@Environment` | Views observe VM properties reactively. VMs expose async methods for user actions. |
| ViewModel <-> Service | Direct method calls (services injected via init or Environment) | VMs call service methods, observe service state. Services are shared across VMs. |
| Service <-> SwiftData | `ModelContext` passed into service methods | Services do NOT own the ModelContext. Caller provides it. This keeps the container lifecycle in the App struct. |
| Service <-> iOS Framework | Wrapped behind service interface | CNContactStore, UNUserNotificationCenter never appear outside their respective service wrappers. |
| ContactSyncService <-> NotificationScheduler | Event-driven: sync completion triggers reschedule | No direct coupling. The ViewModel or a coordinator calls reschedule after sync completes. |

## Build Order Implications

The components have clear dependency ordering that should inform the roadmap phases:

```
Phase 1: Foundation
    SwiftData Models (Person, BirthdayGroup, NotificationPreference)
    BirthdayCalculator (pure logic, no dependencies)
    ContactBridge (mapper, depends only on Models)

Phase 2: Core Data Flow
    ContactSyncService (depends on Models, ContactBridge)
    Contact authorization flow (depends on ContactSyncService)
    BirthdayListView + BirthdayListVM (depends on Models, ContactSyncService)

Phase 3: Notifications
    NotificationScheduler (depends on Models, BirthdayCalculator)
    Overflow queue implementation
    Settings UI for notification preferences

Phase 4: Group Management
    GroupManagerViewModel (depends on ContactSyncService, Models)
    Two-way group sync (depends on ContactSyncService being stable)
    Group-specific notification preferences

Phase 5: Polish
    ContactChangeObserver (CNContactStoreDidChange)
    Incremental sync optimization
    Limited access handling (iOS 18+)
    Edge cases: contacts without birthdays, deleted contacts, etc.
```

**Rationale:** Models must come first because everything depends on them. Contact sync before notifications because notifications are derived from synced data. Groups last because they add the most complexity (two-way sync) and depend on both contact sync and notification scheduling being stable.

## Sources

- [SwiftUI MVVM Best Practices (SwiftLee)](https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/) -- MEDIUM confidence
- [Modern MVVM in SwiftUI 2025 (Medium)](https://medium.com/@minalkewat/modern-mvvm-in-swiftui-2025-the-clean-architecture-youve-been-waiting-for-72a7d576648e) -- LOW confidence
- [Clean Architecture for SwiftUI (Alexey Naumov)](https://nalexn.github.io/clean-architecture-swiftui/) -- MEDIUM confidence
- [CNContactStore (Apple Developer Documentation)](https://developer.apple.com/documentation/contacts/cncontactstore) -- HIGH confidence
- [CNGroup (Apple Developer Documentation)](https://developer.apple.com/documentation/contacts/cngroup) -- HIGH confidence
- [Scheduling Local Notifications (Apple Developer Documentation)](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) -- HIGH confidence
- [iOS Pending Notification Limit (Apple Developer Forums)](https://developer.apple.com/forums/thread/106829) -- HIGH confidence
- [Todoist iOS Notification Scheduler Architecture (Doist Engineering)](https://www.doist.dev/implementing-a-local-notification-scheduler-in-todoist-ios/) -- MEDIUM confidence
- [Contact Change Tracking (LogicWind)](https://blog.logicwind.com/fetch-recently-added-contacts-in-android-and-ios/) -- MEDIUM confidence
- [CNChangeHistoryFetchRequest Swift Limitation (Apple Developer Forums)](https://developer.apple.com/forums/thread/696387) -- HIGH confidence
- [ContactsChangeNotifier Library (GitHub)](https://github.com/yonat/ContactsChangeNotifier) -- MEDIUM confidence
- [SwiftData vs Core Data 2025 (Multiple Sources)](https://www.hackingwithswift.com/quick-start/swiftdata/swiftdata-vs-core-data) -- MEDIUM confidence
- [iOS 18 Contact Access Button (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10121/) -- HIGH confidence
- [SwiftUI @Observable Macro Guide (Medium)](https://hasanalidev.medium.com/understanding-the-swiftui-observable-macro-a-modern-guide-to-apples-observation-framework-80b052cb0161) -- MEDIUM confidence
- [Dependency Injection in SwiftUI Environment (fatbobman)](https://fatbobman.com/en/posts/swiftui-environment-concepts-and-practice/) -- MEDIUM confidence
- [SwiftData Modeling Relationships (SwiftyPlace)](https://www.swiftyplace.com/blog/modeling-data-in-swiftdata) -- MEDIUM confidence

---
*Architecture research for: Birthday Reminders iOS App*
*Researched: 2026-02-15*
