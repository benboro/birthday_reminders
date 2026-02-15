import SwiftUI
import SwiftData

@main
struct BirthdayRemindersApp: App {
    let container: ModelContainer

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
            ContentView()
        }
        .modelContainer(container)
    }
}

/// Placeholder until the real UI is wired up in later plans.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Birthday Reminders")
                .font(.title)
                .navigationTitle("Birthdays")
        }
    }
}
