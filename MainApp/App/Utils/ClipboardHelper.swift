import Foundation
import AppKit

struct ClipboardHelper {
    static func copyTimestamp(for timeZone: SavedTimeZone, config: AppConfig) -> String {
        let date = Date()
        var stringToCopy = ""
        
        // When calculating timestamp for a different timezone, we don't necessarily shift the Unix timestamp (since Unix time is absolute), 
        // but if the user wants the local time represented as an ISO string, we format it with that timezone.
        // If they want Unix time, it's generally universal, but we should make sure we're giving them what they expect.
        // Usually, a timestamp represents an absolute point in time.
        
        switch config.timestampFormat {
        case .seconds:
            stringToCopy = String(Int(date.timeIntervalSince1970))
        case .milliseconds:
            stringToCopy = String(Int(date.timeIntervalSince1970 * 1000))
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = timeZone.timeZone
            stringToCopy = formatter.string(from: date)
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(stringToCopy, forType: .string)
        
        return stringToCopy
    }
}

enum DateFormatterCache {
    private static var timeFormatters: [String: DateFormatter] = [:]
    private static var dateFormatters: [String: DateFormatter] = [:]
    private static var shortTimeFormatters: [String: DateFormatter] = [:]

    static func timeFormatter(for zone: TimeZone, format: TimeFormat) -> DateFormatter {
        let key = "time|\(zone.identifier)|\(format.rawValue)"
        if let cached = timeFormatters[key] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.timeZone = zone

        switch format {
        case .system:
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
        case .format12h:
            formatter.dateFormat = "hh:mm:ss a"
        case .format24h:
            formatter.dateFormat = "HH:mm:ss"
        }

        timeFormatters[key] = formatter
        return formatter
    }

    static func dateFormatter(for zone: TimeZone, format: DateFormat) -> DateFormatter {
        let key = "date|\(zone.identifier)|\(format.rawValue)"
        if let cached = dateFormatters[key] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.timeZone = zone

        switch format {
        case .system:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case .short:
            formatter.dateFormat = "dd.MM.yyyy"
        case .iso:
            formatter.dateFormat = "yyyy-MM-dd"
        case .none:
            formatter.dateStyle = .none
            formatter.timeStyle = .none
        }

        dateFormatters[key] = formatter
        return formatter
    }

    static func shortTimeFormatter(for zone: TimeZone) -> DateFormatter {
        let key = "short|\(zone.identifier)"
        if let cached = shortTimeFormatters[key] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        shortTimeFormatters[key] = formatter
        return formatter
    }
}
