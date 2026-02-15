import SwiftUI

/// Steps in the onboarding state machine.
///
/// Drives the welcome -> permission -> import -> complete flow.
/// Permission denied is an alternate path with recovery options.
enum OnboardingStep: Equatable {
    case welcome
    case permissionRequest
    case importing
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
                    hasCompletedOnboarding = true
                    step = .complete
                }

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
