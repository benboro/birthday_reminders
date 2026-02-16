import SwiftUI
import SwiftData

/// List of all birthday groups with create and delete functionality.
///
/// Shows each group with its name and member count. Tapping navigates to
/// GroupDetailView. Swipe-to-delete removes the group from both SwiftData
/// and iOS Contacts. A toolbar button creates new groups via an alert.
struct GroupListView: View {
    @Query(sort: \BirthdayGroup.name) private var groups: [BirthdayGroup]
    @Environment(\.modelContext) private var modelContext

    var groupSyncService: GroupSyncService
    var notificationScheduler: NotificationScheduler

    @State private var showingAddGroup = false
    @State private var newGroupName = ""
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        List {
            if groups.isEmpty {
                ContentUnavailableView {
                    Label("No Groups Yet", systemImage: "person.3")
                } description: {
                    Text("Create a group to organize your contacts and customize notification preferences.")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(groups) { group in
                    NavigationLink {
                        GroupDetailView(
                            group: group,
                            groupSyncService: groupSyncService,
                            notificationScheduler: notificationScheduler
                        )
                    } label: {
                        HStack {
                            Text(group.name)

                            Spacer()

                            Text("\(group.members.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteGroups)
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newGroupName = ""
                    showingAddGroup = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Group", isPresented: $showingAddGroup) {
            TextField("Group Name", text: $newGroupName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createGroup()
            }
            .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Enter a name for the new group.")
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

    private func createGroup() {
        let trimmedName = newGroupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        do {
            try groupSyncService.createGroup(name: trimmedName, context: modelContext)
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            let group = groups[index]
            do {
                try groupSyncService.deleteGroup(group, context: modelContext)
            } catch {
                errorMessage = "Failed to delete group: \(error.localizedDescription)"
                showingError = true
                return
            }
        }

        Task {
            await rescheduleNotifications()
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
