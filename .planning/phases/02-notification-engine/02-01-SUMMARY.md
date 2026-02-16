---
phase: 02-notification-engine
plan: 01
subsystem: notifications
tags: [UserNotifications, UNCalendarNotificationTrigger, Swift actor, UNUserNotificationCenterDelegate, SwiftUI onboarding]

# Dependency graph
requires:
  - phase: 01-contact-import
    provides: "Person model with contactIdentifier, birthdayMonth, birthdayDay, displayName; BirthdayCalculator; OnboardingFlowView; BirthdayRemindersApp"
provides:
  - "NotificationScheduler actor with priority-based 64-notification ceiling management"
  - "NotificationDelegate for foreground banner display and tap handling"
  - "Pre-permission primer screen in onboarding flow"
  - "ScenePhase-triggered automatic rescheduling on every foreground entry"
  - "Logger.notifications category for structured notification logging"
affects: [02-notification-engine, 03-group-management, 04-widgets]

# Tech tracking
tech-stack:
  added: [UserNotifications framework]
  patterns: [Swift actor for serialized notification scheduling, deterministic notification IDs, pre-permission primer before system alert, scenePhase-driven rescheduling]

key-files:
  created:
    - BirthdayReminders/Services/NotificationScheduler.swift
    - BirthdayReminders/Services/NotificationDelegate.swift
    - BirthdayReminders/Views/Onboarding/NotificationPermissionView.swift
  modified:
    - BirthdayReminders/Extensions/Logger+App.swift
    - BirthdayReminders/Views/Onboarding/OnboardingFlowView.swift
    - BirthdayReminders/App/BirthdayRemindersApp.swift
    - BirthdayReminders/Views/BirthdayList/BirthdayListView.swift
    - BirthdayReminders/Info.plist

key-decisions:
  - "Day-before notification scheduled before day-of in the loop to prioritize earlier-firing reminders within the 64-slot cap"
  - "NotificationScheduler passed through init parameters rather than environment injection for explicit dependency wiring"
  - "BirthdayListView accepts notificationScheduler parameter now to avoid rewrite when settings page needs it"

patterns-established:
  - "Actor isolation: NotificationScheduler actor serializes all UNUserNotificationCenter interactions"
  - "Deterministic IDs: contactIdentifier-birthday-dayof/daybefore pattern for notification deduplication"
  - "Pre-permission primer: custom SwiftUI screen before system permission dialog to explain value"
  - "ScenePhase rescheduling: onChange(of: scenePhase) .active triggers full notification refresh"

# Metrics
duration: 3min
completed: 2026-02-15
---

# Phase 2 Plan 01: Notification Engine Core Summary

**NotificationScheduler actor with 64-notification ceiling, day-of/day-before calendar triggers, pre-permission primer in onboarding, and scenePhase-driven rescheduling**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-16T05:25:31Z
- **Completed:** 2026-02-16T05:28:11Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- NotificationScheduler actor manages the iOS 64-notification hard limit with priority-sorted scheduling by nearest birthday
- Day-of and day-before notifications use deterministic IDs and non-repeating UNCalendarNotificationTrigger with explicit year/month/day/hour/minute
- Pre-permission primer screen (bell icon, "Never Miss a Birthday") integrated into onboarding between contact import and completion
- App automatically reschedules all notifications on every foreground entry via scenePhase observer, backfilling slots as notifications fire
- NotificationDelegate displays banners with sound when app is in foreground (Swift 6 compatible with nonisolated + @preconcurrency)

## Task Commits

Each task was committed atomically:

1. **Task 1: NotificationScheduler actor, NotificationDelegate, and Logger extension** - `9e7a379` (feat)
2. **Task 2: Pre-permission primer, onboarding integration, and app wiring** - `e227c73` (feat)

## Files Created/Modified
- `BirthdayReminders/Services/NotificationScheduler.swift` - Actor managing permission requests, priority-sorted scheduling with 64-cap, calendar triggers
- `BirthdayReminders/Services/NotificationDelegate.swift` - Foreground notification display (banner+sound+list) and tap handling with contactIdentifier extraction
- `BirthdayReminders/Views/Onboarding/NotificationPermissionView.swift` - Pre-permission primer with bell icon, enable/skip buttons
- `BirthdayReminders/Extensions/Logger+App.swift` - Added .notifications logger category
- `BirthdayReminders/Views/Onboarding/OnboardingFlowView.swift` - Added .notificationPermission step between importing and complete, accepts NotificationScheduler
- `BirthdayReminders/App/BirthdayRemindersApp.swift` - Wired NotificationDelegate, scenePhase observer for rescheduling, passes scheduler to child views
- `BirthdayReminders/Views/BirthdayList/BirthdayListView.swift` - Accepts notificationScheduler parameter for future settings integration
- `BirthdayReminders/Info.plist` - Added NSUserNotificationsUsageDescription

## Decisions Made
- Day-before notification is scheduled before day-of in the per-person loop so earlier-firing reminders get priority within the 64-slot cap
- NotificationScheduler is passed explicitly through init parameters (not via SwiftUI environment) for clear dependency wiring and testability
- BirthdayListView already accepts notificationScheduler to avoid rewriting when Plan 02 adds the settings/delivery time picker
- Both day-of and day-before skip logic checks if the target date's delivery time has already passed today, not just if the date is in the past

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- NotificationScheduler is ready for Plan 02 to add delivery time settings and notification preferences
- The scheduler's `reschedule(people:deliveryHour:deliveryMinute:)` API already accepts configurable delivery time
- contactIdentifier stored in notification userInfo ready for deep linking in a future phase
- Per-person notification type preferences (dayOf/dayBefore/both) can be added in Phase 3 group management

## Self-Check: PASSED

All 9 files verified present. Both task commits (9e7a379, e227c73) verified in git log.

---
*Phase: 02-notification-engine*
*Completed: 2026-02-15*
