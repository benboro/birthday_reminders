import SwiftUI

/// Pre-permission screen explaining why the app needs contact access (IMPT-02).
///
/// Shows a contextual explanation before triggering the system permission dialog.
/// Reinforces the privacy promise: data stays on-device and is never shared
/// (SECR-01, SECR-02).
struct PermissionRequestView: View {
    /// Callback when the user taps "Allow Access". The parent view
    /// triggers the actual system permission request.
    var onRequestAccess: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Contact Access")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Text("Birthday Reminders reads your contacts to find birthdays.")
                    .font(.body)

                Text("Your data stays on this device and is never shared.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onRequestAccess) {
                Text("Allow Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    PermissionRequestView(onRequestAccess: {})
}
