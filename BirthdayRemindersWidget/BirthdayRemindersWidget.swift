import SwiftUI
import WidgetKit

/// Widget bundle entry point registering both home screen and lock screen widgets.
@main
struct BirthdayRemindersWidgetBundle: WidgetBundle {
    var body: some Widget {
        BirthdayHomeWidget()
        BirthdayLockScreenWidget()
    }
}

/// Home screen widget showing upcoming birthdays in small, medium, and large sizes.
struct BirthdayHomeWidget: Widget {
    let kind: String = "BirthdayHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()) { entry in
            HomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Birthdays")
        .description("See upcoming birthdays at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Lock screen widget showing the next upcoming birthday in circular, rectangular, and inline sizes.
struct BirthdayLockScreenWidget: Widget {
    let kind: String = "BirthdayLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Birthday")
        .description("See the next upcoming birthday.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
