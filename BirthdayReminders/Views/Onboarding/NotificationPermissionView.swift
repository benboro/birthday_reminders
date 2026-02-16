import SwiftUI

/// Pre-permission primer screen shown before the system notification alert.
///
/// Explains the value of notifications to maximize opt-in rates. Shown after
/// contact import completes in the onboarding flow. The user can enable
/// notifications (triggers the system dialog) or skip (can enable later in Settings).
struct NotificationPermissionView: View {
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Never Miss a Birthday")
                .font(.title2.bold())

            Text("Get notified the day before and the day of each birthday so you always have time to prepare.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Button("Enable Notifications") {
                    onEnable()
                }
                .buttonStyle(.borderedProminent)

                Button("Maybe Later") {
                    onSkip()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .padding(.horizontal)
    }
}
