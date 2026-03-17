import Foundation

enum TimeFormat: String, Codable, CaseIterable {
    case system = "System"
    case format12h = "12-Hour"
    case format24h = "24-Hour"
}

enum AppTheme: String, Codable, CaseIterable {
    case system = "Automatic"
    case light = "Light"
    case dark = "Dark"
}

enum DateFormat: String, Codable, CaseIterable {
    case system = "System"
    case short = "DD.MM.YYYY"
    case iso = "YYYY-MM-DD"
    case none = "None"
}

enum TimestampFormat: String, Codable, CaseIterable {
    case seconds = "Unix (Seconds)"
    case milliseconds = "Unix (Milliseconds)"
    case iso8601 = "ISO 8601"
}

struct AppConfig: Codable, Equatable {
    var timeFormat: TimeFormat = .system
    var dateFormat: DateFormat = .system
    var timestampFormat: TimestampFormat = .seconds
    var launchAtLogin: Bool = false
    var appTheme: AppTheme = .system
    
    static let `default` = AppConfig()
}
