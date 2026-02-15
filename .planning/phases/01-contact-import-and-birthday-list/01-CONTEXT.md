# Phase 1: Contact Import and Birthday List - Context

**Gathered:** 2026-02-15
**Status:** Ready for planning

<domain>
## Phase Boundary

User can open the app, import their contacts, and browse upcoming birthdays in a polished list — with all data stored securely on-device with zero network activity. Contact permission flow, birthday list with sections, search, detail view, and security constraints (encryption at rest, no network, no third-party code).

</domain>

<decisions>
## Implementation Decisions

### Import experience
- Manual re-import — user taps a button to refresh from Contacts when they choose (no continuous sync)
- Guided onboarding on first launch — welcome screen explaining the app, then permission request, then import
- Contacts without birthdays are silently ignored — only contacts with birthdays appear
- Permission denied: show a friendly explanation of why access is needed and offer to open Settings

### Birthday list layout
- Minimal rows: name + date + days until — no photos, no age
- Today's birthdays get a highlighted row (distinct background color or accent) to stand out
- Search bar always visible at the top of the list
- Section header styling (sticky vs inline): Claude's discretion

### Detail view
- Basics only: name, birthday date, days until — no age, no zodiac
- Read-only view — no quick actions (call, message)
- "Open in Contacts" link so user can edit the birthday in iOS Contacts as the single source of truth
- Transition style (push vs sheet): Claude's discretion

### App appearance
- iOS-native feel — system fonts, standard controls, familiar Apple patterns
- Light and dark mode, following the system setting
- System blue accent color — default iOS tint
- Single screen with navigation bar (no tab bar) — settings accessible via gear icon

### Claude's Discretion
- Section header styling (sticky vs inline)
- Detail view transition (push vs sheet)
- Loading states and progress indicators during import
- Exact spacing, typography, and layout details
- Error state handling

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-contact-import-and-birthday-list*
*Context gathered: 2026-02-15*
