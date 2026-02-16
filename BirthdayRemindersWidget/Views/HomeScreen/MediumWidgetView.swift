import SwiftUI

/// Home screen widget view for systemMedium family.
/// Shows the next 3 upcoming birthdays with name and days until.
struct MediumWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if entry.upcomingBirthdays.isEmpty {
            Text("No upcoming birthdays")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.upcomingBirthdays.prefix(3).enumerated()), id: \.element.id) { index, birthday in
                    HStack {
                        Text(birthday.name)
                            .font(.subheadline)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(birthday.daysUntilText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if index < min(entry.upcomingBirthdays.count, 3) - 1 {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
