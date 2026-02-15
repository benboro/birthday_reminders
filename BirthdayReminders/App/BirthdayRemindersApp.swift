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
                BirthdayListView(syncService: syncService)
            } else {
                OnboardingFlowView(syncService: syncService)
            }
        }
        .modelContainer(container)
    }
}
