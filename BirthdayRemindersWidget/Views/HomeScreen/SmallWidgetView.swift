import SwiftUI

/// Home screen widget view for systemSmall family.
/// Shows the next 1 upcoming birthday with name, days until, and formatted date.
struct SmallWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if let birthday = entry.upcomingBirthdays.first {
            VStack(alignment: .leading, spacing: 4) {
                Text(birthday.daysUntilText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(birthday.daysUntil == 0 ? Color.accentColor : .secondary)

                Text(birthday.name)
                    .font(.headline)
                    .lineLimit(2)

                Text(BirthdayCalculator.formattedBirthday(month: birthday.month, day: birthday.day, year: birthday.year))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Text("No upcoming birthdays")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
