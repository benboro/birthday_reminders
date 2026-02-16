import SwiftUI
import SwiftData

/// Steps in the onboarding state machine.
///
/// Drives the welcome -> permission -> import -> notification primer -> complete flow.
/// Permission denied is an alternate path with recovery options.
enum OnboardingStep: Equatable {
    case welcome
    case permissionRequest
    case importing
    case notificationPermission
    case complete
    case permissionDenied
}

/// Container view managing the onboarding flow state machine.
///
/// Holds the current step and transitions between sub-views based on
/// user actions and ContactSyncService state. Stores completion in
/// @AppStorage so the app routes to the birthday list on subsequent launches.
struct OnboardingFlowView: View {
    @State private var step: OnboardingStep = .welcome
    @Bindable var syncService: ContactSyncService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    let notificationScheduler: NotificationScheduler

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeView {
                    step = .permissionRequest
                }

            case .permissionRequest:
                PermissionRequestView {
                    Task {
                        let granted = await syncService.requestAccess()
                        if granted {
                            step = .importing
                        } else {
                            // Check if limited access was granted (treated as success)
                            if syncService.authState == .authorized || syncService.authState == .limited {
                                step = .importing
                            } else {
                                step = .permissionDenied
                            }
                        }
                    }
                }

            case .importing:
                ImportProgressView(syncService: syncService) {
                    step = .notificationPermission
                }

            case .notificationPermission:
                NotificationPermissionView(
                    onEnable: {
                        Task {
                            let granted = await notificationScheduler.requestPermission()
                            if granted {
                                let descriptor = FetchDescriptor<Person>()
                                if let people = try? modelContext.fetch(descriptor) {
                                    await notificationScheduler.reschedule(
                                        people: people,
                                        deliveryHour: 9,
                                        deliveryMinute: 0
                                    )
                                }
                            }
                            hasCompletedOnboarding = true
                            step = .complete
                        }
                    },
                    onSkip: {
                        hasCompletedOnboarding = true
                        step = .complete
                    }
                )

            case .complete:
                // Handled by the parent -- once hasCompletedOnboarding is true,
                // BirthdayRemindersApp switches to the main list view.
                EmptyView()

            case .permissionDenied:
                PermissionDeniedView {
                    syncService.checkAuthorizationStatus()
                    if syncService.authState == .authorized || syncService.authState == .limited {
                        step = .importing
                    }
                    // If still denied, stay on this screen
                }
            }
        }
        .animation(.easeInOut, value: step)
    }
}
