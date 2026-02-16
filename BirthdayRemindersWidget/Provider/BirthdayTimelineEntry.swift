import WidgetKit

/// A single upcoming birthday, carried as a plain value type in the timeline entry.
/// Uses value semantics (not SwiftData @Model) for safe serialization in WidgetKit.
struct WidgetBirthday: Identifiable {
    let id = UUID()
    let name: String
    let firstName: String
    let daysUntil: Int
    let month: Int
    let day: Int
    let year: Int?

    /// Human-readable text for how far away the birthday is.
    var daysUntilText: String {
        switch daysUntil {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "in \(daysUntil) days"
        }
    }
}

/// Timeline entry containing a snapshot of upcoming birthdays for widget rendering.
struct BirthdayTimelineEntry: TimelineEntry {
    let date: Date
    let upcomingBirthdays: [WidgetBirthday]

    /// Sample data for widget placeholders and previews.
    static var placeholder: BirthdayTimelineEntry {
        BirthdayTimelineEntry(
            date: .now,
            upcomingBirthdays: [
                WidgetBirthday(name: "John Doe", firstName: "John", daysUntil: 0, month: 2, day: 15, year: 1990),
                WidgetBirthday(name: "Jane Smith", firstName: "Jane", daysUntil: 3, month: 2, day: 18, year: nil),
                WidgetBirthday(name: "Bob Wilson", firstName: "Bob", daysUntil: 7, month: 2, day: 22, year: 1985),
            ]
        )
    }
}
