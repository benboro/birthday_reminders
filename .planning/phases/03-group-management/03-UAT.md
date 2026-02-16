---
status: testing
phase: 03-group-management
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md]
started: 2026-02-16T06:50:00Z
updated: 2026-02-16T06:50:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 1
name: Navigate to Groups
expected: |
  From the birthday list screen, tap the groups icon (person.3 symbol) in the top-left toolbar. A "Groups" screen appears with a navigation title "Groups" and an empty state message since no groups exist yet.
awaiting: user response

## Tests

### 1. Navigate to Groups
expected: From the birthday list screen, tap the groups icon (person.3 symbol) in the top-left toolbar. A "Groups" screen appears with a navigation title "Groups" and an empty state message since no groups exist yet.
result: [pending]

### 2. Create a New Group
expected: On the Groups screen, tap the plus (+) button in the toolbar. An alert appears with a text field to enter a group name. Type a name (e.g., "Family") and confirm. The group appears in the list showing the name and "0 members". Open iOS Contacts app and verify the same group appears there.
result: [pending]

### 3. View Group Detail
expected: Tap the newly created group. A detail screen appears showing: the group name, a segmented notification preference picker with "Day before only" / "Day of only" / "Both" (defaulting to "Both"), and a members section (currently empty with an "Add Members" option).
result: [pending]

### 4. Add Members to Group
expected: From the group detail, tap "Add Members". A searchable contact list appears. Tap one or more contacts — a checkmark appears next to each selected contact. Dismiss the picker. The group detail now shows those contacts as members with their names and birthday info.
result: [pending]

### 5. Change Notification Preference
expected: On the group detail screen, tap a different segment in the notification preference picker (e.g., switch from "Both" to "Day of only"). The selection changes immediately. This means members of this group will only receive day-of birthday notifications, not day-before.
result: [pending]

### 6. Rename a Group
expected: On the group detail screen, trigger rename (via button or edit action). An alert appears with the current name pre-filled. Change the name and confirm. The navigation title updates. Going back to the group list shows the new name. The rename is also reflected in iOS Contacts.
result: [pending]

### 7. Remove a Member from Group
expected: On the group detail screen, swipe left on a member row. A delete action appears. Confirm removal. The member disappears from the group's member list but still exists in the main birthday list (they're removed from the group, not deleted).
result: [pending]

### 8. Delete a Group
expected: Delete the group (via toolbar action or swipe on the group list). A confirmation may appear. After deletion, the group is gone from both the app and iOS Contacts. All contacts that were in the group still appear in the main birthday list — only the group association is removed.
result: [pending]

### 9. Groups Sync on Contact Re-Import
expected: In iOS Contacts, manually create a new group and add contacts to it. Back in the app, trigger a contact re-import (from Settings). After import completes, navigate to Groups — the group created in iOS Contacts now appears in the app with its members.
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0

## Gaps

[none yet]
