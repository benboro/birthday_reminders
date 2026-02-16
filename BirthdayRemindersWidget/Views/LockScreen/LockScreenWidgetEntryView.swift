import SwiftUI
import WidgetKit

/// Entry view dispatcher for lock screen widgets.
/// Routes to accessory-specific views based on the current widget family.
struct LockScreenWidgetEntryView: View {
    let entry: BirthdayTimelineEntry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .accessoryCircular:
                CircularWidgetView(entry: entry)
            case .accessoryRectangular:
                RectangularWidgetView(entry: entry)
            case .accessoryInline:
                InlineWidgetView(entry: entry)
            default:
                EmptyView()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
