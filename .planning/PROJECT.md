# Birthday Reminders

## What This Is

A polished local iPhone app that reminds you about upcoming birthdays. It syncs contacts from your phone, lets you organize people into groups with two-way sync, and sends configurable notifications — same day, day before, or weekly/monthly previews — so you never miss a birthday.

## Core Value

Reliable, timely birthday notifications that you can configure per group so the right people get the right level of attention.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Sync contacts with birthdays from iPhone Contacts
- [ ] Upcoming birthday list as the main screen (nearest first)
- [ ] Group management with two-way Contacts sync
- [ ] Configurable notification types per group (same day, day before, week preview, month preview)
- [ ] Simple list format for preview notifications
- [ ] Configurable notification delivery time
- [ ] Polished, show-worthy UI/UX

### Out of Scope

- Gift tracking or notes — keeping it lean, just notifications
- "Wished happy birthday" check-off — unnecessary complexity
- App Store publishing — polished for personal use, not distribution
- Contacts without birthdays — hidden entirely, no manual entry
- Real-time chat or social features — this is a personal reminder tool

## Context

- Native iOS app using Swift/SwiftUI
- Relies on iOS Contacts framework for contact and group sync
- Relies on iOS UserNotifications framework for local notifications
- Two-way group sync means changes in-app write back to Contacts
- No backend needed — everything is local on-device
- Birthday data comes exclusively from contact records

## Constraints

- **Platform**: iOS only — native iPhone app
- **Data**: Local only — no server, no account, no cloud sync
- **Contacts**: Read and write access to iOS Contacts (groups and birthdays)
- **Notifications**: Local notifications only (no push server)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-only, no backend | Simplicity, privacy, no infrastructure cost | — Pending |
| Two-way group sync with Contacts | User wants group changes to persist to phone contacts | — Pending |
| Hide contacts without birthdays | Keep the app focused on actionable reminders | — Pending |
| Group-based notification rules | More useful than global-only, less complex than per-person | — Pending |
| Lean feature set (no gift tracking) | Ship fast, do one thing well | — Pending |

---
*Last updated: 2026-02-15 after initialization*
