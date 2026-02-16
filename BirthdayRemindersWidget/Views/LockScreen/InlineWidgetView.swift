import SwiftUI
import WidgetKit

/// Lock screen widget view for accessoryInline family.
/// Shows a single line of text with a gift icon and the next birthday name/countdown.
struct InlineWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            let icon = birthday.daysUntil == 0 ? "gift.fill" : "gift"
            let fullText = birthday.daysUntil == 0
                ? "\(birthday.name)'s birthday!"
                : "\(birthday.name) \(birthday.daysUntilText)"
            let shortText = birthday.daysUntil == 0
                ? "\(birthday.firstName)'s birthday!"
                : "\(birthday.firstName) \(birthday.daysUntilText)"

            ViewThatFits {
                Text("\(Image(systemName: icon)) \(fullText)")
                Text("\(Image(systemName: icon)) \(shortText)")
            }
        } else {
            Text("No upcoming birthdays")
        }
    }
}
