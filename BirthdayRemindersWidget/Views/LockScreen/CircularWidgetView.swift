import SwiftUI
import WidgetKit

/// Lock screen widget view for accessoryCircular family.
/// Shows a gauge counting down days until the next birthday, capped at 30 days.
struct CircularWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            Gauge(value: Double(max(0, 30 - birthday.daysUntil)), in: 0...30) {
                Text("")
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
