import Foundation

enum DateFormatterService {
    /// API date format: yyyy-MM-dd (Europe/Berlin timezone)
    static let apiDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        return formatter
    }()

    /// Display date format: dd.MM.yyyy
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    /// Compact date format: E, d. MMM (German locale)
    static let compactDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "E, d. MMM"
        return formatter
    }()

    /// Full date format: EEEE, d. MMMM yyyy (German locale)
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
}
