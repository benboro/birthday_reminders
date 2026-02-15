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
- App Store publishing — personal use only, sideloaded via free Apple ID
- Contacts without birthdays — hidden entirely, no manual entry
- Real-time chat or social features — this is a personal reminder tool

## Context

- Native iOS app using Swift/SwiftUI
- Relies on iOS Contacts framework for contact and group sync
- Relies on iOS UserNotifications framework for local notifications
- Two-way group sync means changes in-app write back to Contacts
- No backend needed — everything is local on-device
- Birthday data comes exclusively from contact records

## Development Environment

- **Dev machine**: Windows 11 (no local macOS or Xcode)
- **Code editing**: Done entirely on Windows, pushed to GitHub
- **Building**: MacinCloud Pay-As-You-Go ($1/hr, RDP from Windows, Xcode pre-installed)
- **Build workflow**: Push to GitHub → RDP into MacinCloud → pull and build in Xcode → deploy to iPhone
- **Testing on device**: Sideload via Xcode with a free Apple ID (no paid Developer account)
- **Sideload limitation**: Free provisioning expires every 7 days — app must be re-signed weekly via Xcode
- **No App Store distribution**: This is a personal-use app, not intended for public release
- **Security**: Use a dedicated throwaway Apple ID for Xcode signing on MacinCloud — never sign in with your personal Apple ID on a shared cloud machine. Sign out of Xcode after each session. Keep 2FA enabled on all Apple IDs.

## Constraints

- **Platform**: iOS only — native iPhone app
- **Data**: Local only — no server, no account, no cloud sync
- **Contacts**: Read and write access to iOS Contacts (groups and birthdays)
- **Notifications**: Local notifications only (no push server)
- **Build environment**: No local Mac — all Xcode builds happen on MacinCloud via RDP

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-only, no backend | Simplicity, privacy, no infrastructure cost | — Pending |
| Two-way group sync with Contacts | User wants group changes to persist to phone contacts | — Pending |
| Hide contacts without birthdays | Keep the app focused on actionable reminders | — Pending |
| Group-based notification rules | More useful than global-only, less complex than per-person | — Pending |
| Lean feature set (no gift tracking) | Ship fast, do one thing well | — Pending |
| Windows dev + MacinCloud builds | No local Mac available; MacinCloud PAYG is cheapest on-demand option with RDP + pre-installed Xcode | — Decided |
| Free Apple ID sideloading | No App Store distribution needed; avoids $99/yr Developer account; accepts 7-day re-signing | — Decided |
| Throwaway Apple ID for signing | Personal Apple ID should never be used on shared cloud machines; dedicated dev Apple ID isolates risk | — Decided |

---
*Last updated: 2026-02-15 after initialization*
