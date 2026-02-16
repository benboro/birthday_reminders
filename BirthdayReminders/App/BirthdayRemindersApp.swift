import SwiftUI
import SwiftData
import WidgetKit
@preconcurrency import UserNotifications

@main
struct BirthdayRemindersApp: App {
    let container: ModelContainer
    @State private var syncService = ContactSyncService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    private let notificationScheduler = NotificationScheduler()
    private let notificationDelegate = NotificationDelegate()
    private let groupSyncService = GroupSyncService()

    init() {
        let config = ModelConfiguration(
            "BirthdayReminders",
            schema: Schema([Person.self, BirthdayGroup.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.birthdayreminders")
        )
        do {
            container = try ModelContainer(for: Person.self, BirthdayGroup.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    BirthdayListView(syncService: syncService, notificationScheduler: notificationScheduler, groupSyncService: groupSyncService)
                } else {
                    OnboardingFlowView(syncService: syncService, notificationScheduler: notificationScheduler)
                }
            }
            .task {
                syncService.groupSyncService = groupSyncService
                syncService.onImportComplete = { [container, notificationScheduler] _ in
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
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
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
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
        .modelContainer(container)
    }
}
