# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-15)

**Core value:** Reliable, timely birthday notifications that you can configure per group so the right people get the right level of attention.
**Current focus:** Phase 4 in progress, widget extension infrastructure complete

## Current Position

Phase: 4 of 4 (Widgets)
Plan: 1 of 2 in current phase (04-01 complete)
Status: Executing Phase 04
Last activity: 2026-02-15 -- Completed 04-01 widget extension infrastructure

Progress: [#########░] 90%

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: 4.1min
- Total execution time: 0.53 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-contact-import | 3 | 20min | 6.7min |
| 02-notification-engine | 2 | 5min | 2.5min |
| 03-group-management | 2 | 5min | 2.5min |
| 04-widgets | 1 | 2min | 2min |

**Recent Trend:**
- Last 5 plans: 15min, 3min, 3min, 2min, 2min
- Trend: stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: Security requirements (SECR-01 through SECR-04) embedded in Phase 1 as foundational constraints, not a separate phase
- [Roadmap]: Groups depend on notification engine being stable first (research recommendation)
- [01-01]: XcodeGen project.yml instead of hand-written .pbxproj for practical project generation on MacinCloud
- [01-01]: BirthdayCalculator uses private resolvedDate helper to DRY Feb 29 handling
- [01-01]: ContactBridge.upsert wraps fetch in do/catch with error logging
- [01-02]: ContactSyncService treats .limited same as .authorized for import -- CNContactStore only returns user-selected subset
- [01-02]: Indeterminate ProgressView for import -- sub-3-second operation makes determinate bar counterproductive
- [01-02]: @Bindable for syncService in OnboardingFlowView -- simpler than environment injection for single dependency
- [01-03]: In-memory sorting for sectioned birthday list -- @Query cannot sort computed daysUntilBirthday
- [01-03]: Today highlighting with Color.accentColor.opacity(0.1) -- system-aware color for light and dark mode
- [01-03]: CNContactViewController with allowsActions=false, allowsEditing=true -- read-only quick actions but editable for birthday corrections
- [01-03]: Dark mode verification deferred -- simulator toggle issue, app uses system colors throughout
- [02-01]: Day-before scheduled before day-of in loop to prioritize earlier-firing reminders within 64-slot cap
- [02-01]: NotificationScheduler passed via init parameters, not environment injection, for explicit dependency wiring
- [02-01]: BirthdayListView accepts notificationScheduler parameter early to avoid rewrite when settings page is added
- [02-02]: SettingsPlaceholderView struct renamed to SettingsView; file path kept to minimize churn
- [02-02]: Post-import rescheduling wired both inline in SettingsView and via onImportComplete callback in app root for all import sources
- [03-01]: Most-permissive-wins for conflicting group notification preferences -- if any group has .both, person gets both
- [03-01]: Ungrouped contacts default to .both for backward compatibility with Phase 2
- [03-01]: Bulk membership assignment in syncGroupsFromContacts to avoid SwiftData many-to-many 750x performance issue
- [03-01]: Fresh CNGroup refetch before every mutation to avoid stale reference errors
- [03-02]: Groups toolbar button on topBarLeading (person.3 icon) to avoid crowding settings gear on trailing side
- [03-02]: Segmented Picker for NotificationPreference -- 3 cases makes segments ideal for quick visual scanning
- [03-02]: GroupMemberPickerView commits each add/remove immediately rather than batching on dismiss
- [04-01]: @preconcurrency import WidgetKit for Swift 6 strict concurrency compatibility
- [04-01]: Shared source files via individual path references in XcodeGen rather than extracting to Shared/ directory
- [04-01]: Widget timeline refreshes at midnight via .after(midnight) policy for day-boundary accuracy

### Pending Todos

None yet.

### Blockers/Concerns

- ~~App Group container must be configured in Phase 1 even though widgets ship in Phase 4~~ (RESOLVED in 01-01: group.com.birthdayreminders configured in ModelConfiguration)
- ~~Feb 29 birthdays and non-Gregorian calendars need explicit handling during Phase 1 data layer~~ (RESOLVED in 01-01: BirthdayCalculator maps Feb 29 to March 1 in non-leap years; ContactBridge resolves non-Gregorian via calendar conversion)

## Session Continuity

Last session: 2026-02-15
Stopped at: Completed 04-01-PLAN.md
Resume file: .planning/phases/04-widgets/04-01-SUMMARY.md
