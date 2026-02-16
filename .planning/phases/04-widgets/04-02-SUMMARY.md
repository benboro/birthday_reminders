---
phase: 04-widgets
plan: 02
subsystem: ui
tags: [widgetkit, swiftui, widget-views, lock-screen, home-screen, widgetbundle, privacy-sensitive]

# Dependency graph
requires:
  - phase: 04-widgets
    plan: 01
    provides: "BirthdayTimelineProvider, BirthdayTimelineEntry, WidgetBirthday value type, widget extension target"
  - phase: 01-contact-import-and-birthday-list
    provides: "BirthdayCalculator for formatted birthday display"
provides:
  - "Home screen widget views (small, medium, large) with entry dispatcher"
  - "Lock screen widget views (circular, rectangular, inline) with entry dispatcher"
  - "WidgetBundle entry point registering both BirthdayHomeWidget and BirthdayLockScreenWidget"
  - "Privacy-sensitive name redaction on lock screen rectangular widget"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [widget-family-dispatcher, containerBackground-for-standby, gauge-accessoryCircular, privacySensitive-redaction]

key-files:
  created:
    - "BirthdayRemindersWidget/BirthdayRemindersWidget.swift"
    - "BirthdayRemindersWidget/Views/HomeScreen/HomeWidgetEntryView.swift"
    - "BirthdayRemindersWidget/Views/HomeScreen/SmallWidgetView.swift"
    - "BirthdayRemindersWidget/Views/HomeScreen/MediumWidgetView.swift"
    - "BirthdayRemindersWidget/Views/HomeScreen/LargeWidgetView.swift"
    - "BirthdayRemindersWidget/Views/LockScreen/LockScreenWidgetEntryView.swift"
    - "BirthdayRemindersWidget/Views/LockScreen/CircularWidgetView.swift"
    - "BirthdayRemindersWidget/Views/LockScreen/RectangularWidgetView.swift"
    - "BirthdayRemindersWidget/Views/LockScreen/InlineWidgetView.swift"
  modified: []

key-decisions:
  - "Widget family dispatcher pattern: Group+switch on widgetFamily environment for both home and lock screen entry views"
  - "containerBackground(.fill.tertiary) on dispatcher Group rather than individual size views for consistency"
  - "Circular gauge capped at 30-day range for meaningful visual fill at any countdown distance"

patterns-established:
  - "Entry view dispatcher pattern: single entry view reads widgetFamily and routes to size-specific child views"
  - "Today highlighting reuses Color.accentColor.opacity(0.1) pattern from BirthdayListView for visual consistency"

# Metrics
duration: 1min
completed: 2026-02-15
---

# Phase 4 Plan 2: Widget Views Summary

**Home screen widgets (small/medium/large) and lock screen widgets (circular/rectangular/inline) with WidgetBundle entry point, empty state handling, and privacy redaction**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-16T07:31:47Z
- **Completed:** 2026-02-16T07:33:15Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Home screen widgets display 1, 3, and 7 upcoming birthdays at small, medium, and large sizes respectively
- Lock screen widgets show countdown gauge (circular), name with days (rectangular), and single-line text (inline)
- WidgetBundle registers two distinct widgets: "Upcoming Birthdays" (home) and "Next Birthday" (lock screen)
- All views handle empty birthday lists gracefully with placeholder text or gift icon
- Privacy-sensitive modifier applied to lock screen rectangular name text for device-locked redaction
- containerBackground applied on both dispatchers for correct StandBy mode rendering

## Task Commits

Each task was committed atomically:

1. **Task 1: Create home screen widget views and entry view dispatcher** - `eaaba84` (feat)
2. **Task 2: Create lock screen widget views, entry dispatcher, and WidgetBundle** - `3c00f77` (feat)

## Files Created/Modified
- `BirthdayRemindersWidget/BirthdayRemindersWidget.swift` - @main WidgetBundle with BirthdayHomeWidget and BirthdayLockScreenWidget
- `BirthdayRemindersWidget/Views/HomeScreen/HomeWidgetEntryView.swift` - Dispatcher routing to small/medium/large views via widgetFamily
- `BirthdayRemindersWidget/Views/HomeScreen/SmallWidgetView.swift` - Shows next 1 birthday with name, days-until, and formatted date
- `BirthdayRemindersWidget/Views/HomeScreen/MediumWidgetView.swift` - Shows next 3 birthdays in rows with name and days-until
- `BirthdayRemindersWidget/Views/HomeScreen/LargeWidgetView.swift` - Shows next 7 birthdays with header, today highlighting, and formatted dates
- `BirthdayRemindersWidget/Views/LockScreen/LockScreenWidgetEntryView.swift` - Dispatcher routing to circular/rectangular/inline views
- `BirthdayRemindersWidget/Views/LockScreen/CircularWidgetView.swift` - Gauge with accessoryCircularCapacity style for days countdown
- `BirthdayRemindersWidget/Views/LockScreen/RectangularWidgetView.swift` - Name (privacy-sensitive) and days-until with gift icon on today
- `BirthdayRemindersWidget/Views/LockScreen/InlineWidgetView.swift` - Single-line text with SF Symbol gift icon via string interpolation

## Decisions Made
- Widget family dispatcher pattern uses Group+switch on widgetFamily environment value -- clean separation between dispatcher and size-specific views
- containerBackground(.fill.tertiary) applied on the dispatcher Group rather than each individual size view for DRY consistency
- Circular gauge range capped at 0...30 so the visual fill is meaningful whether the birthday is today or a month away

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All widget views complete -- the full widget extension is now functional
- This is the final plan in the project (Phase 4, Plan 2 of 2)
- The app is feature-complete: contact import, birthday list, notifications, group management, and widgets

## Self-Check: PASSED

- All 9 files verified present on disk
- Commit eaaba84 verified in git log
- Commit 3c00f77 verified in git log

---
*Phase: 04-widgets*
*Completed: 2026-02-15*
