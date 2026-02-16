# Roadmap: Birthday Reminders

## Overview

This roadmap delivers a local-only iOS birthday reminder app in four phases. Phase 1 establishes the data foundation and primary screen -- contact import, birthday list, and security constraints baked in from the start. Phase 2 adds the notification engine (the core value proposition) with priority-based scheduling to handle the iOS 64-notification limit. Phase 3 layers on group management with two-way Contacts sync and per-group notification preferences. Phase 4 finishes with home screen and lock screen widgets.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Contact Import and Birthday List** - Data foundation, contact sync, upcoming birthday list, and security constraints
- [x] **Phase 2: Notification Engine** - Birthday notifications with configurable timing, delivery time, and overflow scheduling
- [ ] **Phase 3: Group Management** - Two-way Contacts group sync with per-group notification preferences
- [ ] **Phase 4: Widgets** - Home screen and lock screen widgets showing upcoming birthdays

## Phase Details

### Phase 1: Contact Import and Birthday List
**Goal**: User can open the app, import their contacts, and browse upcoming birthdays in a polished list -- with all data stored securely on-device with zero network activity
**Depends on**: Nothing (first phase)
**Requirements**: IMPT-01, IMPT-02, LIST-01, LIST-02, LIST-03, SECR-01, SECR-02, SECR-03, SECR-04
**Success Criteria** (what must be TRUE):
  1. User can grant contact permission and import all contacts with birthdays in one tap
  2. User sees upcoming birthdays sorted nearest-first with clear sections (today, this week, this month, later)
  3. User can search contacts by name and tap any birthday to see a detail view with name, date, and days until
  4. App makes zero network requests and stores all contact data encrypted at rest with no third-party code
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md -- Xcode project setup, Person model, BirthdayCalculator, ContactBridge
- [ ] 01-02-PLAN.md -- ContactSyncService, onboarding flow (welcome, permission, import)
- [ ] 01-03-PLAN.md -- Birthday list UI, detail view, search, settings, device verification

### Phase 2: Notification Engine
**Goal**: User receives timely birthday notifications at their preferred time, with the app intelligently managing the iOS 64-notification ceiling
**Depends on**: Phase 1
**Requirements**: NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-05
**Success Criteria** (what must be TRUE):
  1. User receives a notification on the day of a contact's birthday and the day before
  2. User can configure what time of day all notifications are delivered
  3. App schedules the most important 64 notifications and backfills as slots free up, so no birthday is silently dropped
  4. User sees a contextual pre-permission screen before the system notification prompt appears
**Plans**: 2 plans

Plans:
- [ ] 02-01-PLAN.md -- NotificationScheduler actor, NotificationDelegate, pre-permission primer, onboarding integration, scenePhase rescheduling
- [ ] 02-02-PLAN.md -- Delivery time settings view, post-import rescheduling, settings integration

### Phase 3: Group Management
**Goal**: User can organize contacts into groups that sync bidirectionally with iOS Contacts and control notification behavior per group
**Depends on**: Phase 2
**Requirements**: GRPS-01, GRPS-02, GRPS-03, GRPS-04
**Success Criteria** (what must be TRUE):
  1. User can create, rename, and delete groups within the app and see those changes reflected in iOS Contacts
  2. User can assign and remove contacts from groups
  3. User can set per-group notification preferences (same day, day before, or both) and the notification engine respects those preferences
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

### Phase 4: Widgets
**Goal**: User can glance at upcoming birthdays from the home screen or lock screen without opening the app
**Depends on**: Phase 1 (data layer); Phase 2 and 3 not strictly required but should be stable
**Requirements**: WDGT-01, WDGT-02
**Success Criteria** (what must be TRUE):
  1. User can add small, medium, or large home screen widgets that display upcoming birthdays
  2. User can add a lock screen widget showing the next upcoming birthday
  3. Widget data stays current with the main app's contact data
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Contact Import and Birthday List | 3/3 | Complete | 2026-02-15 |
| 2. Notification Engine | 2/2 | Complete | 2026-02-15 |
| 3. Group Management | 0/2 | Not started | - |
| 4. Widgets | 0/1 | Not started | - |
