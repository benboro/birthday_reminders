# Requirements: Birthday Reminders

**Defined:** 2026-02-15
**Core Value:** Reliable, timely birthday notifications that you can configure per group so the right people get the right level of attention.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Contact Import

- [ ] **IMPT-01**: User can sync all contacts that have birthdays from iOS Contacts with one tap
- [ ] **IMPT-02**: App requests contact access permission with contextual explanation before sync

### Birthday List

- [ ] **LIST-01**: User sees upcoming birthdays sorted nearest-first with sections (today, this week, this month, later)
- [ ] **LIST-02**: User can search contacts by name
- [ ] **LIST-03**: User can tap a birthday to see detail view (name, birthday date, days until)

### Notifications

- [ ] **NOTF-01**: User receives a notification on the day of a contact's birthday
- [ ] **NOTF-02**: User receives a notification the day before a contact's birthday
- [ ] **NOTF-03**: User can configure what time of day notifications are delivered
- [ ] **NOTF-04**: App handles iOS 64-notification limit with priority-based scheduling
- [ ] **NOTF-05**: App requests notification permission with contextual pre-permission screen

### Groups

- [ ] **GRPS-01**: User can create, rename, and delete groups within the app
- [ ] **GRPS-02**: Groups sync bidirectionally with iOS Contacts groups
- [ ] **GRPS-03**: User can set notification preferences per group (same day, day before, or both)
- [ ] **GRPS-04**: User can assign and remove contacts from groups

### Widgets

- [ ] **WDGT-01**: User can add home screen widgets showing upcoming birthdays (small/medium/large sizes)
- [ ] **WDGT-02**: User can add lock screen widget showing next upcoming birthday

### Security

- [ ] **SECR-01**: App makes zero network requests — no analytics, no tracking, no telemetry
- [ ] **SECR-02**: Contact data stored only in local SwiftData with iOS Data Protection (encrypted at rest)
- [ ] **SECR-03**: No third-party SDKs or dependencies included in the app
- [ ] **SECR-04**: No contact data written to system logs or crash reports

## v2 Requirements

### Contact Import

- **IMPT-03**: Contact photos and age display in list and detail views
- **IMPT-04**: Limited-access handling with ContactAccessButton for incremental contact additions

### Birthday List

- **LIST-04**: Full dark mode support
- **LIST-05**: Belated birthday nudge notification ("you missed these yesterday")

### Notifications

- **NOTF-06**: Weekly/monthly birthday digest notifications (summary of upcoming birthdays)
- **NOTF-07**: Background refresh to keep notification queue current when app not opened

### Groups

- **GRPS-05**: Container detection UI showing iCloud vs Exchange compatibility status

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Gift tracking or notes | Keeping it lean — just notifications |
| "Wished happy birthday" check-off | Unnecessary complexity for the core value |
| App Store publishing | Polished for personal use, not distribution |
| Manual birthday entry | App works exclusively with contacts that already have birthdays |
| Greeting cards / message templates | Bloat that competitors add; not aligned with core value |
| Social features | This is a personal reminder tool, not a social app |
| iCloud sync between devices | Local-only by design for simplicity and privacy |
| Third-party analytics or telemetry | Zero network policy for contact data security |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMPT-01 | — | Pending |
| IMPT-02 | — | Pending |
| LIST-01 | — | Pending |
| LIST-02 | — | Pending |
| LIST-03 | — | Pending |
| NOTF-01 | — | Pending |
| NOTF-02 | — | Pending |
| NOTF-03 | — | Pending |
| NOTF-04 | — | Pending |
| NOTF-05 | — | Pending |
| GRPS-01 | — | Pending |
| GRPS-02 | — | Pending |
| GRPS-03 | — | Pending |
| GRPS-04 | — | Pending |
| WDGT-01 | — | Pending |
| WDGT-02 | — | Pending |
| SECR-01 | — | Pending |
| SECR-02 | — | Pending |
| SECR-03 | — | Pending |
| SECR-04 | — | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 0
- Unmapped: 20 ⚠️

---
*Requirements defined: 2026-02-15*
*Last updated: 2026-02-15 after initial definition*
