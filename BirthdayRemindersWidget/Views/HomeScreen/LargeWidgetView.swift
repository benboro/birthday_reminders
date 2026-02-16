import SwiftUI

/// Home screen widget view for systemLarge family.
/// Shows the next 7 upcoming birthdays with name, formatted date, and days until.
/// Today's birthdays are highlighted with an accent color background.
struct LargeWidgetView: View {
    let entry: BirthdayTimelineEntry

    var body: some View {
        if entry.upcomingBirthdays.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "gift")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No upcoming birthdays")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Upcoming Birthdays")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ForEach(Array(entry.upcomingBirthdays.prefix(7).enumerated()), id: \.element.id) { index, birthday in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(birthday.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(BirthdayCalculator.formattedBirthday(month: birthday.month, day: birthday.day, year: birthday.year))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(birthday.daysUntilText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        birthday.daysUntil == 0
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )

                    if index < min(entry.upcomingBirthdays.count, 7) - 1 {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
