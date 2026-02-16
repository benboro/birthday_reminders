# Phase 3: Group Management - Research

**Researched:** 2026-02-15
**Domain:** iOS Contacts group management (CNGroup, CNSaveRequest), SwiftData many-to-many relationships, per-group notification scheduling
**Confidence:** HIGH

## Summary

Phase 3 adds group management with bidirectional sync to iOS Contacts. The user creates, renames, and deletes groups inside the app; those changes are written to iOS Contacts via `CNSaveRequest`. Conversely, groups created in iOS Contacts appear in the app after a sync. Contacts can be assigned to and removed from groups, and each group carries a notification preference (day-of, day-before, or both) that the existing `NotificationScheduler` must respect.

The Contacts framework provides a complete CRUD API for groups through `CNMutableGroup` and `CNSaveRequest`. Groups live inside containers (`CNContainer`), and the app should use the default container (`defaultContainerIdentifier()`) for new groups. The key operations are: `saveRequest.add(group, toContainerWithIdentifier:)` for creation, `saveRequest.update(group)` for rename, `saveRequest.delete(group)` for deletion, `saveRequest.addMember(contact, to: group)` and `saveRequest.removeMember(contact, from: group)` for membership changes. All operations are synchronous and executed via `contactStore.execute(saveRequest)`.

On the app side, a new `BirthdayGroup` SwiftData model stores the group's CNGroup identifier, name, and notification preference. The `Person` model gains a many-to-many relationship to `BirthdayGroup`. The `NotificationScheduler.reschedule()` method must be extended to consult each person's group memberships to determine whether to generate day-of, day-before, or both notifications. The 64-notification ceiling logic remains unchanged but the notification type filter is applied before generating requests.

**Primary recommendation:** Build the `BirthdayGroup` SwiftData model with a many-to-many relationship to `Person`, a `GroupSyncService` that wraps CNGroup CRUD operations via `CNSaveRequest`, and extend `NotificationScheduler.reschedule()` to accept per-person notification type preferences derived from group membership. Use `.nullify` delete rule on the relationship so deleting a group does not delete the people in it.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Contacts framework (CNGroup, CNMutableGroup, CNSaveRequest) | iOS 18.0+ | CRUD for groups in iOS Contacts, membership management | Apple's only API for programmatic group management in the system Contacts store |
| SwiftData @Model + @Relationship | iOS 18.0+ | BirthdayGroup model with many-to-many relationship to Person | Already in use from Phase 1; @Relationship with inverse handles join table automatically |
| SwiftUI List + Section | iOS 18.0+ | Group list UI, group picker for assigning contacts | Already in use from Phase 1; consistent with existing app patterns |
| @AppStorage / UserDefaults | iOS 18.0+ | Default notification preference for ungrouped contacts | Already used for notificationHour/notificationMinute in Phase 2 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| os.Logger | iOS 18.0+ | Privacy-safe logging for group operations | All group sync, membership, and error events |
| CNContactStore | iOS 18.0+ | Group and membership fetching, save request execution | Already in use from Phase 1 for contact import |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData BirthdayGroup model | App-only groups (no CNGroup sync) | Would not satisfy GRPS-02 (bidirectional sync with iOS Contacts) |
| CNSaveRequest for each operation | Batch all changes in one save request | Single operations are simpler and safer; batching only needed for bulk membership changes |
| Storing notification preference in Person model | Storing only in BirthdayGroup model | Per-group preference is the requirement (GRPS-03); per-person would bypass the group concept |
| Many-to-many Person<->BirthdayGroup | One-to-many (person in one group only) | Contacts can belong to multiple groups in iOS Contacts; many-to-many matches the system behavior |

**Installation:** No additional dependencies. All frameworks are Apple first-party, already imported in existing code.

## Architecture Patterns

### Recommended Project Structure
```
BirthdayReminders/
+-- Models/
|   +-- Person.swift                   # MODIFIED: add groups relationship
|   +-- BirthdayGroup.swift            # NEW: @Model with CNGroup ID, name, notification pref
|   +-- ContactBridge.swift            # Existing, no changes needed
+-- Services/
|   +-- GroupSyncService.swift         # NEW: CNGroup CRUD via CNSaveRequest
|   +-- ContactSyncService.swift       # MODIFIED: import group memberships during contact sync
|   +-- NotificationScheduler.swift    # MODIFIED: per-group notification type filtering
|   +-- BirthdayCalculator.swift       # Existing, no changes needed
+-- Views/
|   +-- Groups/
|   |   +-- GroupListView.swift        # NEW: list of groups with create/rename/delete
|   |   +-- GroupDetailView.swift      # NEW: members list, notification preference picker
|   |   +-- GroupMemberPickerView.swift # NEW: multi-select contacts to add/remove
|   +-- Settings/
|   |   +-- NotificationSettingsView.swift  # Existing, may add default preference picker
|   +-- BirthdayList/
|       +-- BirthdayListView.swift     # MODIFIED: add groups navigation entry
+-- Extensions/
    +-- Logger+App.swift               # MODIFIED: add .groups category
```

### Pattern 1: BirthdayGroup SwiftData Model
**What:** A SwiftData `@Model` that mirrors a CNGroup with an added notification preference. Stores the CNGroup identifier for bidirectional sync linkage.
**When to use:** For all group persistence in the app.
**Example:**
```swift
import SwiftData

/// Notification preference options for a group.
enum NotificationPreference: String, Codable, CaseIterable {
    case dayOfOnly = "Day of only"
    case dayBeforeOnly = "Day before only"
    case both = "Both"
}

@Model
final class BirthdayGroup {
    /// The CNGroup.identifier from iOS Contacts. Used for bidirectional sync.
    @Attribute(.unique)
    var groupIdentifier: String

    /// Display name, synced from/to CNGroup.name.
    var name: String

    /// Per-group notification preference (GRPS-03).
    var notificationPreference: NotificationPreference

    /// Many-to-many relationship with Person.
    @Relationship(deleteRule: .nullify, inverse: \Person.groups)
    var members: [Person]

    init(groupIdentifier: String, name: String,
         notificationPreference: NotificationPreference = .both) {
        self.groupIdentifier = groupIdentifier
        self.name = name
        self.notificationPreference = notificationPreference
        self.members = []
    }
}
```

### Pattern 2: Person Model Extension for Groups Relationship
**What:** Add a `groups` property to the existing `Person` model to complete the many-to-many relationship.
**When to use:** The inverse side of the BirthdayGroup relationship.
**Example:**
```swift
// Add to existing Person model:
var groups: [BirthdayGroup] = []
```
**Important:** SwiftData handles the join table automatically. The `@Relationship` macro is declared on the BirthdayGroup side with `inverse: \Person.groups`, so Person only needs the bare array property. Provide a default value of `[]` to avoid the iOS 17 many-to-many naming bug (confirmed workaround from Hacking with Swift).

### Pattern 3: GroupSyncService for CNGroup CRUD
**What:** A service that wraps all CNGroup operations through CNSaveRequest. Each operation creates a save request, performs the change, and executes it against CNContactStore.
**When to use:** For all group create/rename/delete/membership operations.
**Example:**
```swift
import Contacts
import os

@MainActor
final class GroupSyncService {
    private let store = CNContactStore()

    /// Create a new group in the default Contacts container.
    func createGroup(name: String) throws -> CNGroup {
        let mutableGroup = CNMutableGroup()
        mutableGroup.name = name
        let saveRequest = CNSaveRequest()
        saveRequest.add(mutableGroup, toContainerWithIdentifier: nil) // nil = default container
        try store.execute(saveRequest)
        Logger.groups.info("Created group: \(name, privacy: .private)")
        // After execute, mutableGroup.identifier is populated
        return mutableGroup
    }

    /// Rename an existing group.
    func renameGroup(_ group: CNGroup, to newName: String) throws {
        let mutableGroup = group.mutableCopy() as! CNMutableGroup
        mutableGroup.name = newName
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableGroup)
        try store.execute(saveRequest)
        Logger.groups.info("Renamed group to: \(newName, privacy: .private)")
    }

    /// Delete a group from iOS Contacts.
    func deleteGroup(_ group: CNGroup) throws {
        let mutableGroup = group.mutableCopy() as! CNMutableGroup
        let saveRequest = CNSaveRequest()
        saveRequest.delete(mutableGroup)
        try store.execute(saveRequest)
        Logger.groups.info("Deleted group: \(group.name, privacy: .private)")
    }

    /// Add a contact to a group.
    func addMember(_ contact: CNContact, to group: CNGroup) throws {
        let saveRequest = CNSaveRequest()
        saveRequest.addMember(contact, to: group)
        try store.execute(saveRequest)
    }

    /// Remove a contact from a group.
    func removeMember(_ contact: CNContact, from group: CNGroup) throws {
        let saveRequest = CNSaveRequest()
        saveRequest.removeMember(contact, from: group)
        try store.execute(saveRequest)
    }

    /// Fetch all groups from all containers.
    func fetchAllGroups() throws -> [CNGroup] {
        return try store.groups(matching: nil)
    }

    /// Fetch contacts in a specific group.
    func fetchContacts(in group: CNGroup) throws -> [CNContact] {
        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
        let keys = ContactBridge.keysToFetch()
        return try store.unifiedContacts(matching: predicate, keysToFetch: keys)
    }
}
```

### Pattern 4: Bidirectional Sync Strategy
**What:** On each sync, fetch all CNGroups from the Contacts store, upsert into SwiftData BirthdayGroup models, and remove stale groups. Also sync membership by checking which Person records belong to which CNGroups via predicates.
**When to use:** During contact import/re-import and on app foreground.
**Example flow:**
```
1. Fetch all CNGroups from CNContactStore
2. For each CNGroup:
   a. Find or create BirthdayGroup by groupIdentifier
   b. Update name if changed
   c. Fetch CNContacts in group via predicateForContactsInGroup
   d. Match to Person records by contactIdentifier
   e. Update BirthdayGroup.members array
3. Remove BirthdayGroup records whose groupIdentifier no longer exists in CNGroups
4. For groups created in-app (already have CNGroup counterpart): already synced
```

### Pattern 5: NotificationScheduler with Per-Group Preferences
**What:** Extend `reschedule()` to accept notification preference information per person, derived from their group memberships. If a person belongs to multiple groups with different preferences, use the most permissive (both > either single).
**When to use:** Every reschedule call.
**Example:**
```swift
/// Determines the effective notification preference for a person
/// based on their group memberships.
/// If ungrouped, defaults to .both. If in multiple groups, uses
/// the most permissive preference.
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
```

### Pattern 6: ModelContainer Schema Update
**What:** The app's `ModelContainer` must include `BirthdayGroup.self` in the schema alongside `Person.self`.
**When to use:** In `BirthdayRemindersApp.swift` init.
**Example:**
```swift
let config = ModelConfiguration(
    "BirthdayReminders",
    schema: Schema([Person.self, BirthdayGroup.self]),
    isStoredInMemoryOnly: false,
    groupContainer: .identifier("group.com.birthdayreminders")
)
container = try ModelContainer(
    for: Person.self, BirthdayGroup.self,
    configurations: config
)
```
**Important:** SwiftData handles lightweight schema migration automatically for additive changes (new model, new properties). Adding `BirthdayGroup` and a new `groups` property to `Person` should auto-migrate without a custom migration plan.

### Anti-Patterns to Avoid
- **Using CNChangeHistoryEvent for bidirectional sync:** The change history API (`changeHistoryFetchResult`) has known Swift compatibility issues -- `currentHistoryToken` returns nil in Swift, and the method requires Objective-C bridging. Too fragile for this use case. Instead, do a full group re-sync on each import/foreground cycle (group counts are small, typically < 50).
- **Creating groups in Exchange or CardDAV containers:** Not all container types support groups reliably. Always use `toContainerWithIdentifier: nil` (default container) for new groups created by the app. The default container is typically the local or iCloud container.
- **Storing notification preference as a raw string in Person:** The preference belongs to the group (GRPS-03), not the person. Putting it on Person breaks when a person is in multiple groups and when the user changes a group's preference.
- **Cascade delete on BirthdayGroup.members:** Deleting a group should NOT delete the people in it. Use `.nullify` delete rule so the relationship is cleared but Person records survive.
- **Repeated individual appends to many-to-many relationship:** SwiftData has severe performance issues with repeated individual `append` calls on relationship arrays (750x slower than Core Data). Always build the full array first and assign it, or use `append(contentsOf:)` for bulk operations.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Group CRUD in iOS Contacts | Direct CNContact property manipulation | CNSaveRequest + CNMutableGroup | CNSaveRequest is the only supported way to modify groups; direct mutation is not persisted |
| Many-to-many join table | Manual intermediate model | SwiftData @Relationship with arrays on both sides | SwiftData manages the join table automatically; manual tables add complexity and bugs |
| Group membership querying | Manual iteration over all contacts checking groups | CNContact.predicateForContactsInGroup(withIdentifier:) | Apple's predicate is optimized and handles unified contacts correctly |
| Schema migration for new model | Custom migration code or database reset | SwiftData automatic lightweight migration | Adding a new model and new optional properties is handled automatically |
| Notification type filtering | Custom notification scheduling logic | Extend existing NotificationScheduler with preference parameter | The 64-slot priority logic already exists; just add a filter step before generating requests |

**Key insight:** The Contacts framework already has full CRUD for groups via CNSaveRequest. The main work is bridging between CNGroup identifiers and SwiftData models, and threading notification preferences through the existing scheduler.

## Common Pitfalls

### Pitfall 1: SwiftData Many-to-Many Performance
**What goes wrong:** Adding members to a group one by one via `group.members.append(person)` in a loop causes O(n^2) behavior. SwiftData compares the entire array state after each append.
**Why it happens:** SwiftData does not track discrete array mutations like Core Data does with NSMutableSet. Each append triggers a full array comparison.
**How to avoid:** Build the complete members array first, then assign it in one operation. For bulk additions, collect all Person records into an array and use `group.members.append(contentsOf: newMembers)` or assign the entire array.
**Warning signs:** Group membership updates taking several seconds for groups with 50+ contacts.

### Pitfall 2: CNGroup Identifier Not Set Until After Execute
**What goes wrong:** Reading `mutableGroup.identifier` before calling `contactStore.execute(saveRequest)` returns an empty string or a temporary identifier.
**Why it happens:** CNSaveRequest defers all writes until `execute()` is called. The identifier is assigned by the Contacts store during execution.
**How to avoid:** Always read the identifier after a successful `execute()` call. Use the returned group object (same reference as the CNMutableGroup) to get the identifier.
**Warning signs:** BirthdayGroup records with empty or mismatched groupIdentifier values.

### Pitfall 3: Group Operations Require Contact Authorization
**What goes wrong:** Attempting to create, modify, or delete groups without `.authorized` or `.limited` contact access throws an error.
**Why it happens:** Group operations use the same CNContactStore permission as contact access. The app already requests this permission in Phase 1 onboarding.
**How to avoid:** Check `ContactSyncService.authState` before performing any group operations. The app already gates on authorization for contact import; apply the same check for group operations.
**Warning signs:** Crashes or silent failures when the user has revoked contact permission between app sessions.

### Pitfall 4: Stale CNGroup References After Sync
**What goes wrong:** Holding a CNGroup reference across multiple CNContactStore operations can cause stale data. A group renamed in iOS Contacts between the time it was fetched and when a membership operation is attempted may fail.
**Why it happens:** CNGroup objects are snapshots, not live references to the Contacts database.
**How to avoid:** Re-fetch the CNGroup by identifier immediately before performing mutation operations (rename, delete, add/remove member). For most operations, the freshness window is short enough that this is only needed for operations triggered by user action, not during a full sync pass.
**Warning signs:** Intermittent "record not found" errors during group membership changes.

### Pitfall 5: Default Container May Not Be Local
**What goes wrong:** `defaultContainerIdentifier()` returns the iCloud container if the user's default account is iCloud. Groups created there sync to iCloud, which is fine. But if the user switches their default account, previously created groups may appear to vanish from a different container context.
**Why it happens:** iOS supports multiple contact containers (local, iCloud, Exchange, CardDAV). The default container is user-configured.
**How to avoid:** Always use `toContainerWithIdentifier: nil` (which resolves to the default container) for new groups. When fetching groups, pass `nil` predicate to `groups(matching:)` to get groups from ALL containers, not just the default. Store the `groupIdentifier` in SwiftData which is stable across container changes.
**Warning signs:** Groups disappearing after the user changes their default Contacts account in iOS Settings.

### Pitfall 6: Ungrouped Contacts Need a Default Notification Preference
**What goes wrong:** Contacts not in any group receive no notifications because the scheduler only considers per-group preferences.
**Why it happens:** The scheduler filters by group preference, but ungrouped contacts have no group and therefore no preference.
**How to avoid:** Define a clear default: ungrouped contacts use "both" (day-of and day-before), matching the current Phase 2 behavior. This ensures backward compatibility -- before Phase 3, all contacts are effectively ungrouped.
**Warning signs:** After Phase 3 is deployed, users who never create groups find their notifications have stopped.

### Pitfall 7: Deleting a CNGroup Does Not Delete Its Members
**What goes wrong:** Developer assumes deleting a group via CNSaveRequest also removes contacts from the Contacts store. It does not -- only the group association is removed.
**Why it happens:** Groups are organizational, not ownership containers. Contacts exist independently of groups.
**How to avoid:** This is actually the correct behavior and matches the SwiftData `.nullify` delete rule. When deleting a BirthdayGroup, also call `saveRequest.delete(mutableGroup)` to remove it from iOS Contacts. Person records remain intact in both stores.
**Warning signs:** None -- this is expected behavior. The pitfall is only if you expect members to be deleted.

## Code Examples

Verified patterns from official sources and community references:

### Creating a Group and Syncing to SwiftData
```swift
// Source: Apple CNSaveRequest docs + react-native-unified-contacts reference
func createGroupInBothStores(name: String, context: ModelContext) throws {
    // 1. Create in iOS Contacts
    let mutableGroup = CNMutableGroup()
    mutableGroup.name = name
    let saveRequest = CNSaveRequest()
    saveRequest.add(mutableGroup, toContainerWithIdentifier: nil)
    try store.execute(saveRequest)

    // 2. Create in SwiftData
    let birthdayGroup = BirthdayGroup(
        groupIdentifier: mutableGroup.identifier,
        name: name,
        notificationPreference: .both
    )
    context.insert(birthdayGroup)
    try context.save()
}
```

### Fetching All Groups and Syncing to SwiftData
```swift
// Source: Apple CNContactStore.groups(matching:) docs
func syncGroupsFromContacts(context: ModelContext) throws {
    let cnGroups = try store.groups(matching: nil) // nil = all containers

    var seenIdentifiers = Set<String>()
    for cnGroup in cnGroups {
        seenIdentifiers.insert(cnGroup.identifier)
        let identifier = cnGroup.identifier
        let descriptor = FetchDescriptor<BirthdayGroup>(
            predicate: #Predicate { $0.groupIdentifier == identifier }
        )
        if let existing = try context.fetch(descriptor).first {
            // Update name if changed
            if existing.name != cnGroup.name {
                existing.name = cnGroup.name
            }
        } else {
            // New group from iOS Contacts -- create in SwiftData
            let newGroup = BirthdayGroup(
                groupIdentifier: cnGroup.identifier,
                name: cnGroup.name
            )
            context.insert(newGroup)
        }
    }

    // Remove stale groups
    let allGroups = try context.fetch(FetchDescriptor<BirthdayGroup>())
    for group in allGroups {
        if !seenIdentifiers.contains(group.groupIdentifier) {
            context.delete(group)
        }
    }
}
```

### Syncing Group Membership
```swift
// Source: Apple CNContact.predicateForContactsInGroup(withIdentifier:) docs
func syncMembership(for birthdayGroup: BirthdayGroup, context: ModelContext) throws {
    let predicate = CNContact.predicateForContactsInGroup(
        withIdentifier: birthdayGroup.groupIdentifier
    )
    let keys = ContactBridge.keysToFetch()
    let cnContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)

    let memberIdentifiers = Set(cnContacts.map(\.identifier))

    // Fetch all Person records that should be members
    let allPeople = try context.fetch(FetchDescriptor<Person>())
    let members = allPeople.filter { memberIdentifiers.contains($0.contactIdentifier) }

    // Assign in one operation (avoid repeated appends)
    birthdayGroup.members = members
}
```

### NotificationScheduler Extension for Group Preferences
```swift
// Source: Extension of existing NotificationScheduler pattern from Phase 2
func reschedule(
    people: [Person],
    deliveryHour: Int = 9,
    deliveryMinute: Int = 0
) async {
    center.removeAllPendingNotificationRequests()

    let status = await checkStatus()
    guard status == .authorized || status == .provisional else { return }

    let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }

    var requests: [UNNotificationRequest] = []
    for person in sorted {
        if requests.count >= 64 { break }

        let preference = effectivePreference(for: person)

        // Day-before notification (fires earlier, scheduled first per Phase 2 decision)
        if preference == .dayBeforeOnly || preference == .both {
            if let dayBefore = makeRequest(person: person, offsetDays: -1,
                                           hour: deliveryHour, minute: deliveryMinute) {
                requests.append(dayBefore)
            }
        }

        if requests.count >= 64 { break }

        // Day-of notification
        if preference == .dayOfOnly || preference == .both {
            if let dayOf = makeRequest(person: person, offsetDays: 0,
                                       hour: deliveryHour, minute: deliveryMinute) {
                requests.append(dayOf)
            }
        }
    }

    for request in requests {
        do {
            try await center.add(request)
        } catch {
            Logger.notifications.error("Failed to schedule: \(error.localizedDescription)")
        }
    }

    Logger.notifications.info("Scheduled \(requests.count) notifications for \(people.count) contacts")
}
```

### Notification Preference Picker UI
```swift
// Source: Standard SwiftUI Picker pattern
struct GroupNotificationPreferencePicker: View {
    @Bindable var group: BirthdayGroup

    var body: some View {
        Picker("Notifications", selection: $group.notificationPreference) {
            ForEach(NotificationPreference.allCases, id: \.self) { pref in
                Text(pref.rawValue).tag(pref)
            }
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ABAddressBook group APIs (C-based) | CNContactStore + CNSaveRequest (Objective-C/Swift) | iOS 9 (2015) | ABAddressBook fully deprecated; CNContactStore is the only supported API |
| Core Data for local models | SwiftData @Model with @Relationship | iOS 17 (2023), improved iOS 18 | Automatic join tables for many-to-many, lightweight migration |
| Manual join table for many-to-many | SwiftData array properties on both sides | iOS 17 (2023) | SwiftData generates and manages the join table; no manual model needed |
| CNChangeHistoryEvent for change tracking | CNContactStoreDidChange notification + full re-sync | Ongoing | Change history API has Swift compatibility issues (nil token, requires ObjC bridge); full re-sync is more reliable for small datasets |

**Deprecated/outdated:**
- `ABAddressBook` and `ABGroup`: Fully deprecated since iOS 9. All group management must use `CNContactStore` and `CNSaveRequest`.
- `CNChangeHistoryFetchRequest` from Swift: Has known bugs with `currentHistoryToken` returning nil in Swift. Avoid unless using Objective-C bridge.

## Open Questions

1. **Handling contacts in multiple groups with conflicting notification preferences**
   - What we know: A person can belong to multiple groups. Each group has its own notification preference. The requirement (GRPS-03) says "per group" but does not specify conflict resolution.
   - What's unclear: Whether the user expects the most permissive preference to win, or the most restrictive, or explicit per-contact override.
   - Recommendation: Use most-permissive wins (if any group says "both", the person gets both notifications). This is the safest default -- it never silently drops a notification. Document this behavior in the UI. Can be refined later without data model changes.

2. **Whether to show iOS Contacts groups the user did not create in the app**
   - What we know: `store.groups(matching: nil)` returns ALL groups from all containers, including those the user created in iOS Contacts directly.
   - What's unclear: Whether the user expects to see and manage notification preferences for pre-existing iOS Contacts groups.
   - Recommendation: Yes, show all groups. Bidirectional sync (GRPS-02) means groups from iOS Contacts should appear in the app. Default their notification preference to `.both` on first import. The user can then customize.

3. **Whether group sync should happen automatically on foreground or only on manual re-import**
   - What we know: Phase 1 established "manual re-import" as the pattern per user decision. Contact sync only happens when the user taps re-import.
   - What's unclear: Whether groups should follow the same manual pattern or sync more frequently.
   - Recommendation: Sync groups during the same manual re-import operation. When the user taps "Re-import Contacts" in Settings, also sync groups. Additionally, sync groups on first app launch after Phase 3 deployment to pick up any pre-existing groups. Do not add automatic background sync -- it would contradict the Phase 1 manual-import decision.

4. **SwiftData automatic migration for adding BirthdayGroup model**
   - What we know: SwiftData supports automatic lightweight migration for additive changes (new models, new optional properties). Adding `BirthdayGroup` and a new `groups: [BirthdayGroup] = []` property to `Person` should qualify.
   - What's unclear: Whether the many-to-many relationship join table is created automatically during lightweight migration.
   - Recommendation: Test on a device with existing Phase 2 data. If automatic migration fails, use a `VersionedSchema` and `SchemaMigrationPlan`. This is a LOW risk given SwiftData's documented behavior for additive changes.

## Sources

### Primary (HIGH confidence)
- [Apple: CNSaveRequest Documentation](https://developer.apple.com/documentation/contacts/cnsaverequest) -- Group CRUD methods: add, update, delete, addMember, removeMember
- [Apple: CNGroup Documentation](https://developer.apple.com/documentation/contacts/cngroup) -- Immutable group object with identifier and name
- [Apple: CNMutableGroup Documentation](https://developer.apple.com/documentation/contacts/cnmutablegroup) -- Mutable copy for group modifications
- [Apple: CNContact.predicateForContactsInGroup(withIdentifier:)](https://developer.apple.com/documentation/contacts/cncontact/predicateforcontactsingroup(withidentifier:)) -- Predicate for fetching contacts in a group
- [Apple: CNContactStore.groups(matching:)](https://developer.apple.com/documentation/contacts/cncontactstore/1403121-groups) -- Fetch groups with optional predicate
- [Apple: SwiftData @Relationship](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) -- Delete rules, inverse specification, cascade vs nullify
- [Hacking with Swift: Many-to-many relationships in SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-many-to-many-relationships) -- @Relationship with inverse, default value workaround for iOS 17 bug

### Secondary (MEDIUM confidence)
- [react-native-unified-contacts (GitHub)](https://github.com/joshuapinter/react-native-unified-contacts) -- Verified CNSaveRequest patterns for group CRUD and membership in production code
- [fatbobman: Relationships in SwiftData](https://fatbobman.com/en/posts/relationships-in-swiftdata-changes-and-considerations/) -- Performance issues with many-to-many appends (750x slower), inverse relationship requirements
- [Apple Developer Forums: CNChangeHistoryEvent](https://developer.apple.com/forums/thread/696387) -- Change history API Swift compatibility issues, currentHistoryToken nil bug

### Tertiary (LOW confidence)
- Whether `defaultContainerIdentifier()` behavior changes when user switches between iCloud and local Contacts accounts -- observed behavior, not documented edge case
- Whether SwiftData automatic migration handles many-to-many join table creation for existing databases -- inferred from additive migration documentation, needs runtime validation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All Apple first-party frameworks; CNSaveRequest group API is stable since iOS 9, SwiftData relationships documented for iOS 18
- Architecture: HIGH -- BirthdayGroup model + GroupSyncService follows same patterns established in Phase 1 (Person + ContactBridge + ContactSyncService)
- Notification preference integration: HIGH -- Extension of existing NotificationScheduler is straightforward; 64-slot logic unchanged
- Bidirectional sync: MEDIUM -- Full re-sync approach is reliable but not real-time; CNChangeHistoryEvent issues documented but workaround (full re-sync) is proven
- Pitfalls: HIGH -- SwiftData many-to-many performance issues and CNGroup identifier timing verified by multiple sources

**Research date:** 2026-02-15
**Valid until:** 2026-03-15 (stable domain -- Contacts framework and SwiftData relationships change slowly)
