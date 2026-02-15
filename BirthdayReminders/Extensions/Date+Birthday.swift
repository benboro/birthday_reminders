import Foundation

extension Date {
    /// Start of the current calendar day, stripping time components.
    /// Convenience for birthday calculations that compare dates at day granularity.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
