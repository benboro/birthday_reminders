import Foundation
import SwiftData

/// A person with a birthday, imported from iOS Contacts.
///
/// Birthday is stored as decomposed Int fields rather than DateComponents
/// to avoid SwiftData storage issues with complex Foundation types.
@Model
final class Person: Identifiable {

    // MARK: - Identity

    /// The CNContact.identifier from iOS Contacts. Used for deduplication on re-import.
    @Attribute(.unique)
    var contactIdentifier: String

    // MARK: - Display

    var firstName: String
    var lastName: String

    // MARK: - Birthday (decomposed from DateComponents)

    /// Birthday month, 1-12.
    var birthdayMonth: Int

    /// Birthday day, 1-31.
    var birthdayDay: Int

    /// Birth year, nil when the contact has no year set.
    var birthdayYear: Int?

    /// Calendar identifier for non-Gregorian birthdays. Nil means Gregorian.
    var birthdayCalendarId: String?

    // MARK: - Groups

    /// Groups this person belongs to. Inverse side of BirthdayGroup.members.
    /// Default empty array for SwiftData many-to-many compatibility.
    var groups: [BirthdayGroup] = []

    // MARK: - Computed Properties

    /// Full display name, handling empty first or last name gracefully.
    var displayName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// The next occurrence of this person's birthday.
    var nextBirthdayDate: Date {
        BirthdayCalculator.nextBirthday(month: birthdayMonth, day: birthdayDay)
    }

    /// Number of days until the next birthday.
    var daysUntilBirthday: Int {
        BirthdayCalculator.daysUntil(month: birthdayMonth, day: birthdayDay)
    }

    /// Which list section this person belongs to based on days until birthday.
    var birthdaySection: BirthdaySection {
        BirthdayCalculator.section(for: daysUntilBirthday)
    }

    // MARK: - Init

    init(
        contactIdentifier: String,
        firstName: String,
        lastName: String,
        birthdayMonth: Int,
        birthdayDay: Int,
        birthdayYear: Int? = nil,
        birthdayCalendarId: String? = nil
    ) {
        self.contactIdentifier = contactIdentifier
        self.firstName = firstName
        self.lastName = lastName
        self.birthdayMonth = birthdayMonth
        self.birthdayDay = birthdayDay
        self.birthdayYear = birthdayYear
        self.birthdayCalendarId = birthdayCalendarId
    }
}
