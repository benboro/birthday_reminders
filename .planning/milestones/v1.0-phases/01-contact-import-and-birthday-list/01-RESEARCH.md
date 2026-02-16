# Phase 1: Contact Import and Birthday List - Research

**Researched:** 2026-02-15
**Domain:** SwiftUI contact import, birthday list display, SwiftData persistence, iOS Data Protection, zero-network enforcement
**Confidence:** HIGH

## Summary

Phase 1 establishes the entire data foundation, UI shell, and security posture of the app. The user opens the app, goes through a guided onboarding that requests contact permission, imports all contacts with birthdays, and browses them in a sectioned list (today, this week, this month, later) with search and a detail view. All data is stored in SwiftData with iOS Data Protection encryption at rest. The app makes zero network requests and includes zero third-party code.

The core technical challenges are: (1) correctly modeling birthday data in SwiftData -- DateComponents cannot be stored directly and must be decomposed into primitive fields; (2) handling the full spectrum of CNAuthorizationStatus values including the iOS 18 `.limited` case; (3) computing "next birthday" correctly for Feb 29 birthdays and contacts with non-Gregorian birthdays; (4) configuring the SwiftData ModelContainer with an App Group from day one so widget data sharing in Phase 4 does not require a painful migration; and (5) enforcing the security constraints (encryption at rest, zero network, no PII in logs) as foundational guardrails rather than afterthoughts.

**Primary recommendation:** Build the SwiftData models and BirthdayCalculator first (pure logic, highly testable), then the ContactSyncService, then the UI layer. Configure the App Group container and Data Protection entitlement at project creation time, not later.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Manual re-import -- user taps a button to refresh from Contacts when they choose (no continuous sync)
- Guided onboarding on first launch -- welcome screen explaining the app, then permission request, then import
- Contacts without birthdays are silently ignored -- only contacts with birthdays appear
- Permission denied: show a friendly explanation of why access is needed and offer to open Settings
- Minimal rows: name + date + days until -- no photos, no age
- Today's birthdays get a highlighted row (distinct background color or accent) to stand out
- Search bar always visible at the top of the list
- Detail view basics only: name, birthday date, days until -- no age, no zodiac
- Read-only detail view -- no quick actions (call, message)
- "Open in Contacts" link so user can edit the birthday in iOS Contacts as the single source of truth
- iOS-native feel -- system fonts, standard controls, familiar Apple patterns
- Light and dark mode, following the system setting
- System blue accent color -- default iOS tint
- Single screen with navigation bar (no tab bar) -- settings accessible via gear icon

### Claude's Discretion
- Section header styling (sticky vs inline)
- Detail view transition (push vs sheet)
- Loading states and progress indicators during import
- Exact spacing, typography, and layout details
- Error state handling

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 18+ | UI framework | Declarative, deeply integrated with SwiftData @Query. Handles light/dark mode, system fonts, and standard controls natively. |
| SwiftData | iOS 18+ | Local persistence | @Model macro, #Unique for contact deduplication during re-import, #Index for fast upcoming-birthday queries. Backed by SQLite with iOS Data Protection. |
| Contacts framework | iOS 9+ (targeting 18+) | Read contacts | CNContactStore for authorization and enumeration. CNContact.birthday and CNContact.nonGregorianBirthday for birthday data. |
| Observation framework | iOS 17+ | Reactive state | @Observable macro for ContactSyncService and view models. Granular property tracking, only re-renders views that read changed properties. |
| Foundation Calendar | Built-in | Date math | Calendar, DateComponents for birthday calculation, non-Gregorian conversion, Feb 29 handling. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ContactsUI | iOS 18+ | Open contact in Contacts | CNContactViewController via UIViewControllerRepresentable for "Open in Contacts" link in detail view. |
| os.Logger | iOS 14+ | Privacy-safe logging | Use with `privacy: .private` for any contact-related data. Prevents PII leaking to system logs or crash reports. |
| Swift Testing | Xcode 16+ | Unit tests | @Test macro for BirthdayCalculator, ContactBridge, and model logic. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData | Core Data | Core Data requires NSManagedObject subclasses, .xcdatamodeld files. SwiftData is strictly superior for greenfield iOS 18+ apps. |
| Decomposed Int fields for birthday | DateComponents directly in @Model | DateComponents is a complex Foundation type that can cause SwiftData storage issues. Decomposing to month/day/year Ints is safer and more predictable. |
| CNContactViewController (UIKit bridge) | Custom detail view only | The "Open in Contacts" requirement needs UIKit bridge. No pure SwiftUI equivalent exists for opening a contact in the system Contacts app. |

**Installation:**
```swift
// Zero third-party dependencies. All frameworks are Apple first-party:
import SwiftUI
import SwiftData
import Contacts
import ContactsUI
import os
```

## Architecture Patterns

### Recommended Project Structure (Phase 1 scope)

```
BirthdayReminders/
+-- App/
|   +-- BirthdayRemindersApp.swift     # @main, ModelContainer with App Group
+-- Models/
|   +-- Person.swift                   # @Model: contact with birthday
|   +-- ContactBridge.swift            # Maps CNContact -> Person (stateless)
+-- Services/
|   +-- ContactSyncService.swift       # CNContactStore wrapper, auth + fetch
|   +-- BirthdayCalculator.swift       # Pure functions: next birthday, days until
+-- Views/
|   +-- Onboarding/
|   |   +-- WelcomeView.swift          # First-launch welcome + explanation
|   |   +-- PermissionRequestView.swift # Contact permission with explanation
|   +-- BirthdayList/
|   |   +-- BirthdayListView.swift     # Main list with sections + search
|   |   +-- BirthdayRowView.swift      # Single row: name, date, days until
|   |   +-- BirthdaySectionView.swift  # Section headers (today/week/month/later)
|   |   +-- BirthdayDetailView.swift   # Detail: name, date, days until, open in contacts
|   +-- Components/
|       +-- EmptyStateView.swift       # No birthdays found guidance
|       +-- SettingsPlaceholderView.swift # Gear icon destination (stub for Phase 2)
+-- Extensions/
|   +-- Date+Birthday.swift            # Date helpers
+-- ContactsUIBridge/
|   +-- ContactDetailBridge.swift      # UIViewControllerRepresentable for CNContactViewController
+-- Resources/
    +-- Assets.xcassets                # App icon, accent color
```

### Pattern 1: SwiftData Person Model with Decomposed Birthday

**What:** Store birthday as separate Int fields instead of DateComponents. SwiftData handles Int properties natively and reliably.
**When to use:** Always for this app. DateComponents is a complex Foundation type that can cause SwiftData storage issues.

```swift
// Source: SwiftData documentation + fatbobman Codable analysis
import SwiftData

@Model
final class Person {
    // Identity
    @Attribute(.unique)
    var contactIdentifier: String

    // Display
    var firstName: String
    var lastName: String

    // Birthday (decomposed from DateComponents)
    var birthdayMonth: Int       // 1-12
    var birthdayDay: Int         // 1-31
    var birthdayYear: Int?       // nil when contact has no year
    var birthdayCalendarId: String?  // nil = Gregorian, otherwise calendar identifier

    // Computed for sorting/display
    var nextBirthdayDate: Date {
        BirthdayCalculator.nextBirthday(month: birthdayMonth, day: birthdayDay)
    }

    var daysUntilBirthday: Int {
        BirthdayCalculator.daysUntil(month: birthdayMonth, day: birthdayDay)
    }

    var displayName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    init(contactIdentifier: String, firstName: String, lastName: String,
         birthdayMonth: Int, birthdayDay: Int, birthdayYear: Int? = nil,
         birthdayCalendarId: String? = nil) {
        self.contactIdentifier = contactIdentifier
        self.firstName = firstName
        self.lastName = lastName
        self.birthdayMonth = birthdayMonth
        self.birthdayDay = birthdayDay
        self.birthdayYear = birthdayYear
        self.birthdayCalendarId = birthdayCalendarId
    }
}
```

**Important:** `nextBirthdayDate` and `daysUntilBirthday` are computed properties. SwiftData cannot index or sort by computed properties. For the @Query sort, store a persisted `nextBirthdayDate` that gets recalculated on import and on each day rollover, or sort in-memory after fetching.

### Pattern 2: ModelContainer with App Group (Day One)

**What:** Configure the SwiftData ModelContainer to use a shared App Group container from the very first build, even though widgets ship in Phase 4.
**When to use:** At project creation. Migrating the database location later is painful.

```swift
// Source: Apple ModelConfiguration docs + Hacking with Swift
import SwiftData

@main
struct BirthdayRemindersApp: App {
    let container: ModelContainer

    init() {
        let config = ModelConfiguration(
            "BirthdayReminders",
            schema: Schema([Person.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.yourname.birthdayreminders")
        )
        do {
            container = try ModelContainer(for: Person.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

**Xcode setup required:**
1. Add "App Groups" capability to the main app target
2. Create group identifier: `group.com.yourname.birthdayreminders`
3. When widget target is added in Phase 4, add the same App Group to that target
4. SwiftData automatically copies existing data to the group container if the app transitions from non-group to group storage

### Pattern 3: ContactSyncService with Full Authorization Handling

**What:** @Observable service wrapping CNContactStore that handles all five authorization states.
**When to use:** For all contact operations.

```swift
// Source: Apple CNContactStore docs + WWDC24 Contact Access Button session
import Contacts
import Observation

enum ContactAuthState {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}

@Observable
@MainActor
final class ContactSyncService {
    private(set) var authState: ContactAuthState = .notDetermined
    private(set) var isImporting = false
    private(set) var importedCount = 0
    private(set) var error: Error?

    private let store = CNContactStore()

    func checkAuthorizationStatus() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined: authState = .notDetermined
        case .authorized:    authState = .authorized
        case .limited:       authState = .limited
        case .denied:        authState = .denied
        case .restricted:    authState = .restricted
        @unknown default:    authState = .denied
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            checkAuthorizationStatus()
            return granted
        } catch {
            self.error = error
            checkAuthorizationStatus()
            return false
        }
    }

    func importContacts(into context: ModelContext) async {
        isImporting = true
        importedCount = 0
        defer { isImporting = false }

        let keys: [CNKeyDescriptor] = ContactBridge.keysToFetch()
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        // Run on background -- enumerateContacts is synchronous
        let contacts = await Task.detached { [store] in
            var result: [CNContact] = []
            try? store.enumerateContacts(with: request) { contact, _ in
                // Filter: only contacts WITH a birthday
                if contact.birthday != nil || contact.nonGregorianBirthday != nil {
                    result.append(contact)
                }
            }
            return result
        }.value

        // Upsert into SwiftData on main actor
        for cnContact in contacts {
            ContactBridge.upsert(from: cnContact, into: context)
            importedCount += 1
        }

        // Remove contacts no longer in the Contacts store
        ContactBridge.removeStale(
            knownIdentifiers: Set(contacts.map(\.identifier)),
            context: context
        )

        try? context.save()
    }
}
```

### Pattern 4: ContactBridge with Centralized keysToFetch

**What:** Stateless mapper with a single canonical list of CNContact keys. Prevents CNPropertyNotFetchedException crashes.
**When to use:** Every contact import operation. The bridge is the single source of truth for field mapping.

```swift
// Source: Apple CNContact docs + CNPropertyNotFetchedException prevention
import Contacts
import SwiftData

struct ContactBridge {
    /// Single canonical list of all CNContact keys the app needs.
    /// Adding a new property access without updating this list will crash.
    static func keysToFetch() -> [CNKeyDescriptor] {
        [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactNonGregorianBirthdayKey as CNKeyDescriptor,
            // Required for "Open in Contacts" via CNContactViewController
            CNContactViewController.descriptorForRequiredKeys(),
        ]
    }

    /// Upsert: create or update a Person from a CNContact
    static func upsert(from contact: CNContact, into context: ModelContext) {
        // Resolve birthday: prefer Gregorian, fall back to nonGregorian
        guard let (month, day, year, calendarId) = resolveBirthday(from: contact) else {
            return // No birthday at all -- skip
        }

        // Fetch existing by contactIdentifier
        let identifier = contact.identifier
        let descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { $0.contactIdentifier == identifier }
        )

        if let existing = try? context.fetch(descriptor).first {
            // Update existing
            existing.firstName = contact.givenName
            existing.lastName = contact.familyName
            existing.birthdayMonth = month
            existing.birthdayDay = day
            existing.birthdayYear = year
            existing.birthdayCalendarId = calendarId
        } else {
            // Insert new
            let person = Person(
                contactIdentifier: identifier,
                firstName: contact.givenName,
                lastName: contact.familyName,
                birthdayMonth: month,
                birthdayDay: day,
                birthdayYear: year,
                birthdayCalendarId: calendarId
            )
            context.insert(person)
        }
    }

    /// Resolve birthday from Gregorian or non-Gregorian sources
    static func resolveBirthday(from contact: CNContact) -> (month: Int, day: Int, year: Int?, calendarId: String?)? {
        // Prefer Gregorian birthday
        if let bday = contact.birthday, let month = bday.month, let day = bday.day {
            return (month, day, bday.year, nil)
        }

        // Fall back to non-Gregorian birthday, convert to Gregorian
        if let ngBday = contact.nonGregorianBirthday,
           let calendar = ngBday.calendar,
           let date = calendar.date(from: ngBday) {
            let gregorian = Calendar(identifier: .gregorian)
            let components = gregorian.dateComponents([.month, .day, .year], from: date)
            if let month = components.month, let day = components.day {
                return (month, day, components.year, calendar.identifier.debugDescription)
            }
        }

        return nil
    }

    /// Remove Person records whose contactIdentifier is no longer in the Contacts store
    static func removeStale(knownIdentifiers: Set<String>, context: ModelContext) {
        let descriptor = FetchDescriptor<Person>()
        guard let allPeople = try? context.fetch(descriptor) else { return }
        for person in allPeople {
            if !knownIdentifiers.contains(person.contactIdentifier) {
                context.delete(person)
            }
        }
    }
}
```

### Pattern 5: BirthdayCalculator (Pure Logic, No Dependencies)

**What:** Stateless pure functions for all date math. Handles nil year, Feb 29, and non-Gregorian converted dates.
**When to use:** For display (days until, next birthday date) and later for notification scheduling.

```swift
// Source: Foundation Calendar documentation
import Foundation

enum BirthdayCalculator {
    /// Calculate the next occurrence of a birthday from today.
    /// For Feb 29 in non-leap years: returns March 1.
    static func nextBirthday(month: Int, day: Int, from referenceDate: Date = .now) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let currentYear = calendar.component(.year, from: today)

        // Try this year first
        var components = DateComponents(year: currentYear, month: month, day: day)

        // Handle Feb 29 in non-leap years
        if month == 2 && day == 29 {
            let range = calendar.range(of: .day, in: .month,
                                       for: calendar.date(from: DateComponents(year: currentYear, month: 2, day: 1))!)!
            if !range.contains(29) {
                // Non-leap year: use March 1
                components = DateComponents(year: currentYear, month: 3, day: 1)
            }
        }

        if let thisYear = calendar.date(from: components), thisYear >= today {
            return thisYear
        }

        // Otherwise next year
        components.year = currentYear + 1

        // Re-check Feb 29 for next year
        if month == 2 && day == 29 {
            let range = calendar.range(of: .day, in: .month,
                                       for: calendar.date(from: DateComponents(year: currentYear + 1, month: 2, day: 1))!)!
            if !range.contains(29) {
                components = DateComponents(year: currentYear + 1, month: 3, day: 1)
            }
        }

        return calendar.date(from: components) ?? today
    }

    /// Days until the next birthday occurrence.
    static func daysUntil(month: Int, day: Int, from referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let next = nextBirthday(month: month, day: day, from: referenceDate)
        return calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    /// Format the birthday for display. Returns "March 15" or "March 15, 1990" if year known.
    static func formattedBirthday(month: Int, day: Int, year: Int?) -> String {
        var components = DateComponents(month: month, day: day)
        components.year = year ?? 2000 // Placeholder year for formatting
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return "" }

        let formatter = DateFormatter()
        if year != nil {
            formatter.dateFormat = "MMMM d, yyyy"
        } else {
            formatter.dateFormat = "MMMM d"
        }
        return formatter.string(from: date)
    }

    /// Categorize into sections: today, this week, this month, later
    static func section(for daysUntil: Int) -> BirthdaySection {
        switch daysUntil {
        case 0: return .today
        case 1...7: return .thisWeek
        case 8...30: return .thisMonth
        default: return .later
        }
    }
}

enum BirthdaySection: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case later = "Later"

    var id: String { rawValue }
}
```

### Pattern 6: Always-Visible Search Bar with Sections

**What:** Use `.searchable` with `.navigationBarDrawer(displayMode: .always)` to keep search pinned.
**When to use:** Main birthday list.

```swift
// Source: SwiftUI searchable documentation + Sarunw tutorial
import SwiftUI
import SwiftData

struct BirthdayListView: View {
    @Query(sort: \Person.birthdayMonth, order: .forward) private var allPeople: [Person]
    @State private var searchText = ""

    private var filteredPeople: [Person] {
        if searchText.isEmpty { return Array(allPeople) }
        return allPeople.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sections: [(BirthdaySection, [Person])] {
        let grouped = Dictionary(grouping: filteredPeople) { person in
            BirthdayCalculator.section(for: person.daysUntilBirthday)
        }
        return BirthdaySection.allCases.compactMap { section in
            guard let people = grouped[section], !people.isEmpty else { return nil }
            let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
            return (section, sorted)
        }
    }

    var body: some View {
        List {
            ForEach(sections, id: \.0) { section, people in
                Section(section.rawValue) {
                    ForEach(people) { person in
                        NavigationLink(value: person) {
                            BirthdayRowView(person: person)
                        }
                    }
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search contacts"
        )
    }
}
```

### Anti-Patterns to Avoid

- **Storing DateComponents directly in @Model:** SwiftData decomposes Codable types into composite attributes. DateComponents is a complex Foundation type with internal state that can cause "Unexpected property within Persisted Struct/Enum" errors. Decompose into primitive Int fields instead.
- **Sorting @Query by computed properties:** @Query sort descriptors only work on persisted properties, not computed ones. Either store a persisted nextBirthdayDate field and update it on import, or fetch all and sort in-memory.
- **Scattering CNContact key lists:** Every access to a CNContact property not in keysToFetch causes an uncatchable Objective-C crash (CNPropertyNotFetchedException). Centralize in ContactBridge.keysToFetch() and never access CNContact properties elsewhere.
- **Fetching contacts on the main thread:** CNContactStore.enumerateContacts is synchronous and blocks. Always run in Task.detached or a nonisolated function.
- **Ignoring .limited authorization:** iOS 18 users can grant access to a subset of contacts. Treating .limited the same as .denied breaks the app for those users.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contact deduplication during re-import | Custom duplicate detection logic | SwiftData #Unique on contactIdentifier | #Unique handles upsert automatically -- insert if new, update if exists |
| Encrypted local storage | Custom SQLite encryption or custom crypto | iOS Data Protection entitlement + SwiftData | Apple's hardware-backed encryption is far more secure than any app-level solution |
| Search filtering | Custom search index or SQLite FTS | SwiftUI .searchable + in-memory filter | For < 10,000 contacts, in-memory string matching is instant and simpler |
| Light/dark mode theming | Custom color scheme management | SwiftUI system colors + .preferredColorScheme | System colors adapt automatically. Zero custom code needed. |
| Contact permission UI | Custom permission explanation | System prompt + pre-permission screen | Apple requires the system prompt. A pre-permission screen before it explains context. |
| Opening a contact in Contacts app | Custom URL scheme / deep link | CNContactViewController via UIViewControllerRepresentable | The only Apple-supported way to view/edit a contact in the system Contacts UI from another app |

**Key insight:** Phase 1 is about wiring together Apple frameworks correctly, not building custom solutions. Every component has a first-party answer.

## Common Pitfalls

### Pitfall 1: DateComponents with Nil Year

**What goes wrong:** CNContact.birthday is `DateComponents?` where `.year` can be nil (common for iCloud contacts stored without a birth year). Force-unwrapping `.year` crashes the app. Using `.year` to calculate age produces "Age: -2025" or similar nonsense.
**Why it happens:** iOS explicitly supports yearless birthdays. Many users store birthdays as "March 15" with no year.
**How to avoid:** Model birthdayYear as `Int?`. Display "March 15" when year is nil. Never compute age when year is nil. The user decision says "no age" in the display, which sidesteps this for Phase 1, but the data layer must still handle nil years correctly for future phases.
**Warning signs:** Crash reports from DateComponents force-unwrapping. Tests that only use contacts with complete dates.

### Pitfall 2: February 29 Birthday in Non-Leap Years

**What goes wrong:** A UNCalendarNotificationTrigger with month=2, day=29 simply does not fire in non-leap years. The iOS Calendar app itself has this bug -- Feb 29 birthdays are missing in non-leap years.
**Why it happens:** The calendar date February 29 does not exist in non-leap years.
**How to avoid:** Adopt a policy: in non-leap years, show Feb 29 birthdays on March 1. BirthdayCalculator.nextBirthday() must implement this. Document the policy in code comments. Apply consistently to display, sorting, and future notification scheduling.
**Warning signs:** Feb 29 contacts showing "365 days until" in late February of a non-leap year.

### Pitfall 3: Non-Gregorian Birthday Omission

**What goes wrong:** Contacts whose birthday is stored only in `nonGregorianBirthday` (Chinese lunar, Hebrew, Islamic calendars) get no birthday in the app. They are silently skipped.
**Why it happens:** Developers only check `contact.birthday` and forget `contact.nonGregorianBirthday` exists.
**How to avoid:** ContactBridge.resolveBirthday() must check BOTH properties. Prefer Gregorian; fall back to non-Gregorian with calendar conversion. Include `CNContactNonGregorianBirthdayKey` in keysToFetch.
**Warning signs:** Users from Chinese, Hebrew, or Islamic calendar regions report missing contacts.

### Pitfall 4: CNPropertyNotFetchedException (Uncatchable Crash)

**What goes wrong:** Accessing any CNContact property not in keysToFetch throws an Objective-C exception that bypasses Swift's do/catch. The app crashes with no way to recover.
**Why it happens:** CNContact uses "partial contacts" as a performance optimization. Only requested keys are populated.
**How to avoid:** Centralize ALL contact property access through ContactBridge. Define keysToFetch() as the single source of truth. Never access CNContact properties directly in views or other code. Write a unit test that verifies keysToFetch covers all accessed properties.
**Warning signs:** Sporadic crashes when opening contact details. Works for some contacts but not others (the ones where the code path hits an unfetched property).

### Pitfall 5: iOS 18 Limited Contacts Access

**What goes wrong:** User grants "limited" access and only 5 of their 200 contacts appear. The app looks broken.
**Why it happens:** iOS 18 introduced `.limited` authorization where users select a subset of contacts. Code that only checks for `.authorized` vs `.denied` misses this state entirely.
**How to avoid:** Handle all five states: `.notDetermined`, `.authorized`, `.limited`, `.denied`, `.restricted`. For `.limited`, the app works normally with the subset the user selected. Show a note like "Showing X contacts. Tap to share more." In Phase 1, handle gracefully. The ContactAccessButton for incremental additions is a v2 feature per REQUIREMENTS.md (IMPT-04).
**Warning signs:** QA only ever grants full access, so the limited path is never tested.

### Pitfall 6: App Group Not Configured From Day One

**What goes wrong:** The SwiftData database is created in the default app sandbox location. When Phase 4 (widgets) needs a shared container, the database must be migrated. SwiftData can auto-copy to a group container, but edge cases around WAL files and concurrent access during migration cause data loss.
**Why it happens:** Developers skip App Group configuration in Phase 1 because widgets are "later." But the database location is set at first launch.
**How to avoid:** Configure `ModelConfiguration(groupContainer: .identifier("group.com.yourname.birthdayreminders"))` from the very first build. Add the App Groups entitlement to the Xcode project at creation time. The cost is zero -- a single entitlement and one parameter.
**Warning signs:** None until Phase 4, when it becomes a blocking problem.

### Pitfall 7: Network Requests from System Frameworks

**What goes wrong:** Even without explicit networking code, some Apple frameworks can make network requests (analytics, crash reporting, font loading). The SECR-01 requirement demands zero network requests.
**Why it happens:** Apple's frameworks sometimes include background telemetry. Xcode debug builds may include diagnostic networking.
**How to avoid:** Do not import any networking frameworks (URLSession, Network.framework). Do not enable CloudKit in SwiftData (`cloudKitDatabase: .none`). Verify zero network with Instruments Network profiler or Charles Proxy during testing. Note: some system-level requests (certificate validation, time sync) are outside app control and are not "app" requests.
**Warning signs:** Unexpected traffic in Charles Proxy during testing.

## Code Examples

### "Open in Contacts" via CNContactViewController

```swift
// Source: Apple ContactsUI documentation
import SwiftUI
import ContactsUI

struct ContactDetailBridge: UIViewControllerRepresentable {
    let contactIdentifier: String

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        guard let contact = try? store.unifiedContact(
            withIdentifier: contactIdentifier,
            keysToFetch: [CNContactViewController.descriptorForRequiredKeys()]
        ) else {
            // Return empty nav controller if contact not found
            return UINavigationController()
        }

        let vc = CNContactViewController(for: contact)
        vc.allowsEditing = true  // Let user edit in Contacts
        vc.allowsActions = false // No call/message actions (user decision)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
```

### Data Protection Configuration

```swift
// Source: Apple Data Protection documentation + Hacking with Swift
// In Xcode project settings:
// 1. Target > Signing & Capabilities > + Capability > Data Protection
// 2. Select "Complete Protection" (NSFileProtectionComplete)
//
// This sets the entitlement:
//   com.apple.developer.default-data-protection = NSFileProtectionComplete
//
// Effect: All files (including the SwiftData SQLite store) are encrypted
// when the device is locked. Data is inaccessible until the user unlocks
// the device. This satisfies SECR-02 (encrypted at rest).
//
// IMPORTANT: With Complete Protection, the app cannot read/write data
// while the device is locked. This is fine for Phase 1 (no background
// processing). Phase 2 (notifications) may need to use
// NSFileProtectionCompleteUntilFirstUserAuthentication instead if
// background refresh needs database access while locked.
```

### Privacy-Safe Logging (SECR-04)

```swift
// Source: Apple os.Logger documentation
import os

extension Logger {
    static let app = Logger(subsystem: "com.yourname.birthdayreminders", category: "app")
    static let sync = Logger(subsystem: "com.yourname.birthdayreminders", category: "sync")
}

// CORRECT: Contact data is private, redacted in release logs
Logger.sync.info("Imported contact: \(contactName, privacy: .private)")
Logger.sync.info("Contact count: \(count)")  // Integers are public by default, OK

// WRONG: Never do this -- PII in logs
// Logger.sync.info("Imported \(contactName)")  // Strings are private by default,
// but explicit .private is clearer and safer

// WRONG: Never use print() for contact data
// print("Contact: \(person.firstName) \(person.lastName)")  // Goes to stdout, capturable
```

### Onboarding Flow State Machine

```swift
// Onboarding flow driven by user decisions:
// 1. Welcome screen explaining the app
// 2. Permission request with contextual explanation
// 3. Import contacts
// Permission denied: friendly explanation + Settings link

enum OnboardingStep {
    case welcome
    case permissionRequest
    case importing
    case complete
    case permissionDenied
}

@Observable
@MainActor
final class OnboardingState {
    var step: OnboardingStep = .welcome
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
}
```

### Opening iOS Settings for Permission Recovery

```swift
// Source: Apple UIApplication documentation
import SwiftUI

Button("Open Settings") {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

## Discretion Recommendations

For the areas marked as "Claude's Discretion" in CONTEXT.md:

### Section Header Styling: Sticky (Recommended)

**Recommendation:** Use SwiftUI List with Section, which provides sticky headers by default in `.plain` list style. This is the iOS-native behavior users expect in a contact-like list. No custom code needed.

**Rationale:** The birthday list has four sections (today, this week, this month, later). As the user scrolls through a long "later" section, the sticky header reminds them which timeframe they are viewing. This is especially useful when searching narrows results across sections.

### Detail View Transition: Push (Recommended)

**Recommendation:** Use NavigationLink with push transition (standard NavigationStack behavior).

**Rationale:** The detail view is a content view (name, date, days until, open in contacts) that benefits from full-screen space and a natural back-swipe gesture. A sheet would be appropriate for ephemeral actions (forms, pickers), but this is a read-only content view. Push is the iOS standard for master-detail navigation and matches the "iOS-native feel" decision.

### Loading States During Import

**Recommendation:** Show a simple ProgressView with text ("Importing contacts...") centered on screen during the import. Do not show a progress bar with percentage -- the import is fast enough (< 2 seconds for most contact lists) that a determinate progress bar would flash by too quickly to be useful.

**Rationale:** For the guided onboarding flow, the user taps "Import" and expects feedback that something is happening. An indeterminate spinner with text is honest and appropriate for a sub-3-second operation.

### Error State Handling

**Recommendation:** Use a simple alert for unexpected errors (CNContactStore fetch failure, SwiftData save failure). These are rare edge cases. The main error flow (permission denied) is handled by the dedicated PermissionDeniedView with explanation and Settings link per the user decision.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ObservableObject + @Published | @Observable macro | iOS 17 (2023) | Granular view updates, less boilerplate. Use @Observable for all new code. |
| Core Data with .xcdatamodeld | SwiftData @Model | iOS 17 (2023) | Pure Swift models, macro-driven. #Unique and #Index added in iOS 18. |
| CNContactStore callback-based | async/await overloads | iOS 15 (2021) | Cleaner concurrency. enumerateContacts still synchronous internally but can be wrapped. |
| @Attribute(.unique) single property | #Unique macro compound constraints | iOS 18 (2024) | Multiple properties can form a uniqueness constraint together. |
| Manual contact deduplication | #Unique upsert behavior | iOS 18 (2024) | SwiftData auto-upserts on uniqueness collision. |

**Deprecated/outdated:**
- ObservableObject/@Published: Still works but causes unnecessary re-renders. Use @Observable.
- Core Data for new projects: SwiftData replaces it entirely for iOS 18+ targets.
- Storyboards: Incompatible with SwiftUI. Not relevant.

## Open Questions

1. **SwiftData computed property sorting**
   - What we know: @Query sort descriptors require persisted key paths. Computed properties like `nextBirthdayDate` cannot be used in @Query sort.
   - What's unclear: Whether storing a persisted `nextBirthdayDate` field (updated on import) or fetching all and sorting in-memory is the better approach for this app's scale.
   - Recommendation: For Phase 1, fetch all and sort in-memory. The contact list will be < 1000 entries (contacts with birthdays). In-memory sort is negligible overhead and avoids data staleness from a persisted computed field.

2. **Data Protection level for Phase 2 compatibility**
   - What we know: NSFileProtectionComplete encrypts data but makes it inaccessible when the device is locked. Phase 2 adds background notification rescheduling via BGAppRefreshTask, which runs while the device may be locked.
   - What's unclear: Whether BGAppRefreshTask can access NSFileProtectionComplete-protected files.
   - Recommendation: Start with NSFileProtectionComplete in Phase 1. If Phase 2 requires background database access, downgrade to NSFileProtectionCompleteUntilFirstUserAuthentication at that time. This still encrypts at rest and satisfies SECR-02.

3. **Non-Gregorian calendar conversion edge cases**
   - What we know: iOS Calendar API can convert between calendar systems. Chinese lunar, Hebrew, and Islamic calendars are supported.
   - What's unclear: Edge cases around lunar calendar year boundaries and leap months in the Chinese calendar.
   - Recommendation: Implement the basic conversion (nonGregorianBirthday -> Gregorian month/day) in Phase 1. Flag any conversion failures with a log entry. Edge cases around leap months are rare enough to defer to a polish phase.

4. **Free Apple ID provisioning and App Groups**
   - What we know: The dev environment uses free Apple ID sideloading. Free provisioning has limitations on capabilities.
   - What's unclear: Whether free Apple ID provisioning supports App Groups entitlement.
   - Recommendation: Test App Group creation with free provisioning early. If it fails, the fallback is to use the default container location and migrate when paid provisioning is available, or defer App Group to Phase 4.

## Sources

### Primary (HIGH confidence)
- [Apple: CNContactStore Documentation](https://developer.apple.com/documentation/contacts/cncontactstore) -- Authorization states, enumeration, keysToFetch
- [Apple: CNContact.birthday](https://developer.apple.com/documentation/contacts/cncontact/1403059-birthday) -- DateComponents, nil year behavior
- [Apple: CNContact.nonGregorianBirthday](https://developer.apple.com/documentation/contacts/cncontact/nongregorianbirthday) -- Non-Gregorian calendar support
- [Apple: CNContactViewController](https://developer.apple.com/documentation/contactsui/cncontactviewcontroller) -- View/edit contact in system UI
- [Apple: ModelConfiguration groupContainer](https://developer.apple.com/documentation/swiftdata/modelconfiguration/groupcontainer-swift.struct) -- App Group container for SwiftData
- [Apple: Data Protection Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection) -- Encryption at rest
- [Apple: OSLogPrivacy](https://developer.apple.com/documentation/os/oslogprivacy) -- Privacy-safe logging
- [Apple: WWDC24 What's New in SwiftData](https://developer.apple.com/videos/play/wwdc2024/10137/) -- #Unique, #Index macros

### Secondary (MEDIUM confidence)
- [Hacking with Swift: SwiftData encryption](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-encrypt-swiftdata) -- NSFileProtection with SwiftData
- [Hacking with Swift: SwiftData unique attributes](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-make-unique-attributes-in-a-swiftdata-model) -- @Attribute(.unique) and #Unique upsert behavior
- [Hacking with Swift: SwiftData widget access](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) -- App Group configuration steps
- [Yaacoub: SwiftData Index and Unique macros](https://yaacoub.github.io/articles/swift-tip/swiftdata-s-new-index-and-unique-macros/) -- #Unique compound constraints syntax
- [fatbobman: Codable in SwiftData models](https://fatbobman.com/en/posts/considerations-for-using-codable-and-enums-in-swiftdata-models/) -- Why DateComponents should NOT be stored directly
- [Nutrient.io: iOS Data Protection guide](https://www.nutrient.io/blog/how-to-use-ios-data-protection/) -- Four protection levels explained
- [SwiftLee: OSLog and Unified Logging](https://www.avanderlee.com/debugging/oslog-unified-logging/) -- Privacy-safe logging patterns

### Tertiary (LOW confidence)
- [Apple Community: Feb 29 birthdays](https://discussions.apple.com/thread/2756003) -- Confirms iOS Calendar itself fails on Feb 29 non-leap years
- [Lunar-Solar-Calendar-Converter (GitHub)](https://github.com/isee15/Lunar-Solar-Calendar-Converter) -- Third-party conversion reference (not for use, just for understanding the problem)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All Apple first-party frameworks with official documentation
- Architecture: HIGH -- SwiftData @Model patterns, MVVM with @Observable, and ContactBridge are well-documented
- Birthday data model: HIGH -- DateComponents decomposition verified via fatbobman's SwiftData Codable analysis
- Security (encryption at rest): MEDIUM -- iOS Data Protection is well-documented but SwiftData-specific file protection has caveats around WAL files
- Security (zero network): MEDIUM -- No networking code means no app-initiated requests, but verifying system framework behavior requires runtime testing
- Pitfalls: HIGH -- All sourced from Apple documentation, developer forums, or confirmed production issues

**Research date:** 2026-02-15
**Valid until:** 2026-03-15 (stable domain -- Apple frameworks, no fast-moving ecosystem)
