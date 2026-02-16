# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Birthday Reminders is a native iOS app (Swift 6 / SwiftUI / SwiftData) that syncs contacts with birthdays from the iPhone Contacts store, organizes them into groups with two-way sync, and sends configurable local notifications. It includes home screen and lock screen widgets via a WidgetKit extension. The app is local-only with no backend or network code.

## Development Environment

Code is edited on Windows 11 (no local Xcode). Builds happen on MacinCloud via RDP. The workflow is: edit on Windows → push to GitHub → RDP into MacinCloud → pull and build in Xcode → sideload to iPhone via free Apple ID.

## Build Commands

Generate the Xcode project from `project.yml` (run on MacinCloud):
```bash
brew install xcodegen   # one-time
xcodegen generate
open BirthdayReminders.xcodeproj
```

The `.xcodeproj` is gitignored and must be regenerated via XcodeGen on each MacinCloud session.

## Architecture

**Targets**: Two targets defined in `project.yml` — the main `BirthdayReminders` app and `BirthdayRemindersWidget` extension. Both share an app group (`group.com.birthdayreminders`) for SwiftData access.

**Data layer**: SwiftData with two `@Model` classes — `Person` and `BirthdayGroup`. Birthday fields are stored as decomposed Ints (`birthdayMonth`, `birthdayDay`, `birthdayYear?`) rather than DateComponents to avoid SwiftData serialization issues. The shared `ModelContainer` uses `groupContainer: .identifier("group.com.birthdayreminders")` so the widget can read the same store.

**Service layer**: `@Observable @MainActor` services injected from the app root:
- `ContactSyncService` — CNContactStore authorization and contact import (off-main-thread via `Task.detached`)
- `GroupSyncService` — Bidirectional sync between CNGroup and BirthdayGroup (CRUD operations mutate both iOS Contacts and SwiftData)
- `NotificationScheduler` — Manages up to 64 `UNNotificationRequest` objects (iOS ceiling), sorted nearest-first, with per-group preference resolution (most-permissive wins when a person belongs to multiple groups)
- `NotificationDelegate` — `UNUserNotificationCenterDelegate` for foreground banners

**Stateless utilities**: `BirthdayCalculator` (enum with static methods for date math, Feb 29 → Mar 1 in non-leap years) and `ContactBridge` (maps CNContact ↔ Person, single source of truth for `keysToFetch`).

**Views**: No explicit ViewModels. Views use `@Query` for SwiftData reads and call services directly. `BirthdayListView` sorts by computed `daysUntilBirthday` in-memory because SwiftData `@Query` can't sort on computed properties. Onboarding is a state machine in `OnboardingFlowView`.

**Widget**: `BirthdayTimelineProvider` creates its own `ModelContainer` with the shared app group config, fetches top 8 upcoming birthdays as `WidgetBirthday` value types (not @Model), and refreshes `.after(midnight)`.

## Key Data Flows

**Contact import**: Permission → `ContactSyncService.importContacts()` → `ContactBridge.upsert()` → `GroupSyncService.syncGroupsFromContacts()` → `NotificationScheduler.reschedule()` → `WidgetCenter.reloadAllTimelines()`

**Notification scheduling**: Fetch all Person records → sort by `daysUntilBirthday` → resolve per-person preference from group memberships → generate day-of + day-before notifications → cap at 64 total → schedule via `UNCalendarNotificationTrigger`

## Concurrency

Swift 6 strict concurrency is enabled. Services use `@MainActor` isolation. Legacy frameworks (Contacts, ContactsUI, UserNotifications) are imported with `@preconcurrency`. `NotificationDelegate` uses `nonisolated` for delegate callbacks. Contact enumeration runs in `Task.detached`.

## Important Constraints

- iOS 18.0 minimum deployment target
- No third-party dependencies — pure Apple frameworks only
- No network code (no URLSession, no backend)
- iOS Contacts is the single source of truth for birthday data — the app never creates or edits birthdays
- Group CRUD must write to both SwiftData and CNContactStore
- GroupSyncService assigns `group.members` array in bulk (not individual appends) to avoid SwiftData many-to-many performance issues
- All PII (names, identifiers) must be logged with `privacy: .private`
- Widget shares 4 source files directly (Person, BirthdayGroup, BirthdayCalculator, Date+Birthday) rather than through a shared framework

## Commit Messages

- Commit messages must be a single sentence, concise and descriptive.
- Do NOT include any `Co-Authored-By` trailers or similar attribution lines in commit messages.
- Do NOT include blank lines or multi-line bodies in commit messages.
