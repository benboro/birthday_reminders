import SwiftUI

/// Friendly explanation when contact permission is denied.
///
/// Non-accusatory tone explaining why access is needed. Provides an
/// "Open Settings" button to navigate to the app's Settings page and
/// a "Try Again" button that re-checks authorization status (the user
/// may have changed it in Settings).
struct PermissionDeniedView: View {
    /// Callback to re-check authorization status after the user returns from Settings.
    var onTryAgain: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Access Needed")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Text("Birthday Reminders needs access to your contacts to find birthdays.")
                    .font(.body)

                Text("You can grant access in Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onTryAgain) {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    PermissionDeniedView(onTryAgain: {})
}
