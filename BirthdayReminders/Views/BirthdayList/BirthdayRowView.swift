import SwiftUI

/// A single row in the birthday list showing name, formatted date, and days until.
///
/// Minimal design per user decision: name + date + days-until only.
/// No photos, no age, no zodiac.
/// Today's birthdays get a highlighted background to stand out (user decision).
struct BirthdayRowView: View {
    let person: Person

    /// Whether this person's birthday is today.
    private var isToday: Bool {
        person.daysUntilBirthday == 0
    }

    /// Human-readable days-until text.
    private var daysUntilText: String {
        let days = person.daysUntilBirthday
        switch days {
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            return "in \(days) days"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.body)
                    .fontWeight(isToday ? .semibold : .regular)

                Text(BirthdayCalculator.formattedBirthday(
                    month: person.birthdayMonth,
                    day: person.birthdayDay,
                    year: person.birthdayYear
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(daysUntilText)
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? Color.accentColor : .secondary)
        }
        .padding(.vertical, 2)
        .listRowBackground(
            isToday ? Color.accentColor.opacity(0.1) : nil
        )
    }
}
