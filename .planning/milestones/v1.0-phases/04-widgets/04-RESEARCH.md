# Phase 4: Widgets - Research

**Researched:** 2026-02-15
**Domain:** WidgetKit (iOS 18), SwiftData app group sharing, XcodeGen multi-target
**Confidence:** HIGH

## Summary

Phase 4 adds home screen widgets (small, medium, large) and a lock screen widget for the Birthday Reminders app. WidgetKit is Apple's first-party framework for this, and it is the only supported approach -- there are no third-party alternatives and none should be used (SECR-03). The existing app already has the App Group container `group.com.birthdayreminders` configured in both the entitlements and the SwiftData `ModelConfiguration`, which means the data-sharing foundation is already in place. The widget extension will create its own `ModelContainer` pointing at the same app group to read the shared SwiftData store.

The primary technical challenges are: (1) configuring a new widget extension target in XcodeGen's `project.yml`, (2) building a `TimelineProvider` that queries SwiftData for upcoming birthdays, (3) designing appropriate SwiftUI views for six widget families (three home screen sizes plus three lock screen accessory types), and (4) ensuring the widget timeline stays current when the main app's data changes via `WidgetCenter.shared.reloadAllTimelines()`.

**Primary recommendation:** Create a single widget extension with a `WidgetBundle` containing two widgets -- a home screen widget (supporting `systemSmall`, `systemMedium`, `systemLarge`) and a lock screen widget (supporting `accessoryCircular`, `accessoryRectangular`, `accessoryInline`). Use `TimelineProvider` (not `AppIntentTimelineProvider`) since there are no user-configurable widget options. Query SwiftData directly in the timeline provider using the shared app group container. Trigger timeline reloads from the main app after every contact sync.

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| WidgetKit | iOS 14+ (current: iOS 18) | Widget extension framework | Apple's only supported widget framework; no alternatives exist |
| SwiftUI | iOS 18.0 | Widget view rendering | Required by WidgetKit -- all widget views must be SwiftUI |
| SwiftData | iOS 17+ (current: iOS 18) | Shared data access via app group | Already used by main app; widget reads from same store |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| WidgetCenter | iOS 14+ | Timeline reload triggers | Call `reloadAllTimelines()` from main app after data changes |
| XcodeGen | Current | Generate widget extension target | Already used for project generation; add new target to `project.yml` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TimelineProvider | AppIntentTimelineProvider | AppIntentTimelineProvider adds user-configurable widget options (e.g., pick a group to show). Not needed for v1 requirements (WDGT-01/WDGT-02 specify no configuration). Can be added later if needed. |
| Two separate widgets in bundle | Single widget with all families | A single widget supporting all 6 families works but makes the widget gallery confusing -- the user sees one entry with very different appearances. Two widgets (home + lock screen) provide clearer gallery presentation. |
| Direct SwiftData query in provider | Shared UserDefaults / JSON file | UserDefaults has size limits and requires manual serialization. SwiftData via app group is already configured and gives access to the full Person model. |

### Installation

No package installation needed. WidgetKit and SwiftData are Apple first-party frameworks included in the iOS SDK. The widget extension is configured via `project.yml` (XcodeGen).

## Architecture Patterns

### Recommended Project Structure

```
BirthdayReminders/
+-- (existing app sources)

BirthdayRemindersWidget/
+-- BirthdayRemindersWidget.swift          # @main WidgetBundle entry point
+-- Provider/
|   +-- BirthdayTimelineProvider.swift      # TimelineProvider implementation
|   +-- BirthdayTimelineEntry.swift         # TimelineEntry data structure
+-- Views/
|   +-- HomeScreen/
|   |   +-- SmallWidgetView.swift           # systemSmall: next 1 birthday
|   |   +-- MediumWidgetView.swift          # systemMedium: next 3-4 birthdays
|   |   +-- LargeWidgetView.swift           # systemLarge: next 6-8 birthdays
|   +-- LockScreen/
|   |   +-- CircularWidgetView.swift        # accessoryCircular: days countdown
|   |   +-- RectangularWidgetView.swift     # accessoryRectangular: name + days
|   |   +-- InlineWidgetView.swift          # accessoryInline: "Name in X days"
+-- Shared/
    +-- WidgetDataService.swift             # SwiftData query helper for widget
    +-- Info.plist                          # NSExtension with WidgetKit identifier
    +-- BirthdayRemindersWidget.entitlements # App Group entitlement
```

**Files shared between main app and widget extension targets:**
- `BirthdayReminders/Models/Person.swift`
- `BirthdayReminders/Models/BirthdayGroup.swift` (if needed for filtering)
- `BirthdayReminders/Services/BirthdayCalculator.swift`
- `BirthdayReminders/Extensions/Date+Birthday.swift`

### Pattern 1: WidgetBundle with Two Widgets

**What:** A single widget extension containing a `WidgetBundle` with two distinct widget definitions -- one for home screen families and one for lock screen families.
**When to use:** When providing widgets for both home screen and lock screen placements.
**Example:**
```swift
// Source: Apple WidgetBundle documentation
@main
struct BirthdayRemindersWidgetBundle: WidgetBundle {
    var body: some Widget {
        BirthdayHomeWidget()
        BirthdayLockScreenWidget()
    }
}

struct BirthdayHomeWidget: Widget {
    let kind: String = "BirthdayHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()) { entry in
            HomeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Birthdays")
        .description("See upcoming birthdays at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BirthdayLockScreenWidget: Widget {
    let kind: String = "BirthdayLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Birthday")
        .description("See the next upcoming birthday.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
```

### Pattern 2: TimelineProvider with SwiftData Query

**What:** The `TimelineProvider` creates its own `ModelContainer` using the shared app group, fetches upcoming birthdays, and generates timeline entries.
**When to use:** In every widget timeline refresh cycle.
**Example:**
```swift
// Source: Verified pattern from Apple docs + community best practices
struct BirthdayTimelineProvider: TimelineProvider {
    typealias Entry = BirthdayTimelineEntry

    // Widget needs its own ModelContainer for the shared app group store
    private var sharedModelContainer: ModelContainer {
        let schema = Schema([Person.self, BirthdayGroup.self])
        let config = ModelConfiguration(
            "BirthdayReminders",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.birthdayreminders")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create widget ModelContainer: \(error)")
        }
    }

    func placeholder(in context: Context) -> BirthdayTimelineEntry {
        BirthdayTimelineEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayTimelineEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayTimelineEntry>) -> Void) {
        let entry = fetchEntry()
        // Refresh at midnight (birthdays change day boundaries)
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    @MainActor
    private func fetchEntry() -> BirthdayTimelineEntry {
        let container = sharedModelContainer
        let descriptor = FetchDescriptor<Person>()
        let people = (try? container.mainContext.fetch(descriptor)) ?? []
        let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
        return BirthdayTimelineEntry(date: .now, upcomingBirthdays: sorted.prefix(8).map {
            WidgetBirthday(
                name: $0.displayName,
                daysUntil: $0.daysUntilBirthday,
                month: $0.birthdayMonth,
                day: $0.birthdayDay,
                year: $0.birthdayYear
            )
        })
    }
}
```

### Pattern 3: containerBackground for iOS 17+ Widgets

**What:** All widgets must use `.containerBackground(for: .widget)` to provide a removable background. Without this, Xcode shows warnings and widgets render incorrectly in StandBy mode.
**When to use:** On every widget view's top-level container.
**Example:**
```swift
// Source: Apple iOS 17 WidgetKit documentation, verified via Swift Senpai
struct HomeWidgetEntryView: View {
    var entry: BirthdayTimelineEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                EmptyView()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### Pattern 4: Widget Timeline Reload from Main App

**What:** After every contact sync or data change in the main app, call `WidgetCenter.shared.reloadAllTimelines()` to notify WidgetKit that data has changed.
**When to use:** After `ContactSyncService` import completes, after any data mutation.
**Example:**
```swift
// Source: Apple WidgetCenter documentation
import WidgetKit

// In ContactSyncService or wherever data changes:
WidgetCenter.shared.reloadAllTimelines()

// Or reload only specific widget kinds:
WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayHomeWidget")
WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayLockScreenWidget")
```

### Anti-Patterns to Avoid

- **Creating ModelContainer on every timeline call:** The ModelContainer should be created once (or lazily cached). Creating it repeatedly is wasteful and can cause crashes if the store is busy.
- **Using @Query in widget views:** `@Query` requires a `.modelContainer()` view modifier which does not work on `WidgetConfiguration`. Use `FetchDescriptor` directly in the `TimelineProvider` and pass data as plain structs in the `TimelineEntry`.
- **Storing Person model objects in TimelineEntry:** `TimelineEntry` must be serializable. Use plain value types (structs) to carry birthday data from the provider to the views, not SwiftData `@Model` objects.
- **Forgetting containerBackground:** Omitting `.containerBackground(for: .widget)` causes preview errors and broken rendering in StandBy mode on iOS 17+.
- **Using networking or heavy computation in timeline provider:** Widget extensions have strict memory and execution time limits. Keep the timeline provider lightweight -- fetch from local SwiftData only.
- **Not handling empty data state:** The widget must render gracefully when there are zero birthdays (first launch, before sync).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Widget rendering | Custom UIKit extension views | WidgetKit + SwiftUI | WidgetKit is the only supported approach for iOS widgets since iOS 14 |
| Data sharing between app and extension | Custom file-based IPC, UserDefaults serialization | SwiftData with shared app group container | Already configured; SwiftData handles concurrency and schema migrations |
| Timeline scheduling | Custom timer/background refresh | WidgetKit TimelineProvider + WidgetCenter | System manages refresh budget; hand-rolling would be more complex and less reliable |
| Lock screen styling | Custom grayscale/vibrant rendering | `widgetRenderingMode` environment value | System automatically handles lock screen desaturation; read rendering mode to adapt |
| Midnight refresh | Background URLSession or BGTaskScheduler | TimelineProvider `.after(midnight)` policy | WidgetKit's timeline policy handles this natively |

**Key insight:** WidgetKit is an opinionated framework -- you provide a TimelineProvider and SwiftUI views, and the system handles everything else (refresh scheduling, rendering contexts, size management). Fighting the framework by hand-rolling any of these creates fragile, non-standard widgets.

## Common Pitfalls

### Pitfall 1: Widget Extension Missing App Group Entitlement

**What goes wrong:** Widget shows empty or stale data. SwiftData creates a separate database in the widget extension's own container instead of reading the shared app group store.
**Why it happens:** The widget extension target needs its own entitlements file with the same `group.com.birthdayreminders` app group. Forgetting to add this (or misconfiguring in XcodeGen) means the extension cannot access the shared store.
**How to avoid:** Create a separate entitlements file for the widget extension (`BirthdayRemindersWidget.entitlements`) with the same app group. Verify in XcodeGen `project.yml` that `CODE_SIGN_ENTITLEMENTS` points to it. The `ModelConfiguration` in the widget must use the same `groupContainer: .identifier("group.com.birthdayreminders")` as the main app.
**Warning signs:** Widget displays placeholder data indefinitely; widget database file appears in the widget extension's container directory instead of the shared group container.

### Pitfall 2: Swift 6 Strict Concurrency with TimelineProvider

**What goes wrong:** Build errors about non-sendable types, @MainActor isolation conflicts, or "capture of non-sendable type" warnings in the timeline provider.
**Why it happens:** The project uses Swift 6.0 with strict concurrency. `TimelineProvider` methods use completion handlers. SwiftData's `mainContext` requires `@MainActor`. These constraints can conflict.
**How to avoid:** Mark data-fetching helper methods as `@MainActor`. Use `@preconcurrency import WidgetKit` if needed (Xcode 16+ has updated WidgetKit with `@Sendable` annotations on completion handlers, but edge cases remain). Consider setting `SWIFT_STRICT_CONCURRENCY` to `targeted` for the widget extension target if strict mode causes irresolvable issues.
**Warning signs:** Build errors mentioning Sendable, MainActor isolation, or non-isolated access in the widget target.

### Pitfall 3: Shared Source Files Not Added to Widget Target

**What goes wrong:** Build errors like "cannot find type 'Person' in scope" in the widget extension.
**Why it happens:** Swift source files must be explicitly included in each target that uses them. `Person.swift`, `BirthdayGroup.swift`, `BirthdayCalculator.swift`, and `Date+Birthday.swift` exist in the main app target but are not automatically available to the widget extension.
**How to avoid:** In XcodeGen `project.yml`, configure the widget extension's `sources` to include both the widget-specific directory AND the shared model/service files from the main app. Use path includes, not file-level references, to keep it maintainable.
**Warning signs:** Compiler errors about undefined types or missing symbols, specifically for types defined in the main app target.

### Pitfall 4: Timeline Refresh Budget Exhaustion

**What goes wrong:** Widget shows stale data in production even though it works perfectly in debug.
**Why it happens:** In production, WidgetKit limits widgets to roughly 40-70 refreshes per day (approximately every 15-60 minutes). Debug builds have no limit, masking the issue. Calling `reloadAllTimelines()` too frequently can exhaust the budget.
**How to avoid:** Design the timeline with date-based entries. For a birthday app, the most important refresh is at midnight (when "days until" values change). Set `.after(midnight)` policy. Only call `reloadAllTimelines()` after actual data changes (contact sync), not on every app foreground.
**Warning signs:** Widget works in Simulator/debug but shows stale data when sideloaded to a real device.

### Pitfall 5: Forgetting NSExtension in Widget Info.plist

**What goes wrong:** The widget extension fails to load or doesn't appear in the widget gallery.
**Why it happens:** Widget extensions require `NSExtension` with `NSExtensionPointIdentifier` set to `com.apple.widgetkit-extension` in their Info.plist. If the Info.plist is missing or malformed, iOS doesn't recognize the extension.
**How to avoid:** Create a dedicated Info.plist for the widget extension with the required `NSExtension` dictionary. In XcodeGen, use `info` properties on the target to generate this, or provide a manual Info.plist.
**Warning signs:** Widget doesn't appear in the widget gallery at all; no crash, just absent.

### Pitfall 6: ModelContainer Initialization in Widget Preview Crashes

**What goes wrong:** Widget previews crash with "failed to find a currently active container" error.
**Why it happens:** SwiftUI previews for widgets need an active `ModelContainer` in memory even for placeholder data. If the provider uses the shared app group store, previews may fail because the app group isn't available in the preview environment.
**How to avoid:** Provide in-memory preview containers or use static preview data that doesn't depend on SwiftData. The `placeholder(in:)` method should return hardcoded sample data, not query the database.
**Warning signs:** Xcode preview canvas shows red error banners; preview crashes in the widget extension target.

## Code Examples

### TimelineEntry with Plain Value Types

```swift
// Source: Verified pattern from Apple WidgetKit docs + community best practices
struct BirthdayTimelineEntry: TimelineEntry {
    let date: Date
    let upcomingBirthdays: [WidgetBirthday]

    static var placeholder: BirthdayTimelineEntry {
        BirthdayTimelineEntry(
            date: .now,
            upcomingBirthdays: [
                WidgetBirthday(name: "John Doe", daysUntil: 0, month: 2, day: 15, year: 1990),
                WidgetBirthday(name: "Jane Smith", daysUntil: 3, month: 2, day: 18, year: nil),
                WidgetBirthday(name: "Bob Wilson", daysUntil: 7, month: 2, day: 22, year: 1985),
            ]
        )
    }
}

struct WidgetBirthday: Identifiable {
    let id = UUID()
    let name: String
    let daysUntil: Int
    let month: Int
    let day: Int
    let year: Int?

    var daysUntilText: String {
        switch daysUntil {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "in \(daysUntil) days"
        }
    }
}
```

### Small Home Screen Widget View

```swift
// Source: Pattern derived from WidgetKit documentation + existing BirthdayRowView
struct SmallWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            VStack(alignment: .leading, spacing: 4) {
                Text(birthday.daysUntilText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(birthday.daysUntil == 0 ? .accent : .secondary)

                Text(birthday.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(BirthdayCalculator.formattedBirthday(
                    month: birthday.month,
                    day: birthday.day,
                    year: birthday.year
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Text("No upcoming birthdays")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

### Lock Screen Accessory Circular Widget

```swift
// Source: Pattern from Apple WWDC22 "Complications and widgets: Reloaded"
struct CircularWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            Gauge(value: Double(max(0, 30 - birthday.daysUntil)), in: 0...30) {
                Text("\(birthday.daysUntil)")
            } currentValueLabel: {
                Text("\(birthday.daysUntil)")
                    .font(.system(.title2, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "gift")
            }
        }
    }
}
```

### Lock Screen Accessory Inline Widget

```swift
// Source: Pattern from Apple lock screen widget documentation
struct InlineWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            if birthday.daysUntil == 0 {
                Text("\(Image(systemName: "gift.fill")) \(birthday.name)'s birthday!")
            } else {
                Text("\(Image(systemName: "gift")) \(birthday.name) \(birthday.daysUntilText)")
            }
        } else {
            Text("No upcoming birthdays")
        }
    }
}
```

### XcodeGen Widget Extension Target Configuration

```yaml
# Source: XcodeGen docs + verified XcodeGen GitHub issue #904
# Add to project.yml targets section:

BirthdayRemindersWidget:
  type: app-extension
  platform: iOS
  deploymentTarget: "18.0"
  sources:
    - path: BirthdayRemindersWidget
    # Shared files from main app (models + utilities the widget needs)
    - path: BirthdayReminders/Models/Person.swift
    - path: BirthdayReminders/Models/BirthdayGroup.swift
    - path: BirthdayReminders/Services/BirthdayCalculator.swift
    - path: BirthdayReminders/Extensions/Date+Birthday.swift
  settings:
    base:
      PRODUCT_BUNDLE_IDENTIFIER: com.birthdayreminders.widget
      INFOPLIST_FILE: BirthdayRemindersWidget/Info.plist
      CODE_SIGN_ENTITLEMENTS: BirthdayRemindersWidget/BirthdayRemindersWidget.entitlements
      SWIFT_VERSION: "6.0"
      SKIP_INSTALL: true
      ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
      ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME: WidgetBackground
      TARGETED_DEVICE_FAMILY: "1"
      GENERATE_INFOPLIST_FILE: false
  entitlements:
    path: BirthdayRemindersWidget/BirthdayRemindersWidget.entitlements
    properties:
      com.apple.security.application-groups:
        - group.com.birthdayreminders
  dependencies:
    - sdk: SwiftUI.framework
    - sdk: WidgetKit.framework
```

And add the widget as a dependency of the main app target:

```yaml
# In the BirthdayReminders target, add:
dependencies:
  - target: BirthdayRemindersWidget
```

### Widget Extension Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Birthday Widgets</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
```

### Widget Extension Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.birthdayreminders</string>
    </array>
</dict>
</plist>
```

### Triggering Widget Reload from Main App

```swift
// Source: Apple WidgetCenter documentation
// Add to ContactSyncService or BirthdayRemindersApp after data changes
import WidgetKit

// After contact sync completes:
WidgetCenter.shared.reloadAllTimelines()

// The existing onImportComplete callback in BirthdayRemindersApp.swift
// is the ideal place to add this call.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `IntentConfiguration` with SiriKit intents | `AppIntentConfiguration` with App Intents | iOS 17 (WWDC23) | Simpler API for configurable widgets; not needed for v1 since we use StaticConfiguration |
| `.background()` modifier for widget background | `.containerBackground(for: .widget)` | iOS 17 (WWDC23) | Required for StandBy mode support; old approach causes preview errors |
| No lock screen widgets | `accessoryCircular/Rectangular/Inline` families | iOS 16 (WWDC22) | Enabled lock screen widget placement; separate from home screen families |
| Completion-handler-based TimelineProvider | Same, but with `@Sendable` annotations | Xcode 16 (2024) | Fixed Swift 6 strict concurrency warnings in WidgetKit |
| No transaction history | SwiftData `HistoryDescriptor` for granular widget updates | iOS 18 (WWDC24) | Enables selective widget reloads based on what changed; optional optimization |

**Deprecated/outdated:**
- `IntentConfiguration`: Replaced by `AppIntentConfiguration` for configurable widgets in iOS 17+. For non-configurable widgets, `StaticConfiguration` remains current and correct.
- `.background()` on widget views: Must be replaced with `.containerBackground(for: .widget)` for iOS 17+ targets.

## Open Questions

1. **Shared source file approach in XcodeGen**
   - What we know: XcodeGen supports listing individual source files in a target's `sources` array. The widget extension needs `Person.swift`, `BirthdayGroup.swift`, `BirthdayCalculator.swift`, and `Date+Birthday.swift` from the main app.
   - What's unclear: Whether listing individual files causes issues with XcodeGen's source detection (duplicate symbol warnings, target membership conflicts). An alternative approach is extracting shared files into a `Shared/` directory referenced by both targets.
   - Recommendation: Start with individual file references in the widget target's sources array. If this causes duplicate symbol issues, refactor shared code into a dedicated `Shared/` directory. XcodeGen's `excludes` on the main app target may be needed to prevent double-inclusion.

2. **privacySensitive() for birthday data on lock screen**
   - What we know: The `privacySensitive()` modifier redacts widget content when the device is locked. The app has security requirements (SECR-04: no contact data in logs).
   - What's unclear: Whether birthday names on lock screen widgets should be considered sensitive data requiring redaction. The lock screen is inherently visible to anyone who sees the phone.
   - Recommendation: Apply `privacySensitive()` to the name text in lock screen widgets, which will show redacted placeholder content when the device is locked. This aligns with the app's privacy-first approach without being overly restrictive when the user has explicitly added a widget.

3. **Widget preview strategy without shared app group**
   - What we know: SwiftUI previews for widget extensions may not have access to the app group container. Previews need a `ModelContainer` to render views that reference SwiftData models.
   - What's unclear: Whether Xcode previews can access the app group container in the simulator environment.
   - Recommendation: Use hardcoded placeholder data in previews via the `placeholder(in:)` method and static preview providers. Do not depend on SwiftData in preview mode.

## Sources

### Primary (HIGH confidence)
- Apple WidgetKit Documentation: Building Widgets Using WidgetKit and SwiftUI - widget architecture, TimelineProvider protocol, widget families
- Apple SwiftData Documentation: ModelConfiguration.GroupContainer - app group data sharing configuration
- Apple WidgetCenter Documentation: reloadTimelines(ofKind:) and reloadAllTimelines() API
- XcodeGen GitHub Issue #904 - confirmed widget extensions use `app-extension` type with `com.apple.widgetkit-extension` NSExtensionPointIdentifier
- XcodeGen ProjectSpec.md - target configuration, dependencies, and source file referencing

### Secondary (MEDIUM confidence)
- [Swift with Majid: Lock screen widgets in SwiftUI](https://swiftwithmajid.com/2022/08/30/lock-screen-widgets-in-swiftui/) - lock screen widget rendering modes, containerBackground, widgetAccentable
- [CreateWithSwift: Creating a Lock Screen widget](https://www.createwithswift.com/creating-a-lock-screen-widget-with-swiftui/) - accessory widget families, AccessoryWidgetBackground, privacy sensitive modifier
- [Swift Senpai: Understanding Container Background](https://swiftsenpai.com/development/widget-container-background/) - containerBackground migration from .background(), StandBy mode behavior
- [Swift Senpai: How to Update or Refresh a Widget](https://swiftsenpai.com/development/refreshing-widget/) - timeline refresh policies, budget system (40-70 refreshes/day)
- [Hacking with Swift: SwiftData container from widgets](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) - SwiftData app group automatic detection
- [Caleb Hearth: Using WidgetKit + SwiftData](https://calebhearth.com/using-widgetkit-with-swiftdata) - ModelContainer initialization in provider, preview crash workaround
- [Nicola De Filippo: Share SwiftData with a Widget](https://nicoladefilippo.com/share-swiftdata-with-a-widget/) - @MainActor requirement for FetchDescriptor in widget, timeline provider implementation
- [Zeke Snider: SwiftData Transaction History for Widgets](https://zekesnider.com/swift-data-transction-history/) - iOS 18 HistoryDescriptor API, NSPersistentStoreRemoteChange notifications
- [Zenn: WidgetKit with XcodeGen](https://zenn.dev/altiveinc/articles/widgetkit-with-xcodegen) - project.yml widget extension target configuration, build settings
- [Swift Forums: WidgetKit and sendability problem](https://forums.swift.org/t/widgetkit-and-sendability-problem/72915) - Swift 6 concurrency issues resolved in Xcode 16

### Tertiary (LOW confidence)
- None. All findings were verified against at least two sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - WidgetKit is Apple's only widget framework; no decisions to make
- Architecture: HIGH - WidgetBundle, TimelineProvider, containerBackground are well-documented standard patterns
- XcodeGen configuration: MEDIUM - Widget extension target type confirmed via GitHub issue, but exact XcodeGen YAML for shared source files needs validation during implementation
- Pitfalls: HIGH - Multiple sources confirm the same issues (app group entitlements, Swift 6 concurrency, containerBackground requirement)
- Lock screen widgets: HIGH - Three accessory families well-documented since iOS 16, stable API

**Research date:** 2026-02-15
**Valid until:** 2026-03-15 (stable domain -- WidgetKit API changes infrequently between iOS releases)
