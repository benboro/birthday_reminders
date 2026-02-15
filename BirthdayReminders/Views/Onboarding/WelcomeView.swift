import SwiftUI

/// First-launch welcome screen explaining the app purpose.
///
/// Clean, friendly design with app name prominently displayed and
/// a brief explanation of what the app does. Tapping "Get Started"
/// advances the onboarding flow to the permission request step.
struct WelcomeView: View {
    /// Callback when the user taps "Get Started".
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "gift.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Birthday Reminders")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Never miss a birthday. Import your contacts and see upcoming birthdays at a glance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
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
    WelcomeView(onContinue: {})
}
