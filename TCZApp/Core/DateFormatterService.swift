import Foundation

/// Thread-safe date formatting service using thread-local storage.
/// DateFormatter is NOT thread-safe per Apple documentation, so each thread
/// gets its own cached instance.
enum DateFormatterService {
    // Thread-local storage keys
    private static let apiDateKey = "DateFormatterService.apiDate"
    private static let displayDateKey = "DateFormatterService.displayDate"
    private static let compactDateKey = "DateFormatterService.compactDate"
    private static let fullDateKey = "DateFormatterService.fullDate"

    /// API date format: yyyy-MM-dd (Europe/Berlin timezone)
    /// Thread-safe: uses thread-local storage
    static var apiDate: DateFormatter {
        if let existing = Thread.current.threadDictionary[apiDateKey] as? DateFormatter {
            return existing
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        Thread.current.threadDictionary[apiDateKey] = formatter
        return formatter
    }

    /// Display date format: dd.MM.yyyy
    /// Thread-safe: uses thread-local storage
    static var displayDate: DateFormatter {
        if let existing = Thread.current.threadDictionary[displayDateKey] as? DateFormatter {
            return existing
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        Thread.current.threadDictionary[displayDateKey] = formatter
        return formatter
    }

    /// Compact date format: E, d. MMM (German locale)
    /// Thread-safe: uses thread-local storage
    static var compactDate: DateFormatter {
        if let existing = Thread.current.threadDictionary[compactDateKey] as? DateFormatter {
            return existing
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "E, d. MMM"
        Thread.current.threadDictionary[compactDateKey] = formatter
        return formatter
    }

    /// Full date format: EEEE, d. MMMM yyyy (German locale)
    /// Thread-safe: uses thread-local storage
    static var fullDate: DateFormatter {
        if let existing = Thread.current.threadDictionary[fullDateKey] as? DateFormatter {
            return existing
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        Thread.current.threadDictionary[fullDateKey] = formatter
        return formatter
    }
}
