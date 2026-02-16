---
phase: 04-widgets
verified: 2026-02-15T23:35:00Z
status: human_needed
score: 11/11 must-haves verified
human_verification:
  - test: "Add small, medium, and large home screen widgets"
    expected: "Widget gallery shows 'Upcoming Birthdays' with three size options. Each size displays correct number of birthdays (1, 3, 7). Today's birthdays appear highlighted on large widget."
    why_human: "Visual widget appearance, layout correctness, and StandBy mode rendering require physical device testing"
  - test: "Add lock screen widgets in all three accessory formats"
    expected: "Widget gallery shows 'Next Birthday' with circular (gauge countdown), rectangular (name + days), and inline (single line text) options. Circular widget shows meaningful gauge fill at various countdown distances."
    why_human: "Lock screen widget rendering and gauge visual appearance require physical device testing"
  - test: "Verify privacy redaction on lock screen"
    expected: "Lock device. Rectangular widget should redact birthday name while device is locked. Unlock device. Name should be visible again."
    why_human: "Privacy-sensitive modifier behavior requires physical lock screen testing"
  - test: "Verify widget data stays current"
    expected: "Add widget to home screen. Import new contacts or modify birthdays in main app. Return to home screen. Widget shows updated data. Foreground the app. Widget refreshes."
    why_human: "Real-time widget refresh behavior requires end-to-end testing with actual data changes"
  - test: "Verify empty state handling"
    expected: "Delete all contacts with birthdays. Widgets show 'No upcoming birthdays' placeholder text or gift icon (large widget). No crashes or blank widgets."
    why_human: "Edge case behavior with empty data requires testing"
  - test: "Verify widget timeline refresh at midnight"
    expected: "Widget displays 'Tomorrow' for a birthday. Wait until midnight. Widget updates to show 'Today' without opening the app."
    why_human: "Timeline refresh policy requires time-based observation"
---

# Phase 04: Widgets Verification Report

**Phase Goal:** User can glance at upcoming birthdays from the home screen or lock screen without opening the app
**Verified:** 2026-02-15T23:35:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Widget extension target exists in project.yml with correct app-extension type and shared source files | ✓ VERIFIED | project.yml line 43-71: BirthdayRemindersWidget target with type: app-extension, shared sources (Person.swift, BirthdayGroup.swift, BirthdayCalculator.swift, Date+Birthday.swift) |
| 2 | Widget extension has its own entitlements with the same app group (group.com.birthdayreminders) | ✓ VERIFIED | BirthdayRemindersWidget.entitlements line 6-9: com.apple.security.application-groups array contains group.com.birthdayreminders |
| 3 | TimelineProvider fetches upcoming birthdays from the shared SwiftData store and produces timeline entries | ✓ VERIFIED | BirthdayTimelineProvider.swift line 50-62: fetchEntry() queries Person with FetchDescriptor, sorts by daysUntilBirthday, maps to WidgetBirthday structs, returns BirthdayTimelineEntry |
| 4 | Main app triggers WidgetCenter.shared.reloadAllTimelines() after every contact sync | ✓ VERIFIED | BirthdayRemindersApp.swift line 55 (onImportComplete) and line 71 (onChange scenePhase .active): reloadAllTimelines() called after notificationScheduler.reschedule() |
| 5 | User can add small, medium, or large home screen widgets showing upcoming birthdays | ✓ VERIFIED | BirthdayRemindersWidget.swift line 23: supportedFamilies([.systemSmall, .systemMedium, .systemLarge]). SmallWidgetView shows 1 birthday, MediumWidgetView shows 3 (line 16: prefix(3)), LargeWidgetView shows 7 (line 27: prefix(7)) |
| 6 | User can add a lock screen widget showing the next upcoming birthday | ✓ VERIFIED | BirthdayRemindersWidget.swift line 37: supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline]). All lock screen views display first birthday from entry.upcomingBirthdays |
| 7 | All widget views handle the empty state (no birthdays) gracefully | ✓ VERIFIED | All views have if/else branches: SmallWidgetView line 25-30, MediumWidgetView line 9-13, LargeWidgetView line 10-19, CircularWidgetView line 19-22, RectangularWidgetView line 25-28, InlineWidgetView line 16-18. All show "No upcoming birthdays" text or gift icon |
| 8 | Home screen widgets use containerBackground for correct StandBy mode rendering | ✓ VERIFIED | HomeWidgetEntryView.swift line 24: .containerBackground(.fill.tertiary, for: .widget) applied on dispatcher Group |
| 9 | Lock screen widgets apply privacySensitive to redact names when device is locked | ✓ VERIFIED | RectangularWidgetView.swift line 15: .privacySensitive() applied to birthday name Text |
| 10 | Widget data stays current with the main app's contact data | ✓ VERIFIED | Timeline provider reads from same app group container (BirthdayTimelineProvider.swift line 19: groupContainer: .identifier("group.com.birthdayreminders"), matches BirthdayRemindersApp.swift line 22). Main app triggers reload after sync and foreground (line 55, 71) |
| 11 | Widget timeline refreshes at midnight when days-until values change | ✓ VERIFIED | BirthdayTimelineProvider.swift line 39-42: midnight computed as startOfDay(byAdding .day value 1), Timeline policy: .after(midnight) |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| project.yml | BirthdayRemindersWidget target configuration | ✓ VERIFIED | 72 lines, contains BirthdayRemindersWidget target with type: app-extension, shared sources, entitlements, dependencies |
| BirthdayRemindersWidget/Info.plist | Widget extension NSExtension configuration | ✓ VERIFIED | 31 lines, contains NSExtensionPointIdentifier: com.apple.widgetkit-extension |
| BirthdayRemindersWidget/BirthdayRemindersWidget.entitlements | App group entitlement for widget extension | ✓ VERIFIED | 12 lines, contains group.com.birthdayreminders |
| BirthdayRemindersWidget/Provider/BirthdayTimelineEntry.swift | TimelineEntry and WidgetBirthday value types | ✓ VERIFIED | 40 lines, defines WidgetBirthday struct with daysUntilText computed property, BirthdayTimelineEntry conforming to TimelineEntry, static placeholder |
| BirthdayRemindersWidget/Provider/BirthdayTimelineProvider.swift | TimelineProvider with SwiftData query | ✓ VERIFIED | 65 lines, implements placeholder/getSnapshot/getTimeline, fetchEntry() queries Person via FetchDescriptor, creates ModelContainer with app group |
| BirthdayReminders/App/BirthdayRemindersApp.swift | WidgetCenter reload after data changes | ✓ VERIFIED | 79 lines, imports WidgetKit (line 3), calls reloadAllTimelines() after sync (line 55) and foreground (line 71) |
| BirthdayRemindersWidget/BirthdayRemindersWidget.swift | WidgetBundle with home and lock screen widgets | ✓ VERIFIED | 39 lines, @main BirthdayRemindersWidgetBundle with BirthdayHomeWidget and BirthdayLockScreenWidget, correct supportedFamilies for each |
| BirthdayRemindersWidget/Views/HomeScreen/SmallWidgetView.swift | systemSmall widget showing next 1 birthday | ✓ VERIFIED | 32 lines, displays first birthday with daysUntilText, name, formatted date, handles empty state |
| BirthdayRemindersWidget/Views/HomeScreen/MediumWidgetView.swift | systemMedium widget showing next 3-4 birthdays | ✓ VERIFIED | 36 lines, ForEach over prefix(3), HStack with name and daysUntilText, Dividers, handles empty state |
| BirthdayRemindersWidget/Views/HomeScreen/LargeWidgetView.swift | systemLarge widget showing next 6-8 birthdays | ✓ VERIFIED | 61 lines, ForEach over prefix(7), header "Upcoming Birthdays", today highlighting with Color.accentColor.opacity(0.1), handles empty state with gift icon |
| BirthdayRemindersWidget/Views/LockScreen/CircularWidgetView.swift | accessoryCircular days countdown gauge | ✓ VERIFIED | 25 lines, Gauge with value: 30 - daysUntil, range 0...30, gaugeStyle(.accessoryCircularCapacity), handles empty state with AccessoryWidgetBackground + gift icon |
| BirthdayRemindersWidget/Views/LockScreen/RectangularWidgetView.swift | accessoryRectangular name + days display | ✓ VERIFIED | 30 lines, VStack with name (privacySensitive), daysUntilText with gift.fill icon for today, handles empty state |
| BirthdayRemindersWidget/Views/LockScreen/InlineWidgetView.swift | accessoryInline single-line text | ✓ VERIFIED | 20 lines, Text with SF Symbol string interpolation, handles daysUntil==0 with "birthday!" and gift.fill, else gift + countdown, handles empty state |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| BirthdayRemindersWidget/Provider/BirthdayTimelineProvider.swift | BirthdayReminders/Models/Person.swift | SwiftData FetchDescriptor in shared app group container | ✓ WIRED | Line 50: FetchDescriptor&lt;Person&gt;() creates query. Line 19: groupContainer .identifier("group.com.birthdayreminders") matches main app (BirthdayRemindersApp.swift line 22) |
| BirthdayReminders/App/BirthdayRemindersApp.swift | WidgetKit | WidgetCenter.shared.reloadAllTimelines() | ✓ WIRED | Line 3: import WidgetKit. Line 55: reloadAllTimelines() in onImportComplete. Line 71: reloadAllTimelines() in onChange scenePhase .active |
| project.yml | BirthdayRemindersWidget | XcodeGen widget extension target with shared sources | ✓ WIRED | Line 43-71: BirthdayRemindersWidget target with type: app-extension, sources array includes BirthdayRemindersWidget directory + 4 shared source paths. Line 35: main app dependencies includes target: BirthdayRemindersWidget |
| BirthdayRemindersWidget/BirthdayRemindersWidget.swift | BirthdayRemindersWidget/Provider/BirthdayTimelineProvider.swift | StaticConfiguration references BirthdayTimelineProvider | ✓ WIRED | Line 18: StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()). Line 32: Same for lock screen widget |
| BirthdayRemindersWidget/Views/HomeScreen/HomeWidgetEntryView.swift | BirthdayRemindersWidget/Views/HomeScreen/*.swift | widgetFamily environment switch dispatching to size-specific views | ✓ WIRED | Line 9: @Environment(\.widgetFamily). Line 13-22: switch on widgetFamily routes to SmallWidgetView, MediumWidgetView, LargeWidgetView |
| BirthdayRemindersWidget/Views/LockScreen/LockScreenWidgetEntryView.swift | BirthdayRemindersWidget/Views/LockScreen/*.swift | widgetFamily environment switch dispatching to accessory views | ✓ WIRED | Line 9: @Environment(\.widgetFamily). Line 13-22: switch on widgetFamily routes to CircularWidgetView, RectangularWidgetView, InlineWidgetView |

### Requirements Coverage

Phase 4 requirements from ROADMAP.md:

| Requirement | Status | Evidence |
|-------------|--------|----------|
| WDGT-01: Home screen widgets (small, medium, large) | ✓ SATISFIED | BirthdayHomeWidget with supportedFamilies [.systemSmall, .systemMedium, .systemLarge]. Views exist and render 1, 3, 7 birthdays respectively |
| WDGT-02: Lock screen widget | ✓ SATISFIED | BirthdayLockScreenWidget with supportedFamilies [.accessoryCircular, .accessoryRectangular, .accessoryInline]. Views exist for all three accessory formats |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | - | - | - | No anti-patterns detected |

**Analysis:**
- No TODO/FIXME/placeholder comments found (except legitimate WidgetKit placeholder method/property)
- No empty implementations or stub patterns detected
- No console.log equivalents (print/NSLog) found
- All files substantive with full implementations (20-79 lines per file, total 295 lines of widget code)
- All views handle empty state with meaningful placeholder UI
- All key links verified — components properly wired
- App group identifier consistent across main app, widget extension target, entitlements, and timeline provider
- Timeline refresh policy correct: .after(midnight) ensures widgets update when days-until values change
- Privacy-sensitive modifier applied correctly on lock screen rectangular widget name
- containerBackground applied on both entry view dispatchers for StandBy mode support
- Commits verified in git history: 78ab462, 5a7ba1e, eaaba84, 3c00f77

### Human Verification Required

#### 1. Add small, medium, and large home screen widgets

**Test:** Long-press home screen → tap + icon → search for "Birthday" → select "Upcoming Birthdays" → add small, medium, and large widgets to home screen. Verify each widget displays the correct number of birthdays (small: 1, medium: 3, large: 7). Verify today's birthday appears highlighted with accent color background on large widget.

**Expected:** Widget gallery shows "Upcoming Birthdays" with three size options. Each size displays the correct number of birthdays with names, days-until, and formatted dates. Layout is readable and visually polished. Today's birthdays appear highlighted on large widget with accent color background. Empty state shows "No upcoming birthdays" placeholder text or gift icon (large). Widgets render correctly in StandBy mode (horizontal orientation).

**Why human:** Visual widget appearance, layout correctness, text readability, today highlighting visual design, and StandBy mode rendering require physical device testing. Automated verification can confirm code structure but cannot assess visual polish or user experience quality.

#### 2. Add lock screen widgets in all three accessory formats

**Test:** Lock device → long-press lock screen → tap Customize → select Lock Screen → tap widget area → search for "Birthday" → select "Next Birthday" → add circular, rectangular, and inline widgets. Verify circular widget shows gauge with countdown number. Verify rectangular widget shows name and "Today" or "in X days". Verify inline widget shows single line with gift icon and name.

**Expected:** Widget gallery shows "Next Birthday" with three accessory options (circular, rectangular, inline). Circular widget displays gauge filling from 0-30 with countdown number visible. Rectangular widget shows birthday name on top line and days-until on bottom line, with gift icon for today's birthday. Inline widget shows single line with gift icon and name + countdown. Empty state shows "No upcoming birthdays" text or gift icon.

**Why human:** Lock screen widget rendering, gauge visual appearance, text layout, icon display, and accessory widget size constraints require physical device testing. Circular gauge fill visualization cannot be verified programmatically.

#### 3. Verify privacy redaction on lock screen

**Test:** Add rectangular lock screen widget. Ensure a birthday exists in the data. Lock device. Observe lock screen. Birthday name should be redacted (blurred or replaced with placeholder). Unlock device. Name should become visible.

**Expected:** While device is locked, the rectangular lock screen widget shows redacted/blurred name text (due to .privacySensitive() modifier). Days-until text remains visible. After unlocking, name becomes readable.

**Why human:** Privacy-sensitive modifier behavior requires physical lock screen testing. System-level privacy redaction cannot be verified programmatically — requires observing actual lock screen rendering.

#### 4. Verify widget data stays current

**Test:** Add a home screen widget. Note the displayed birthdays. Open main app. Import new contacts with birthdays OR delete contacts with birthdays OR use ContactBridge to modify birthday dates. Return to home screen. Observe widget content. Expected: widget shows updated data. Foreground the app again. Widget should refresh again.

**Expected:** After data changes in the main app (import, delete, modify), widgets reflect those changes. Widget may take a few seconds to refresh. Foregrounding the app triggers immediate widget refresh (via WidgetCenter.shared.reloadAllTimelines() on scenePhase .active). Widget content matches current contact data in the main app.

**Why human:** Real-time widget refresh behavior requires end-to-end testing with actual data changes. Automated verification can confirm reloadAllTimelines() is called, but cannot verify the system actually refreshes the widget UI and displays updated data correctly.

#### 5. Verify empty state handling

**Test:** Delete all contacts with birthdays from the main app (or set all birthday dates far in the future). Return to home screen. Observe widgets. Expected: no crashes, no blank widgets, all show placeholder text or icon.

**Expected:** Small/medium widgets show "No upcoming birthdays" text in caption font, secondary color. Large widget shows gift icon (large title font, secondary) and "No upcoming birthdays" text below. Lock screen circular widget shows AccessoryWidgetBackground with gift icon. Lock screen rectangular and inline widgets show "No upcoming birthdays" text. No crashes or blank/broken UI.

**Why human:** Edge case behavior with empty data requires visual inspection across all widget sizes. Empty state layout quality and user-friendliness cannot be verified programmatically.

#### 6. Verify widget timeline refresh at midnight

**Test:** Before midnight, add a widget and note a birthday showing "Tomorrow" status. Wait until midnight passes (or change device time to simulate). Observe widget without opening the app.

**Expected:** Widget updates automatically at midnight. Birthday that showed "Tomorrow" now shows "Today". Days-until countdown decrements correctly. Widget refresh happens without user intervention (driven by Timeline policy: .after(midnight)).

**Why human:** Timeline refresh policy requires time-based observation. Cannot be verified programmatically without simulating time passage or waiting for actual midnight boundary. System-level WidgetKit timeline scheduling behavior must be observed in practice.

---

## Summary

**Phase 04 goal ACHIEVED** — all automated checks passed.

### What's Verified

All 11 observable truths verified against actual codebase:
- Widget extension target correctly configured in project.yml with app-extension type, shared sources, entitlements, and Info.plist
- Timeline provider queries shared SwiftData store from app group container, sorts by daysUntilBirthday, produces timeline entries with midnight refresh policy
- Main app triggers WidgetCenter.shared.reloadAllTimelines() after every contact sync and foreground
- WidgetBundle registers two distinct widgets: BirthdayHomeWidget (systemSmall/Medium/Large) and BirthdayLockScreenWidget (accessoryCircular/Rectangular/Inline)
- Home screen widgets display 1, 3, 7 birthdays respectively at three sizes
- Lock screen widgets show next birthday in circular gauge, rectangular name+days, and inline single-line formats
- All views handle empty state gracefully with placeholder text or gift icon
- Privacy-sensitive modifier applied to lock screen rectangular widget name
- containerBackground applied to both entry view dispatchers for StandBy mode support
- App group identifier consistent across all components (group.com.birthdayreminders)
- No anti-patterns detected — all implementations substantive, properly wired, no stubs or placeholders

### What Needs Human Testing

6 items require physical device testing:
1. **Widget gallery and home screen rendering** — visual appearance, layout quality, today highlighting, StandBy mode
2. **Lock screen widget rendering** — gauge visualization, accessory layout constraints, text display
3. **Privacy redaction on lock screen** — system-level privacy-sensitive behavior when device locked
4. **Widget data freshness** — real-time refresh after data changes, reloadAllTimelines() effectiveness
5. **Empty state handling** — edge case UI quality with no birthdays
6. **Midnight timeline refresh** — automatic refresh at day boundary without user intervention

### Commits Verified

All 4 commits from SUMMARY files exist in git history:
- 78ab462: Widget extension target configuration (Plan 04-01 Task 1)
- 5a7ba1e: TimelineProvider and WidgetCenter wiring (Plan 04-01 Task 2)
- eaaba84: Home screen widget views (Plan 04-02 Task 1)
- 3c00f77: Lock screen widget views and WidgetBundle (Plan 04-02 Task 2)

### Next Steps

1. Run human verification tests on physical iOS device
2. If visual issues found, file as gaps and re-plan
3. If all tests pass, mark Phase 04 complete in ROADMAP.md

---

_Verified: 2026-02-15T23:35:00Z_
_Verifier: Claude (gsd-verifier)_
