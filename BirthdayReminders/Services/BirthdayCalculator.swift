import Foundation

/// Pure stateless functions for all birthday date math.
/// Handles nil year, Feb 29 in non-leap years, and section categorization.
enum BirthdayCalculator {

    /// Calculate the next occurrence of a birthday from a reference date.
    /// For Feb 29 in non-leap years, returns March 1 of that year.
    static func nextBirthday(month: Int, day: Int, from referenceDate: Date = .now) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let currentYear = calendar.component(.year, from: today)

        // Try this year first
        if let candidate = resolvedDate(month: month, day: day, year: currentYear, calendar: calendar),
           candidate >= today {
            return candidate
        }

        // Otherwise use next year
        if let candidate = resolvedDate(month: month, day: day, year: currentYear + 1, calendar: calendar) {
            return candidate
        }

        // Fallback (should never happen with valid month/day)
        return today
    }

    /// Days until the next birthday occurrence, measured from start-of-day.
    static func daysUntil(month: Int, day: Int, from referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let next = nextBirthday(month: month, day: day, from: referenceDate)
        return calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    /// Format the birthday for display.
    /// With year: "March 15, 1990". Without year: "March 15".
    static func formattedBirthday(month: Int, day: Int, year: Int?) -> String {
        var components = DateComponents(month: month, day: day)
        // Use a placeholder year for formatting when year is unknown
        components.year = year ?? 2000
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return "" }

        let formatter = DateFormatter()
        if year != nil {
            formatter.dateFormat = "MMMM d, yyyy"
        } else {
            formatter.dateFormat = "MMMM d"
        }
        return formatter.string(from: date)
    }

    /// Categorize a days-until value into a display section.
    static func section(for daysUntil: Int) -> BirthdaySection {
        switch daysUntil {
        case 0: return .today
        case 1...7: return .thisWeek
        case 8...30: return .thisMonth
        default: return .later
        }
    }

    // MARK: - Private Helpers

    /// Resolve a month/day/year to a concrete Date, handling Feb 29 in non-leap years
    /// by mapping to March 1.
    private static func resolvedDate(month: Int, day: Int, year: Int, calendar: Calendar) -> Date? {
        // Handle Feb 29 in non-leap years
        if month == 2 && day == 29 {
            guard let feb1 = calendar.date(from: DateComponents(year: year, month: 2, day: 1)),
                  let range = calendar.range(of: .day, in: .month, for: feb1) else {
                return nil
            }
            if !range.contains(29) {
                // Non-leap year: map Feb 29 birthday to March 1
                return calendar.date(from: DateComponents(year: year, month: 3, day: 1))
            }
        }

        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}

/// Section categories for grouping birthdays in the list view.
enum BirthdaySection: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case later = "Later"

    var id: String { rawValue }
}
