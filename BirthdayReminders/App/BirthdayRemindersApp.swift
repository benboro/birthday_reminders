import SwiftUI
import SwiftData

@main
struct BirthdayRemindersApp: App {
    let container: ModelContainer
    @State private var syncService = ContactSyncService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let config = ModelConfiguration(
            "BirthdayReminders",
            schema: Schema([Person.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.birthdayreminders")
        )
        do {
            container = try ModelContainer(for: Person.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                BirthdayListPlaceholderView()
            } else {
                OnboardingFlowView(syncService: syncService)
            }
        }
        .modelContainer(container)
    }
}

/// Placeholder until the real birthday list is built in Plan 03.
struct BirthdayListPlaceholderView: View {
    var body: some View {
        NavigationStack {
            Text("Birthday List")
                .font(.title)
                .foregroundStyle(.secondary)
                .navigationTitle("Birthdays")
        }
    }
}
