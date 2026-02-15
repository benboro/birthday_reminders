import Contacts
import ContactsUI
import SwiftData
import os

/// Stateless mapper between CNContact and the app's Person model.
///
/// All contact property access goes through this bridge to prevent
/// CNPropertyNotFetchedException crashes. The keysToFetch() method is
/// the single source of truth for which CNContact properties are loaded.
struct ContactBridge {

    // MARK: - Keys

    /// Single canonical list of all CNContact keys the app needs.
    /// Adding a new property access without updating this list will crash.
    static func keysToFetch() -> [CNKeyDescriptor] {
        [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactNonGregorianBirthdayKey as CNKeyDescriptor,
            // Required for "Open in Contacts" via CNContactViewController
            CNContactViewController.descriptorForRequiredKeys(),
        ]
    }

    // MARK: - Upsert

    /// Create or update a Person from a CNContact.
    /// Contacts without a resolvable birthday are silently skipped.
    static func upsert(from contact: CNContact, into context: ModelContext) {
        guard let birthday = resolveBirthday(from: contact) else {
            Logger.sync.debug("Skipping contact without birthday: \(contact.identifier, privacy: .private)")
            return
        }

        let identifier = contact.identifier
        let descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { $0.contactIdentifier == identifier }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                // Update existing record
                existing.firstName = contact.givenName
                existing.lastName = contact.familyName
                existing.birthdayMonth = birthday.month
                existing.birthdayDay = birthday.day
                existing.birthdayYear = birthday.year
                existing.birthdayCalendarId = birthday.calendarId
                Logger.sync.debug("Updated contact: \(contact.givenName, privacy: .private)")
            } else {
                // Insert new record
                let person = Person(
                    contactIdentifier: identifier,
                    firstName: contact.givenName,
                    lastName: contact.familyName,
                    birthdayMonth: birthday.month,
                    birthdayDay: birthday.day,
                    birthdayYear: birthday.year,
                    birthdayCalendarId: birthday.calendarId
                )
                context.insert(person)
                Logger.sync.debug("Inserted contact: \(contact.givenName, privacy: .private)")
            }
        } catch {
            Logger.sync.error("Failed to fetch/upsert contact: \(error.localizedDescription)")
        }
    }

    // MARK: - Birthday Resolution

    /// Resolve birthday from a CNContact, preferring Gregorian, falling back to non-Gregorian.
    /// Returns nil if neither source has a valid month and day.
    static func resolveBirthday(from contact: CNContact) -> (month: Int, day: Int, year: Int?, calendarId: String?)? {
        // Prefer Gregorian birthday
        if let bday = contact.birthday, let month = bday.month, let day = bday.day {
            return (month: month, day: day, year: bday.year, calendarId: nil)
        }

        // Fall back to non-Gregorian birthday, convert to Gregorian month/day
        if let ngBday = contact.nonGregorianBirthday,
           let calendar = ngBday.calendar,
           let date = calendar.date(from: ngBday) {
            let gregorian = Calendar(identifier: .gregorian)
            let components = gregorian.dateComponents([.month, .day, .year], from: date)
            if let month = components.month, let day = components.day {
                return (month: month, day: day, year: components.year, calendarId: calendar.identifier.debugDescription)
            }
        }

        return nil
    }

    // MARK: - Stale Removal

    /// Remove Person records whose contactIdentifier is no longer in the known set.
    /// Call after a full import to clean up deleted contacts.
    static func removeStale(knownIdentifiers: Set<String>, context: ModelContext) {
        let descriptor = FetchDescriptor<Person>()
        do {
            let allPeople = try context.fetch(descriptor)
            for person in allPeople {
                if !knownIdentifiers.contains(person.contactIdentifier) {
                    context.delete(person)
                    Logger.sync.debug("Removed stale contact: \(person.contactIdentifier, privacy: .private)")
                }
            }
        } catch {
            Logger.sync.error("Failed to fetch people for stale removal: \(error.localizedDescription)")
        }
    }
}
