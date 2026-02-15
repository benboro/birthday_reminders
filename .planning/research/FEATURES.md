# Feature Research

**Domain:** iOS Birthday Reminder App
**Researched:** 2026-02-15
**Confidence:** MEDIUM-HIGH (based on analysis of 15+ competitor apps across App Store listings, review articles, and user complaint threads)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Contact import (one-tap) | Every competitor does this. Users will not manually type 50+ birthdays. | MEDIUM | Use CNContactStore to pull name, photo, birthday. Must handle contacts without birthdays gracefully. Permission prompt UX is critical -- explain value before requesting. |
| Upcoming birthday list (nearest first) | This IS the app. Every competitor shows a chronological upcoming list as the primary view. | LOW | Sort by days-until-birthday. Show name, photo, date, age turning, days remaining. This is the main screen. |
| Same-day notification | The core promise of the app. iOS Calendar already does this natively -- the app must at least match it. | LOW | Local notification at user-configured time on the birthday. UNUserNotificationCenter. |
| Advance notification (day before / days before) | Every serious competitor offers at least "1 day before." Birthday Reminder Pro+ does 7 days. Birthday Calendar lets you set multiple lead times. Users need time to buy gifts or send cards. | LOW | Configurable: same day, 1 day, 2 days, 3 days, 1 week before. Per-contact or global default. |
| Age calculation | Users universally want to see "turning 30" not just "March 15." Every competitor shows this. | LOW | Calculate from birth year. Handle missing birth year gracefully (show date only, no age). |
| Contact photo display | Users identify people by face. Every competitor with contact sync shows the photo. Feels broken without it. | LOW | Pull from CNContact thumbnailImageData. Show initials as fallback. |
| Dark mode support | iOS standard since iOS 13. Apps without it look broken on dark-mode devices. | LOW | Use system colors and semantic colors throughout. Not a feature to market, but absence is noticed. |
| Search | Once you have 50+ birthdays, finding someone by name is essential. Birthday Boss, Birthday Reminder Pro+ all include search. | LOW | Simple text filter on the birthday list by name. |
| Manual birthday entry | Not everyone is in your contacts (e.g., online friends, partners' family). Birthday Reminder Pro+ and Birthday Boss both support this. | LOW | Name + date + optional photo. Store locally alongside imported contacts. |
| Notification time customization | iOS Calendar locks you to 9 AM. This is one of the top reasons people download a separate app. Must let users pick their preferred notification time. | LOW | Global default time + per-contact override option. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not expected, but valued when present.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Contact groups with two-way iOS sync | Only Birthday Boss has groups at all (Family/Friends/Work + custom), but it does NOT sync groups back to iOS Contacts. This is a genuine differentiator -- organize people in the app, and those groups appear in iOS Contacts and vice versa. No competitor does this. | HIGH | Use CNGroup and CNContactStore to read/write groups. Must handle conflict resolution (group renamed in Contacts vs app). This is the hardest feature technically but the clearest differentiator. |
| Weekly/monthly birthday digest notification | hip offers "weekly summaries." Most apps only notify per-birthday. A single Monday notification saying "3 birthdays this week: Mom (Tue), Jake (Thu), Sarah (Sat)" is more useful than 3 separate advance notifications. | MEDIUM | Aggregate upcoming birthdays into a single local notification. Configurable: weekly (pick day), monthly (1st of month). Requires scheduling logic. |
| Per-contact notification customization | Most apps offer only a global notification setting. Birthday Boss has "additional advance notifications" but it is clunky. Letting users say "notify me 1 week before for Mom but just same-day for coworkers" is genuinely useful. | MEDIUM | Override global defaults per contact. UI must not make simple case complex -- defaults should work, overrides are optional. |
| Home screen widgets (multiple sizes) | Birthday Reminder & Countdown offers 6 widget variants. diBirthday has lock screen widgets. Widgets keep the app visible without opening it. Apple pushes widgets heavily. | MEDIUM | WidgetKit. Small (next birthday), medium (next 3), large (next 5-7). Lock screen widget showing days until next birthday. |
| Polished countdown display | Several apps (Birthday Reminder & Countdown, Countdown+) emphasize visual countdown. A well-designed "12 days until..." display with the person's photo creates emotional connection. | LOW | Visual element on detail view and widgets. Days + hours if within 24h. |
| Zodiac / astrology sign display | hip shows "astrology tidbits." A lightweight touch -- show the zodiac sign emoji next to the birthday. Low effort, some users find it delightful. | LOW | Pure date calculation, no API needed. Show sign emoji + name. Optional -- can be toggled off. |
| Export to CSV/PDF | Birthday Reminder & Countdown and Birthday Boss both offer export. Useful for backup and for users switching apps. | LOW | Generate CSV with name, date, group. PDF with formatted list. Share sheet integration. |
| Belated birthday nudge | NextBday uniquely shows "yesterday's birthday" with a nudge to still send wishes. Prevents the "I saw the notification but forgot to act" problem. | LOW | Show yesterday's birthdays in a distinct "you missed these" section. Disappears after 24h. |
| Month-view calendar | Birthday Boss and Birthday Calendar offer calendar views alongside the list. Some users think spatially about dates. | MEDIUM | Calendar grid with birthday dots. Tap a day to see that day's birthdays. Secondary navigation, not primary. |

### Anti-Features (Commonly Requested, Often Problematic)

Features to explicitly NOT build. These align with the project's "lean" philosophy.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Gift tracking / gift ideas | hip, NextBday, and Birthday Boss all include gift lists. Seems like a natural extension. | Scope creep. Gift tracking is its own product category. It requires shopping integrations, price tracking, purchase history. It bloats the UI and distracts from the core value: reliable reminders. hip's "hip Finds" is essentially an ad channel for affiliate revenue. | Keep the app focused on reminders. Users who want gift tracking already use Amazon wishlists, Apple Notes, or dedicated apps. |
| Greeting card sending | hip (100+ cards), hbd, BirthdayAlarm all include card libraries. | Cards require either a content library to maintain or third-party integrations. They become stale. They push the app toward a messaging platform. Card quality becomes a review complaint vector. The app becomes about cards, not reminders. | One-tap action to open Messages/Mail with the contact pre-filled. Let the user write their own message. |
| Message templates / AI greetings | Birthday Nudge generates "personalized messages." HappyBday has templates. | Templates feel generic. AI-generated messages feel even more generic. Users who send templated birthday messages are sending something worse than nothing. This feature actively degrades the human connection the app exists to support. | Pre-fill the contact in Messages. Let humans be human. |
| Facebook birthday sync | Birthday Calendar and Countdown+ integrate with Facebook. | Facebook deprecated birthday API access years ago. Any integration is fragile and breaks regularly -- Birthday Calendar reviewers specifically complain about this. The Facebook social graph is not where birthday management lives anymore. | Import from iOS Contacts only. Contacts is the canonical source. |
| Social features / birthday feed | Some apps let you "share" birthday lists or see friends' birthdays socially. | Privacy nightmare. Birthday lists are personal data. Social features require accounts, servers, and moderation. This is a local-first app. | Keep it local. Export via share sheet if users want to share a specific list. |
| Anniversary / death date / general event tracking | Birthday Boss tracks "anniversaries, deaths, and other annual events." Countdown+ tracks arbitrary events. | Feature diffusion. The app is called "Birthday Reminders" not "Annual Event Tracker." Supporting arbitrary events complicates the data model, notification logic, and UI. Every event type needs its own display logic. | Build for birthdays only. If users need general event tracking, iOS Calendar and Reminders already exist. |
| iCloud sync / cloud backup | Birthday Reminder & Countdown and Birthday Boss offer iCloud sync. Birthday Boss even disabled it on iOS 26+, suggesting Apple made it harder. | For a local-first app that syncs FROM Contacts, the Contacts app IS the backup via iCloud. Adding CloudKit sync introduces complexity (conflict resolution, schema migration, entitlements) for questionable value. The birthday data already lives in Contacts. | Contacts sync IS the backup strategy. Offer CSV export as a manual backup option. |
| In-app calling / texting / emailing | Birthday Reminder Pro+ has direct call/text/email buttons. | These are one-line deep links (tel://, sms://, mailto://). Trivially simple to implement but clutter the UI with three action buttons per contact. The value is marginal -- users can open Contacts or Messages directly. | Single "Send wishes" button that opens the iOS share sheet or Messages with the contact pre-filled. One button, not three. |

## Feature Dependencies

```
[Contact Import]
    |
    +--requires--> [Upcoming Birthday List] (list needs data to display)
    |
    +--requires--> [Age Calculation] (needs birth year from contact)
    |
    +--requires--> [Contact Photo Display] (needs photo from contact)
    |
    +--enables--> [Contact Groups with iOS Sync] (groups operate on imported contacts)
    |                  |
    |                  +--enhances--> [Per-Contact Notification Customization]
    |                                    (set notification rules per group)
    |
    +--enables--> [Search] (search over imported + manual contacts)

[Manual Birthday Entry]
    |
    +--parallel-to--> [Contact Import] (both feed the birthday list)

[Notification Engine]
    |
    +--requires--> [Notification Time Customization] (must configure before scheduling)
    |
    +--requires--> [Same-Day Notification] (baseline)
    |
    +--requires--> [Advance Notification] (day before, week before)
    |
    +--enables--> [Weekly/Monthly Digest] (aggregates individual notifications)
    |
    +--enables--> [Per-Contact Notification Customization] (overrides per person)
    |
    +--enables--> [Belated Birthday Nudge] (post-birthday notification)

[Home Screen Widgets]
    |
    +--requires--> [Upcoming Birthday List] (widget displays list data)
    |
    +--independent--> [Lock Screen Widgets] (separate WidgetKit target)

[Month-View Calendar]
    |
    +--requires--> [Upcoming Birthday List] (calendar needs same data)
    |
    +--conflicts-with--> [App Simplicity] (adds navigation complexity)
```

### Dependency Notes

- **Contact Import requires Notification Permission:** Both CNContactStore and UNUserNotificationCenter permissions should be requested in onboarding. Contact permission first (to show value), then notification permission (to deliver value).
- **Groups require Contact Import:** Cannot assign groups without contacts loaded. Groups should be a Phase 2 feature after basic import works.
- **Digest Notifications require basic Notification Engine:** The weekly/monthly digest builds on top of per-birthday notifications. Ship individual notifications first, add digests after.
- **Widgets require the data layer:** WidgetKit extensions need access to the same data store. Plan shared App Group container from the start even if widgets ship later.
- **Month-View Calendar conflicts with simplicity:** Adding a calendar view introduces a navigation paradigm shift. If built, it must be a secondary tab, not replace the list.

## MVP Definition

### Launch With (v1)

Minimum viable product -- the smallest thing that is better than iOS Calendar's built-in birthday notifications.

- [ ] **Contact import (one-tap)** -- Without this, there is no app
- [ ] **Upcoming birthday list (nearest first)** -- The primary screen, the core experience
- [ ] **Contact photo + age display** -- Makes the list feel personal, not like a spreadsheet
- [ ] **Same-day + advance notifications** -- The core promise. Must work reliably.
- [ ] **Notification time customization** -- The #1 reason to use this over iOS Calendar
- [ ] **Manual birthday entry** -- For people not in contacts
- [ ] **Search** -- Essential once list exceeds ~20 entries
- [ ] **Dark mode** -- Not optional in 2026

### Add After Validation (v1.x)

Features to add once core is working and user feedback confirms direction.

- [ ] **Contact groups with two-way iOS sync** -- The signature differentiator. Complex enough to warrant its own phase. Ship after core is rock-solid.
- [ ] **Per-contact notification customization** -- Builds on groups (notify differently for Family vs Coworkers)
- [ ] **Weekly/monthly birthday digest** -- Requires notification engine to be proven reliable first
- [ ] **Home screen + lock screen widgets** -- High visibility, drives engagement. Requires shared data container.
- [ ] **Belated birthday nudge** -- Small feature, big user delight. Easy to add once notification system is mature.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Month-view calendar** -- Nice to have, adds complexity. Only build if user feedback demands it.
- [ ] **Zodiac sign display** -- Fun but niche. Add as a settings toggle when polish phase begins.
- [ ] **CSV/PDF export** -- Useful for power users but not a growth driver. Build when someone asks.
- [ ] **Countdown display polish** -- Animated countdowns, visual flair. Polish phase, not launch phase.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Contact import (one-tap) | HIGH | MEDIUM | P1 |
| Upcoming birthday list | HIGH | LOW | P1 |
| Same-day + advance notifications | HIGH | LOW | P1 |
| Notification time customization | HIGH | LOW | P1 |
| Contact photo + age display | MEDIUM | LOW | P1 |
| Manual birthday entry | MEDIUM | LOW | P1 |
| Search | MEDIUM | LOW | P1 |
| Dark mode | MEDIUM | LOW | P1 |
| Contact groups (two-way sync) | HIGH | HIGH | P2 |
| Per-contact notification rules | MEDIUM | MEDIUM | P2 |
| Home screen widgets | HIGH | MEDIUM | P2 |
| Lock screen widgets | MEDIUM | MEDIUM | P2 |
| Weekly/monthly digest | MEDIUM | MEDIUM | P2 |
| Belated birthday nudge | MEDIUM | LOW | P2 |
| Month-view calendar | LOW | MEDIUM | P3 |
| Zodiac sign display | LOW | LOW | P3 |
| CSV/PDF export | LOW | LOW | P3 |
| Countdown polish | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Birthday Boss ($0.99) | hip (subscription) | Birthday Reminder & Countdown (freemium) | NextBday (free) | Birthday Reminder Pro+ ($0.99) | Our Approach |
|---------|----------------------|---------------------|------------------------------------------|-----------------|-------------------------------|--------------|
| Contact import | Yes | Yes (+ Facebook, Calendar) | Yes | Yes (one-tap) | Yes (auto-detect) | One-tap import from Contacts only |
| Groups | Yes (Family/Friends/Work + custom) | Yes (custom groups) | No | No | No | Two-way sync with iOS Contact groups |
| Notification customization | Day-of + advance | Day, time, frequency | Default + per-contact | 0/1/3/7 days + daily time | Day-of + 7 days before | Global default + per-contact override |
| Widgets | 4 types (home + lock) | Yes | 6 types (home + lock) | Home screen | No | Multiple sizes, home + lock screen |
| Digest/summary | No | Weekly summaries | No | No | No | Weekly + monthly configurable digest |
| Gift tracking | History logs | hip Finds (gift shopping) | In-app gift ordering | Gift lists per contact | Gift ideas per person | NOT building this |
| Cards/greetings | No | 100+ cards | No | Greeting templates | No | NOT building this |
| Calendar view | Yes | No | No | Month organization | No | Defer to v2+ |
| Export | CSV | Import/export files | CSV, Excel, PDF | No | CSV | CSV export in v2+ |
| Pricing model | One-time $0.99 | Subscription | Free + $5-9/yr for pro | Free | One-time $0.99 | TBD (one-time or freemium recommended over subscription for this category) |
| Age display | Yes | Yes (countdown) | Yes (age + countdown) | No explicit | Yes | Yes, age turning + days until |
| Belated nudge | No | No | No | Yes (yesterday's birthdays) | No | Yes |
| Offline / local-first | Yes | Needs internet for some features | iCloud sync available | Fully local | iCloud sync | Fully local, no account needed |

### Competitive Gaps We Exploit

1. **Two-way group sync** -- No competitor syncs groups back to iOS Contacts. Birthday Boss has groups but they are app-internal only. This is our primary structural advantage.
2. **Digest notifications** -- Only hip offers weekly summaries, and hip is subscription-based and bloated with cards/gifts. A lean app with good digests fills a gap.
3. **Reliability without bloat** -- User complaints across competitors center on: notification unreliability, ad intrusion, and feature bloat. A lean, reliable, ad-free app with polished UX is the positioning.
4. **Belated nudge** -- Only NextBday does this. It is a small feature with outsized emotional value.

### Pricing Observation

The market splits into three models:
- **One-time purchase** ($0.99-$3.99): Birthday Boss, Birthday Reminder Pro+, Birdays
- **Subscription** ($2.99-$4.99/mo): hip, Birthday Nudge
- **Freemium** (free + IAP for pro): Birthday Reminder & Countdown, hbd

Subscription fatigue is real for utility apps. The most-loved apps in reviews (Birthday Boss, Birdays) are one-time purchases. Recommendation: either free with a one-time pro unlock ($1.99-$3.99) or fully free. Subscription is inappropriate for an app with no server costs.

## Sources

- [Birthday Reminder & Countdown - App Store](https://apps.apple.com/us/app/birthday-reminder-countdown/id1453656360) (App Store listing, features verified)
- [Birthday Reminder Pro+ - App Store](https://apps.apple.com/us/app/birthday-reminder-pro/id427341961) (App Store listing, features verified)
- [hip: Birthday Reminder & Cards - App Store](https://apps.apple.com/us/app/hip-birthday-reminder-cards/id401949944) (App Store listing, features verified)
- [hip Official Website](https://www.hip.app/) (Feature marketing page)
- [Birthday Boss - App Store](https://apps.apple.com/us/app/birthday-boss/id1039998852) (App Store listing, only competitor with groups)
- [Birthday Reminders - NextBday - App Store](https://apps.apple.com/us/app/birthday-reminders-nextbday/id6751151244) (App Store listing, belated nudge feature)
- [Top 5 Birthday Reminder Apps in 2025 - Birthday Nudge](https://birthdaynudge.com/blog/best-birthday-reminder-apps-2025/) (Competitor comparison with user experience details)
- [11 Best Birthday Reminder Apps for iPhone - Applavia](https://www.applavia.com/blog/best-birthday-reminder-apps-for-iphone/) (Feature roundup of 11 apps)
- [4 Best Free Birthday Reminder Apps - LoveTrack](https://lovetrackapp.com/articles/birthday-reminder-apps/) (User complaint analysis, notification reliability issues)
- [Apple Community - Notification of Birthdays](https://discussions.apple.com/thread/254742422) (iOS native birthday notification limitations)
- [Apple Community - No longer getting Contacts birthday alerts](https://discussions.apple.com/thread/254597167) (iOS native notification reliability problems)

---
*Feature research for: iOS Birthday Reminder App*
*Researched: 2026-02-15*
