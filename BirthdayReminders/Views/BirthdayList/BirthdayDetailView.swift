import SwiftUI

/// Detail view for a single birthday contact.
///
/// Shows name, birthday date, and days until next birthday.
/// "Open in Contacts" button presents the iOS Contacts editor via ContactDetailBridge.
///
/// Read-only view per user decision: no call, message, age, or zodiac.
struct BirthdayDetailView: View {
    let person: Person

    @State private var showingContactEditor = false

    /// Human-readable days-until text for the detail view.
    private var daysUntilText: String {
        let days = person.daysUntilBirthday
        switch days {
        case 0:
            return "Today!"
        case 1:
            return "Tomorrow"
        default:
            return "in \(days) days"
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Name
            VStack(spacing: 8) {
                Image(systemName: "gift.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text(person.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }

            // Birthday info
            VStack(spacing: 12) {
                Label {
                    Text(BirthdayCalculator.formattedBirthday(
                        month: person.birthdayMonth,
                        day: person.birthdayDay,
                        year: person.birthdayYear
                    ))
                    .font(.title3)
                } icon: {
                    Image(systemName: "calendar")
                }

                Label {
                    Text(daysUntilText)
                        .font(.title3)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "clock")
                }
            }
            .foregroundStyle(.secondary)

            Spacer()

            // Open in Contacts
            Button {
                showingContactEditor = true
            } label: {
                Label("Open in Contacts", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
        .navigationTitle("Birthday")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContactEditor) {
            ContactDetailBridge(contactIdentifier: person.contactIdentifier)
        }
    }
}
