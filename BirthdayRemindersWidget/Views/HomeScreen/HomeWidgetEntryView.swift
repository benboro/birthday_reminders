import SwiftUI
import WidgetKit

/// Entry view dispatcher for home screen widgets.
/// Routes to size-specific views based on the current widget family.
struct HomeWidgetEntryView: View {
    let entry: BirthdayTimelineEntry

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
