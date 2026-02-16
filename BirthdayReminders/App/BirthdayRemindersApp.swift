import SwiftUI
import SwiftData
@preconcurrency import UserNotifications

@main
struct BirthdayRemindersApp: App {
    let container: ModelContainer
    @State private var syncService = ContactSyncService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    private let notificationScheduler = NotificationScheduler()
    private let notificationDelegate = NotificationDelegate()

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

        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                BirthdayListView(syncService: syncService, notificationScheduler: notificationScheduler)
            } else {
                OnboardingFlowView(syncService: syncService, notificationScheduler: notificationScheduler)
            }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    let context = container.mainContext
                    let descriptor = FetchDescriptor<Person>()
                    guard let people = try? context.fetch(descriptor) else { return }
                    let hour = UserDefaults.standard.object(forKey: "notificationHour") as? Int ?? 9
                    let minute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? 0
                    await notificationScheduler.reschedule(
                        people: people,
                        deliveryHour: hour,
                        deliveryMinute: minute
                    )
                }
            }
        }
    }
}
