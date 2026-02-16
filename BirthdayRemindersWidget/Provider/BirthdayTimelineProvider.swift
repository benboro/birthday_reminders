@preconcurrency import WidgetKit
import SwiftUI
import SwiftData

/// Provides timeline entries for birthday widgets by querying the shared SwiftData store.
///
/// Uses the same app group container (group.com.birthdayreminders) as the main app
/// to read Person records. Refreshes at midnight when days-until values change.
struct BirthdayTimelineProvider: TimelineProvider {
    typealias Entry = BirthdayTimelineEntry

    /// Creates a ModelContainer pointing at the shared app group database.
    private var sharedModelContainer: ModelContainer {
        let schema = Schema([Person.self, BirthdayGroup.self])
        let config = ModelConfiguration(
            "BirthdayReminders",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.birthdayreminders")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create widget ModelContainer: \(error)")
        }
    }

    func placeholder(in context: Context) -> BirthdayTimelineEntry {
        BirthdayTimelineEntry.placeholder
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (BirthdayTimelineEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayTimelineEntry>) -> Void) {
        let entry = fetchEntry()
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    /// Fetches upcoming birthdays from the shared SwiftData store, sorted by days until birthday.
    @MainActor
    private func fetchEntry() -> BirthdayTimelineEntry {
        let container = sharedModelContainer
        let descriptor = FetchDescriptor<Person>()
        let people = (try? container.mainContext.fetch(descriptor)) ?? []
        let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
        let birthdays = sorted.prefix(8).map { person in
            WidgetBirthday(
                name: person.displayName,
                daysUntil: person.daysUntilBirthday,
                month: person.birthdayMonth,
                day: person.birthdayDay,
                year: person.birthdayYear
            )
        }
        return BirthdayTimelineEntry(date: .now, upcomingBirthdays: birthdays)
    }
}
