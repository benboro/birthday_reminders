import SwiftUI
import SwiftData

/// Detail view for a single birthday group showing name, notification preference, and members.
///
/// Supports renaming the group, changing notification preference (day-of, day-before, both),
/// viewing and removing members, and presenting a member picker to add contacts.
/// All group mutations trigger notification rescheduling.
struct GroupDetailView: View {
    @Bindable var group: BirthdayGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var groupSyncService: GroupSyncService
    var notificationScheduler: NotificationScheduler

    @State private var isEditingName = false
    @State private var editedName: String = ""
    @State private var showingMemberPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        List {
            // MARK: - Name Section
            Section("Name") {
                HStack {
                    Text(group.name)

                    Spacer()

                    Button("Rename") {
                        editedName = group.name
                        isEditingName = true
                    }
                    .font(.subheadline)
                }
            }

            // MARK: - Notification Preference Section
            Section("Notification Preference") {
                Picker("Preference", selection: $group.notificationPreference) {
                    ForEach(NotificationPreference.allCases, id: \.self) { preference in
                        Text(preference.rawValue).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: group.notificationPreference) {
                    Task {
                        await rescheduleNotifications()
                    }
                }
            }

            // MARK: - Members Section
            Section {
                let sortedMembers = group.members.sorted { $0.displayName < $1.displayName }

                if sortedMembers.isEmpty {
                    Text("No members yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedMembers, id: \.contactIdentifier) { person in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.displayName)

                                Text(BirthdayCalculator.formattedBirthday(
                                    month: person.birthdayMonth,
                                    day: person.birthdayDay,
                                    year: person.birthdayYear
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: removeMembers)
                }

                Button {
                    showingMemberPicker = true
                } label: {
                    Label("Add Members", systemImage: "person.badge.plus")
                }
            } header: {
                Text("Members (\(group.members.count))")
            }

            // MARK: - Delete Section
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Group", systemImage: "trash")
                }
            }
        }
        .navigationTitle(group.name)
        .sheet(isPresented: $showingMemberPicker) {
            NavigationStack {
                GroupMemberPickerView(
                    group: group,
                    groupSyncService: groupSyncService,
                    notificationScheduler: notificationScheduler
                )
            }
        }
        .alert("Rename Group", isPresented: $isEditingName) {
            TextField("Group Name", text: $editedName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                renameGroup()
            }
            .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Enter a new name for this group.")
        }
        .confirmationDialog(
            "Delete \"\(group.name)\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteGroup()
            }
        } message: {
            Text("This will remove the group. Your contacts will not be deleted.")
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

    private func renameGroup() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        do {
            try groupSyncService.renameGroup(group, to: trimmedName, context: modelContext)
        } catch {
            errorMessage = "Failed to rename group: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func removeMembers(at offsets: IndexSet) {
        let sortedMembers = group.members.sorted { $0.displayName < $1.displayName }

        for index in offsets {
            let person = sortedMembers[index]
            do {
                try groupSyncService.removeMember(person, from: group)
            } catch {
                errorMessage = "Failed to remove member: \(error.localizedDescription)"
                showingError = true
                return
            }
        }

        Task {
            await rescheduleNotifications()
        }
    }

    private func deleteGroup() {
        do {
            try groupSyncService.deleteGroup(group, context: modelContext)
            Task {
                await rescheduleNotifications()
            }
            dismiss()
        } catch {
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
            showingError = true
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
