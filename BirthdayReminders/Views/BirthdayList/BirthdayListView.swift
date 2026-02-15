import SwiftUI
import SwiftData

/// Main birthday list screen showing contacts grouped by proximity to their next birthday.
///
/// Fetches all Person records via @Query and sorts in-memory by daysUntilBirthday.
/// Grouped into four sections: Today, This Week, This Month, Later.
/// Always-visible search bar filters by display name.
///
/// IMPORTANT: @Query cannot sort on computed properties (daysUntilBirthday is computed).
/// The birthdayMonth sort descriptor provides a rough ordering; real sort is in-memory.
struct BirthdayListView: View {
    @Query(sort: \Person.birthdayMonth) private var allPeople: [Person]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingSettings = false

    var syncService: ContactSyncService

    // MARK: - Computed Properties

    /// Filter people by search text on display name.
    private var filteredPeople: [Person] {
        if searchText.isEmpty {
            return allPeople
        }
        return allPeople.filter { person in
            person.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Group filtered people into sections ordered by BirthdaySection.allCases,
    /// with people sorted by daysUntilBirthday ascending within each section.
    private var sections: [(BirthdaySection, [Person])] {
        let grouped = Dictionary(grouping: filteredPeople) { person in
            BirthdayCalculator.section(for: person.daysUntilBirthday)
        }
        return BirthdaySection.allCases.compactMap { section in
            guard let people = grouped[section], !people.isEmpty else { return nil }
            let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
            return (section, sorted)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if allPeople.isEmpty {
                    EmptyStateView(syncService: syncService)
                } else {
                    birthdayList
                }
            }
            .navigationTitle("Birthdays")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search contacts"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsPlaceholderView(syncService: syncService)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .navigationDestination(for: Person.self) { person in
                BirthdayDetailView(person: person)
            }
        }
    }

    // MARK: - Subviews

    private var birthdayList: some View {
        List {
            ForEach(sections, id: \.0) { section, people in
                Section(section.rawValue) {
                    ForEach(people) { person in
                        NavigationLink(value: person) {
                            BirthdayRowView(person: person)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
