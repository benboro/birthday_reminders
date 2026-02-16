import SwiftUI
import SwiftData

/// Multi-select picker for adding and removing contacts from a group.
///
/// Shows all imported contacts with a checkmark indicator for current membership.
/// Tapping a row toggles membership via GroupSyncService. Includes a search bar
/// for filtering contacts by name.
struct GroupMemberPickerView: View {
    @Query(sort: \Person.firstName) private var allPeople: [Person]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var group: BirthdayGroup
    var groupSyncService: GroupSyncService
    var notificationScheduler: NotificationScheduler

    @State private var selectedIdentifiers: Set<String> = []
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var showingError = false

    /// Current group member identifiers for initial state.
    private var currentMemberIdentifiers: Set<String> {
        Set(group.members.map(\.contactIdentifier))
    }

    /// Filter contacts by search text.
    private var filteredPeople: [Person] {
        if searchText.isEmpty {
            return allPeople
        }
        return allPeople.filter { person in
            person.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredPeople, id: \.contactIdentifier) { (person: Person) in
                Button {
                    toggleMembership(for: person)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.displayName)
                                .foregroundStyle(.primary)

                            Text(BirthdayCalculator.formattedBirthday(
                                month: person.birthdayMonth,
                                day: person.birthdayDay,
                                year: person.birthdayYear
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedIdentifiers.contains(person.contactIdentifier) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .navigationTitle("Add Members")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    Task {
                        await rescheduleNotifications()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedIdentifiers = currentMemberIdentifiers
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func toggleMembership(for person: Person) {
        if selectedIdentifiers.contains(person.contactIdentifier) {
            // Remove from group
            do {
                try groupSyncService.removeMember(person, from: group)
                selectedIdentifiers.remove(person.contactIdentifier)
            } catch {
                errorMessage = "Failed to remove member: \(error.localizedDescription)"
                showingError = true
            }
        } else {
            // Add to group
            do {
                try groupSyncService.addMember(person, to: group)
                selectedIdentifiers.insert(person.contactIdentifier)
            } catch {
                errorMessage = "Failed to add member: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    // MARK: - Notification Rescheduling

    private func rescheduleNotifications() async {
        let descriptor = FetchDescriptor<Person>()
        guard let people = try? modelContext.fetch(descriptor) else { return }
        let hour = UserDefaults.standard.object(forKey: "notificationHour") as? Int ?? 9
        let minute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? 0
        await notificationScheduler.reschedule(people: people, deliveryHour: hour, deliveryMinute: minute)
    }
}
