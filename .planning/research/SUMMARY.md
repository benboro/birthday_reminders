# Project Research Summary

**Project:** Birthday Reminders
**Domain:** Native iOS Birthday Reminder App (local-only, Contacts + Notifications)
**Researched:** 2026-02-15
**Confidence:** HIGH

## Executive Summary

Birthday Reminders is a local-only iOS app that syncs contacts from the phone, organizes them into groups with two-way Contacts sync, and delivers configurable birthday notifications. The expert approach for this type of app is an all-Apple-first-party stack: Swift 6.2, SwiftUI, SwiftData, the Contacts framework, and UserNotifications. Targeting iOS 18+ is the right call -- it unlocks SwiftData maturity features (#Unique, #Index), the new ContactAccessButton for limited-access handling, and covers the vast majority of active devices. Zero third-party dependencies are needed. The architecture follows modern MVVM with an @Observable service layer, where ViewModels only exist for screens with real business logic and simple display views use @Query directly.

The two highest-risk areas are the 64 local notification ceiling and two-way group sync with iOS Contacts. The notification limit is a hard iOS constraint that silently drops notifications beyond the 64th -- any user with 20+ contacts and multiple timing options will hit this. The proven mitigation is a priority-queue scheduler (modeled on Todoist's production approach) that schedules the soonest 64 and persists overflow to SwiftData for backfill. Two-way group sync is the app's primary differentiator but also its most complex feature: CNGroup is container-dependent (iCloud supports groups, Exchange does not), cross-container membership fails silently, and conflict resolution between app-side and Contacts-side edits must be handled. This feature should ship after the core birthday list and notification engine are rock-solid.

The competitive landscape validates the lean approach. Competitors bloat themselves with gift tracking, greeting cards, and social features -- exactly the things PROJECT.md explicitly excludes. The gaps this app exploits are: two-way group sync (no competitor does this), digest notifications (only one subscription-based competitor offers weekly summaries), and reliability without bloat. The biggest UX risk is notification permission timing -- requesting too early kills opt-in rates and makes the app's core value proposition unreachable.

## Key Findings

### Recommended Stack

All Apple first-party. No third-party dependencies. This is a strength -- it eliminates supply-chain risk and keeps the project simple.

**Core technologies:**
- **Swift 6.2** (iOS 18+ deployment target): Strict concurrency checking catches data races at compile time. Single-threaded-by-default mode simplifies @MainActor patterns.
- **SwiftUI**: Declarative UI, deeply integrated with SwiftData @Query and the Observation framework. Pure SwiftUI is sufficient for every screen in this app.
- **SwiftData** (iOS 18+ for #Unique/#Index): Modern persistence replacing Core Data boilerplate. #Unique compound constraints handle contact deduplication during sync. #Index accelerates upcoming-birthday queries.
- **Contacts framework + ContactAccessButton**: CNContactStore for reading contacts and groups. CNSaveRequest for writing groups back. ContactAccessButton (iOS 18+) handles the limited-access incremental picker.
- **UserNotifications**: UNCalendarNotificationTrigger for recurring birthday reminders. Hard 64-notification limit requires overflow architecture.
- **@Observable (Observation framework)**: Replaces ObservableObject/@Published with granular property tracking. Only re-renders views that read changed properties.
- **WidgetKit**: TimelineProvider-based widgets for birthday countdowns. Requires shared App Group container for data access.

**Critical version requirement:** iOS 18.0 minimum deployment target. This is non-negotiable -- SwiftData #Unique/#Index and ContactAccessButton are essential for this app's requirements.

### Expected Features

**Must have (table stakes):**
- Contact import (one-tap) from iOS Contacts -- the app has no value without this
- Upcoming birthday list sorted by nearest first -- this IS the app
- Same-day + configurable advance notifications -- the core promise
- Configurable notification delivery time -- the #1 reason to use this over iOS Calendar
- Contact photo and age display -- makes the list feel personal
- Search -- essential once list exceeds ~20 entries
- Dark mode -- mandatory in 2026

**Should have (differentiators):**
- Two-way contact group sync with iOS Contacts -- no competitor does this; it is the signature feature
- Per-group notification customization (same day, day before, week preview, month preview) -- aligns directly with PROJECT.md requirements
- Weekly/monthly birthday digest notification -- only hip offers this, and hip is bloated
- Home screen + lock screen widgets -- high visibility, drives engagement
- Belated birthday nudge ("you missed these yesterday") -- small feature, outsized emotional value

**Defer (v2+):**
- Month-view calendar, zodiac signs, CSV/PDF export, countdown animation polish
- Gift tracking, greeting cards, message templates, social features -- explicitly out of scope per PROJECT.md

**Note on PROJECT.md alignment:** PROJECT.md says "no manual entry -- hide contacts without birthdays." The feature research recommends manual entry as table stakes, but PROJECT.md overrides this. The app will work exclusively with contacts that already have birthday data. The empty-state UX must guide users to add birthdays in the Contacts app.

### Architecture Approach

MVVM with Service Layer using @Observable. Three ViewModels (BirthdayListVM, GroupManagerVM, SettingsVM) coordinate services. Pure display views use @Query and @Bindable directly -- no ViewModel-per-view. Services (ContactSyncService, NotificationScheduler, BirthdayCalculator) wrap iOS frameworks and are injected via SwiftUI .environment(). The data layer is SwiftData with three core models: Person, BirthdayGroup, and NotificationPreference.

**Major components:**
1. **ContactSyncService** -- wraps CNContactStore; handles authorization states (.authorized, .limited, .denied); maps CNContact to Person via ContactBridge; syncs groups bidirectionally via CNSaveRequest
2. **NotificationScheduler** -- wraps UNUserNotificationCenter; implements priority-queue overflow (64-notification limit); derives all notifications from SwiftData state; idempotent full-reschedule on every change
3. **BirthdayCalculator** -- pure stateless functions for next-birthday computation, days-until, age-turning; handles nil-year DateComponents and non-Gregorian calendars; no dependencies, highly testable
4. **GroupManagerVM** -- orchestrates group CRUD with two-way Contacts sync; handles container-dependency (iCloud vs Exchange); coordinates NotificationScheduler rescheduling after group preference changes

### Critical Pitfalls

1. **64 local notification ceiling** -- iOS silently drops notifications beyond 64. A user with 25 contacts and 3 timing options needs 75 slots. Implement the Todoist-style overflow queue from day one. This cannot be retrofitted without rewriting the notification layer.
2. **iOS 18 limited contacts access** -- Users can grant access to only a subset of contacts. Must handle CNAuthorizationStatus.limited distinctly, show ContactAccessButton for incremental additions, and never assume .authorized means "all contacts."
3. **Birthday DateComponents with nil year** -- CNContact.birthday.year is nil when stored without a year. Force-unwrapping crashes the app. Also: nonGregorianBirthday (Chinese lunar, Hebrew, Islamic) must be checked, and Feb 29 birthdays need an explicit non-leap-year policy.
4. **CNPropertyNotFetchedException** -- Accessing any CNContact property not in keysToFetch throws an uncatchable Objective-C exception that crashes Swift. Centralize a single keysToFetch array and unit-test it against all accessed properties.
5. **Contact groups are container-dependent** -- CNGroup only works in containers that support groups (iCloud yes, Exchange no, Google inconsistent). Cross-container membership fails. The app must detect container type, create groups only in compatible containers, and explain limitations to the user.
6. **Notification permission timing** -- Requesting too early kills opt-in rate (40-60% denial). Delay the prompt until after the user sees their birthday list. Show a pre-permission screen explaining value. Consider provisional authorization.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Foundation and Contact Import

**Rationale:** Everything depends on the data layer. SwiftData models, birthday calculation logic, and contact import are the foundation that every subsequent phase builds on. Architecture research confirms models must come first. Pitfalls research says DateComponents handling and keysToFetch centralization must be correct from the start.
**Delivers:** SwiftData models (Person, BirthdayGroup, NotificationPreference), BirthdayCalculator (pure logic), ContactBridge mapper, ContactSyncService with full + limited access handling, contact authorization onboarding flow.
**Addresses features:** Contact import (one-tap), contact photo display, age calculation, handling of contacts without birthdays (hide them per PROJECT.md).
**Avoids pitfalls:** DateComponents nil-year crashes, CNPropertyNotFetchedException, limited contacts access breakage, non-Gregorian birthday omission.

### Phase 2: Birthday List and Core UI

**Rationale:** With data in place, the primary screen can be built. This is the app's identity -- the upcoming birthday list sorted nearest-first. Architecture research shows BirthdayListView can use @Query directly for simple display, with BirthdayListVM only for search/filter coordination.
**Delivers:** Main birthday list view with sections (today, this week, this month, later), birthday detail view, search, avatar display with initials fallback, dark mode theming, empty state guidance.
**Addresses features:** Upcoming birthday list (nearest first), search, dark mode, contact photo + age display.
**Avoids pitfalls:** Age off-by-one from timezone (compute at display time), empty state confusion (guide user to add birthdays in Contacts).

### Phase 3: Notification Engine

**Rationale:** Notifications are the core value proposition but depend on having birthday data to schedule against. Architecture research mandates the overflow queue be built from the start -- not bolted on later. Permission timing must be deliberate (after user sees their list, not on cold launch).
**Delivers:** NotificationScheduler with 64-notification overflow queue, UNCalendarNotificationTrigger scheduling, notification permission request with pre-permission screen, global notification time configuration, same-day + advance notification scheduling, BGAppRefreshTask for background rescheduling.
**Addresses features:** Same-day notification, advance notifications (day before, week before), notification time customization.
**Avoids pitfalls:** 64-notification ceiling (overflow queue from day one), notification permission denial (delayed contextual prompt), repeating trigger with year component (omit year, set repeats: true), background task re-registration.

### Phase 4: Group Management with Two-Way Sync

**Rationale:** This is the app's primary differentiator but also its most complex feature. Architecture research says groups should come after contact sync and notification scheduling are stable. Pitfalls research highlights container-dependency as a design-level decision that must be made before building the UI. Two-way sync means changes in-app write back to iOS Contacts via CNSaveRequest.
**Delivers:** GroupManagerViewModel, group CRUD UI, two-way CNGroup sync, container detection and compatibility handling, group-specific notification preferences (same day, day before, week preview, month preview), NotificationScheduler rescheduling on group preference changes.
**Addresses features:** Contact groups with two-way iOS sync, per-group notification customization (the core PROJECT.md requirement).
**Avoids pitfalls:** Container-dependent group creation (detect iCloud vs Exchange), cross-container membership failures (validate before adding), CNSaveRequest batch failures (one request per container).

### Phase 5: Widgets and Digest Notifications

**Rationale:** Widgets and digest notifications are high-value features that depend on a stable data layer and notification engine. WidgetKit requires a shared App Group container -- this should be planned from Phase 1 but implemented here. Digest notifications aggregate individual birthday notifications into weekly/monthly summaries, requiring the notification engine to be proven reliable first.
**Delivers:** WidgetKit extension (small/medium/large home screen widgets, lock screen widget), App Group shared container for widget data access, weekly/monthly birthday digest notification, belated birthday nudge.
**Addresses features:** Home screen + lock screen widgets, weekly/monthly digest, belated birthday nudge.
**Avoids pitfalls:** Widget data access (App Group container), digest notifications crowding out individual notifications (priority queue handles this).

### Phase 6: Polish and Edge Cases

**Rationale:** Production hardening. ContactChangeObserver for external edits, incremental sync optimization, comprehensive edge case handling. These are the "looks done but isn't" items from pitfalls research.
**Delivers:** CNContactStoreDidChange observation with self-change filtering, incremental sync via change history tokens, Feb 29 non-leap-year policy implementation, permission revocation cache cleanup, unified contact deduplication, performance optimization for large contact lists.
**Addresses features:** Reliability, performance, edge case correctness.
**Avoids pitfalls:** Change observation loops, stale data from missing sync, Feb 29 silent notification failure, permission revocation data retention.

### Phase Ordering Rationale

- **Data before UI before logic:** Models and contact import must exist before the list view can display anything, and the list must display before notifications have meaning. This mirrors the architecture research build-order recommendation.
- **Notifications before groups:** Group-specific notification preferences depend on both the notification engine and the group model. Getting notifications right first means groups can layer preferences on top of a working system.
- **Groups are isolated high-complexity:** Two-way sync with container-dependent CNGroup is the riskiest feature. Isolating it in its own phase prevents it from destabilizing the core birthday list and notification system.
- **Widgets last among features:** WidgetKit is an extension target with its own lifecycle. It reads from a shared data store but does not affect core app behavior. Safe to build after everything it depends on is stable.
- **Polish is explicit:** Edge cases like non-Gregorian calendars, Feb 29 handling, and incremental sync are easy to defer but critical for real-world reliability. Making them an explicit phase prevents them from being forgotten.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Notification Engine):** The 64-notification overflow queue is non-trivial. The Todoist blog post provides a production reference, but the exact SwiftData schema for overflow persistence and BGAppRefreshTask integration need detailed design. Research the specific BGTaskScheduler registration and re-registration patterns.
- **Phase 4 (Group Management):** Two-way CNGroup sync with container detection has sparse documentation. Most developers avoid writing to Contacts groups. Research the exact CNSaveRequest patterns for group creation/membership across iCloud and Exchange containers. The architectural decision of "app-internal groups with CNGroup as sync target" vs "CNGroup as source of truth" needs to be resolved.

Phases with standard patterns (skip deep research):
- **Phase 1 (Data Foundation):** SwiftData @Model, CNContactStore fetch, and ContactBridge mapping are well-documented with official Apple examples and multiple tutorials.
- **Phase 2 (Birthday List):** Standard SwiftUI list with @Query. Extremely well-documented pattern.
- **Phase 5 (Widgets):** WidgetKit with TimelineProvider is a mature, well-documented pattern with abundant WWDC sessions and tutorials.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All Apple first-party frameworks with official documentation and WWDC sessions. Version requirements verified against Apple's published SDK submission rules. |
| Features | MEDIUM-HIGH | Based on analysis of 15+ competitor App Store listings and user review threads. Competitive gaps (two-way group sync, digest notifications) are verified by checking each competitor's feature list. Pricing analysis is directional, not definitive. |
| Architecture | HIGH | MVVM + Service Layer is the community-consensus SwiftUI pattern. Notification overflow queue is validated by Todoist's production post-mortem. Apple documentation confirms all integration patterns. Some architecture blog sources are MEDIUM confidence but corroborate official docs. |
| Pitfalls | HIGH | Primarily sourced from Apple Developer Documentation and Apple Developer Forums. The 64-notification limit, CNPropertyNotFetchedException, container-dependent groups, and limited contacts access are all documented by Apple or confirmed in developer forum threads with Apple responses. |

**Overall confidence:** HIGH

### Gaps to Address

- **App Group container setup:** Must be configured from Phase 1 even though widgets ship in Phase 5. The ModelContainer configuration needs to use a shared App Group from the start, or migrating data later will be painful. Validate the exact SwiftData + App Group + WidgetKit configuration pattern before Phase 1 implementation.
- **Non-Gregorian birthday conversion accuracy:** Research confirms nonGregorianBirthday exists but the exact Calendar conversion pattern (Chinese lunar to Gregorian) needs implementation-time validation. Edge cases around lunar calendar year boundaries are not well-documented.
- **BGAppRefreshTask reliability:** Background refresh is critical for keeping the notification overflow queue current when the app is not opened for weeks. Apple's documentation is clear on the API, but real-world reliability varies by device state, battery level, and usage patterns. May need a fallback strategy.
- **PROJECT.md vs Feature Research tension on manual entry:** PROJECT.md explicitly says "no manual entry" and "contacts without birthdays -- hidden entirely." Feature research recommends manual entry as table stakes. PROJECT.md takes precedence, but this means the app's empty state and the "contact has no birthday" experience must be exceptionally well-designed.
- **Pricing model:** Feature research recommends one-time purchase or free with pro unlock. PROJECT.md says this is for personal use (not App Store distribution), so pricing is not relevant for MVP. If distribution plans change, revisit.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: SwiftData, CNContactStore, CNGroup, CNSaveRequest, UNUserNotificationCenter, BGTaskScheduler, ContactAccessButton
- Apple WWDC24: What's New in SwiftData (#Unique, #Index, history API), Meet the Contact Access Button (limited access model)
- Apple Developer Forums: 64-notification limit confirmation, CNGroup container limitations, CNChangeHistoryFetchRequest Swift limitation
- Apple Upcoming Requirements: Xcode/SDK submission requirements for 2025-2026

### Secondary (MEDIUM confidence)
- Todoist Engineering: Local notification scheduler architecture (production-validated overflow pattern)
- TelemetryDeck: iOS version adoption statistics (66% iOS 26 as of Feb 2026)
- Hacking with Swift: SwiftData patterns, ContactAccessButton usage examples
- App Store competitor listings: Birthday Boss, hip, Birthday Reminder & Countdown, NextBday, Birthday Reminder Pro+ (feature verification)
- SwiftLee, Donny Wals, fatbobman: SwiftUI architecture patterns, @Observable migration guides

### Tertiary (LOW confidence)
- Medium articles on MVVM architecture (corroborate but do not establish patterns)
- User complaint threads on Apple Community forums (directional, not systematic)

---
*Research completed: 2026-02-15*
*Ready for roadmap: yes*
