import SwiftUI
import WidgetKit

/// Lock screen widget view for accessoryInline family.
/// Shows a single line of text with a gift icon and the next birthday name/countdown.
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
