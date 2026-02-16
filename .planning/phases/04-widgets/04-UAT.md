---
status: testing
phase: 04-widgets
source: 04-01-SUMMARY.md, 04-02-SUMMARY.md
started: 2026-02-15T12:00:00Z
updated: 2026-02-15T12:00:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 1
name: Add Home Screen Widget
expected: |
  Long-press home screen, tap +, search "Birthday". Two widgets appear: "Upcoming Birthdays" (home screen) and "Next Birthday" (lock screen). Select "Upcoming Birthdays" and choose small/medium/large size. Widget places on home screen.
awaiting: user response

## Tests

### 1. Add Home Screen Widget
expected: Long-press home screen, tap +, search "Birthday". Two widgets appear: "Upcoming Birthdays" (home screen) and "Next Birthday" (lock screen). Select "Upcoming Birthdays" and choose small/medium/large size. Widget places on home screen.
result: [pending]

### 2. Small Home Widget Display
expected: Small home screen widget shows the next upcoming birthday with the person's name, days until their birthday, and formatted birth date.
result: [pending]

### 3. Medium Home Widget Display
expected: Medium home screen widget shows the next 3 upcoming birthdays in rows, each with name and days-until countdown.
result: [pending]

### 4. Large Home Widget Display
expected: Large home screen widget shows up to 7 upcoming birthdays with a header row. If any birthday is today, that row is highlighted with a subtle accent color background. Each row shows name, days-until, and formatted date.
result: [pending]

### 5. Lock Screen Circular Widget
expected: From lock screen customization, add "Next Birthday" circular widget. It shows a gauge/ring that fills based on how close the next birthday is (within 30-day range), with the days count in the center.
result: [pending]

### 6. Lock Screen Rectangular Widget
expected: Rectangular lock screen widget shows the next birthday person's name and days-until count. If the birthday is today, a gift icon appears. Name text is redacted when device is locked (privacy-sensitive).
result: [pending]

### 7. Lock Screen Inline Widget
expected: Inline lock screen widget shows a single line of text with a gift SF Symbol and the next birthday info (e.g., "John in 3 days").
result: [pending]

### 8. Widget Empty State
expected: If no contacts with birthdays are imported, widgets display placeholder content (gift icon or "No birthdays" text) instead of crashing or showing blank space.
result: [pending]

### 9. Widget Updates After Sync
expected: After importing new contacts in the main app (or returning to the app from background), home screen and lock screen widgets update to reflect the latest birthday data without manual intervention.
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0

## Gaps

[none yet]
