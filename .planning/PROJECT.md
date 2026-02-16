# Birthday Reminders

## What This Is

A native iOS app that syncs contacts with birthdays from iPhone Contacts, organizes them into groups with two-way sync, sends configurable local notifications with intelligent 64-slot scheduling, and displays upcoming birthdays via home screen and lock screen widgets. Local-only with zero network activity.

## Core Value

Reliable, timely birthday notifications that you can configure per group so the right people get the right level of attention.

## Requirements

### Validated

- ✓ Sync contacts with birthdays from iPhone Contacts — v1.0
- ✓ Upcoming birthday list as the main screen (nearest first, sectioned) — v1.0
- ✓ Group management with two-way Contacts sync — v1.0
- ✓ Per-group notification preferences (same day, day before, or both) — v1.0
- ✓ Configurable notification delivery time — v1.0
- ✓ 64-notification ceiling with priority-based scheduling — v1.0
- ✓ Home screen widgets (small/medium/large) — v1.0
- ✓ Lock screen widget (circular/rectangular/inline) — v1.0
- ✓ Zero network requests, encrypted at rest, no third-party code — v1.0

### Active

- [ ] Contact photos and age display in list and detail views
- [ ] Limited-access handling with ContactAccessButton for incremental additions
- [ ] Full dark mode verification and polish
- [ ] Belated birthday nudge notification
- [ ] Weekly/monthly birthday digest notifications
- [ ] Background refresh to keep notification queue current
- [ ] Container detection UI for iCloud vs Exchange groups

### Out of Scope

- Gift tracking or notes — keeping it lean, just notifications
- "Wished happy birthday" check-off — unnecessary complexity
- App Store publishing — personal use only, sideloaded via free Apple ID
- Manual birthday entry — app works exclusively with contacts that already have birthdays
- Greeting cards / message templates — bloat, not aligned with core value
- Social features — this is a personal reminder tool
- iCloud sync between devices — local-only by design for simplicity and privacy
- Third-party analytics or telemetry — zero network policy for contact data security

## Context

Shipped v1.0 with 2,850 LOC Swift across 5 phases (10 plans) in 2 days.
Tech stack: Swift 6, SwiftUI, SwiftData, WidgetKit, Contacts, UserNotifications.
Development environment: Windows 11 editing → GitHub → MacinCloud RDP → Xcode build → iPhone sideload.
No third-party dependencies. iOS 18.0 minimum deployment target.

## Development Environment

- **Dev machine**: Windows 11 (no local macOS or Xcode)
- **Code editing**: Done entirely on Windows, pushed to GitHub
- **Building**: MacinCloud Pay-As-You-Go ($1/hr, RDP from Windows, Xcode pre-installed)
- **Build workflow**: Push to GitHub → RDP into MacinCloud → pull and build in Xcode → deploy to iPhone
- **Testing on device**: Sideload via Xcode with a free Apple ID (no paid Developer account)
- **Sideload limitation**: Free provisioning expires every 7 days — app must be re-signed weekly via Xcode
- **No App Store distribution**: This is a personal-use app, not intended for public release
- **Security**: Always sign out of Xcode after each MacinCloud session. Keep 2FA enabled on your Apple ID.

## Constraints

- **Platform**: iOS only — native iPhone app
- **Data**: Local only — no server, no account, no cloud sync
- **Contacts**: Read and write access to iOS Contacts (groups and birthdays)
- **Notifications**: Local notifications only (no push server)
- **Build environment**: No local Mac — all Xcode builds happen on MacinCloud via RDP

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-only, no backend | Simplicity, privacy, no infrastructure cost | ✓ Good — zero network confirmed |
| Two-way group sync with Contacts | User wants group changes to persist to phone contacts | ✓ Good — bidirectional CRUD working |
| Hide contacts without birthdays | Keep the app focused on actionable reminders | ✓ Good — clean, focused UI |
| Group-based notification rules | More useful than global-only, less complex than per-person | ✓ Good — most-permissive-wins logic |
| Lean feature set (no gift tracking) | Ship fast, do one thing well | ✓ Good — shipped in 2 days |
| Windows dev + MacinCloud builds | No local Mac available; MacinCloud PAYG is cheapest on-demand option | ✓ Good — workflow works |
| Free Apple ID sideloading | No App Store distribution needed; avoids $99/yr Developer account | ✓ Good — accepts 7-day re-signing |
| XcodeGen for project generation | Avoid hand-written .pbxproj; regenerate on each MacinCloud session | ✓ Good — project.yml is portable |
| Decomposed birthday fields (month/day/year Ints) | SwiftData can't serialize DateComponents | ✓ Good — avoids serialization issues |
| In-memory sorting for birthday list | @Query can't sort on computed daysUntilBirthday | ✓ Good — performant with contact-scale data |
| Bulk membership assignment | Avoid SwiftData many-to-many 750x performance issue | ✓ Good — prevents perf regression |
| Shared source files via path references | Simpler than extracting to Shared/ framework for widget | ✓ Good — 4 files shared directly |
| @preconcurrency imports for legacy frameworks | Swift 6 strict concurrency with Contacts, WidgetKit | ✓ Good — clean concurrency compliance |

---
*Last updated: 2026-02-16 after v1.0 milestone*
