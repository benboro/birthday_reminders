import SwiftUI
import WidgetKit

/// Lock screen widget view for accessoryRectangular family.
/// Shows the next birthday name and days until, with privacy redaction on the name.
struct RectangularWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            VStack(alignment: .leading, spacing: 2) {
                Text(birthday.name)
                    .font(.headline)
                    .lineLimit(1)
                    .privacySensitive()

                if birthday.daysUntil == 0 {
                    Text("\(Image(systemName: "gift.fill")) \(birthday.daysUntilText)")
                        .font(.caption)
                } else {
                    Text(birthday.daysUntilText)
                        .font(.caption)
                }
            }
        } else {
            Text("No upcoming birthdays")
                .font(.caption)
        }
    }
}
