import SwiftUI
import SwiftData
@preconcurrency import UserNotifications

/// Notification configuration section for the Settings screen.
///
/// Provides a delivery time picker backed by @AppStorage and displays
/// the current notification permission status with actionable recovery.
/// Changing the delivery time immediately reschedules all notifications.
struct NotificationSettingsView: View {
    var notificationScheduler: NotificationScheduler

    @AppStorage("notificationHour") private var notificationHour: Int = 9
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @Environment(\.modelContext) private var modelContext

    @State private var authStatus: UNAuthorizationStatus?

    /// Bridges hour/minute integers to a Date for SwiftUI DatePicker.
    private var deliveryTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = notificationHour
                components.minute = notificationMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                notificationHour = components.hour ?? 9
                notificationMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        Section("Notifications") {
            DatePicker(
                "Delivery Time",
                selection: deliveryTime,
                displayedComponents: .hourAndMinute
            )

            permissionStatusRow
        }
        .task {
            authStatus = await notificationScheduler.checkStatus()
        }
        .onChange(of: notificationHour) { _, newHour in
            Task {
                await rescheduleAll(hour: newHour, minute: notificationMinute)
            }
        }
        .onChange(of: notificationMinute) { _, newMinute in
            Task {
                await rescheduleAll(hour: notificationHour, minute: newMinute)
            }
        }
    }

    // MARK: - Permission Status

    @ViewBuilder
    private var permissionStatusRow: some View {
        switch authStatus {
        case .authorized:
            Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .denied:
            HStack {
                Label("Notifications Disabled", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)

                Spacer()

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.footnote)
            }

        case .notDetermined:
            HStack {
                Label("Notifications Not Set Up", systemImage: "bell.slash")
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Enable") {
                    Task {
                        _ = await notificationScheduler.requestPermission()
                        authStatus = await notificationScheduler.checkStatus()
                    }
                }
                .font(.footnote)
            }

        default:
            Label("Notifications Unavailable", systemImage: "bell.slash")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Rescheduling

    /// Fetches all Person records and reschedules notifications at the given time.
    private func rescheduleAll(hour: Int, minute: Int) async {
        let descriptor = FetchDescriptor<Person>()
        guard let people = try? modelContext.fetch(descriptor) else { return }
        await notificationScheduler.reschedule(
            people: people,
            deliveryHour: hour,
            deliveryMinute: minute
        )
    }
}
