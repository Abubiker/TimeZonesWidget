import Foundation

final class WidgetTimeZoneStore {
    static let shared = WidgetTimeZoneStore()

    static let maximumTimeZones = 4

    private let userDefaults: UserDefaults
    private let key = "widget.selected.timezones"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func timeZones() -> [SavedTimeZone] {
        let identifiers = storedIdentifiers()
        let zones = identifiers.map { SavedTimeZone(identifier: $0) }
        return zones.isEmpty ? defaultTimeZones : zones
    }

    @discardableResult
    func add(identifier: String) -> AddResult {
        var identifiers = storedIdentifiers()
        if identifiers.contains(identifier) {
            return .alreadyExists
        }

        guard identifiers.count < Self.maximumTimeZones else {
            return .limitReached
        }

        identifiers.append(identifier)
        userDefaults.set(identifiers, forKey: key)
        return .added
    }

    func remove(identifier: String) {
        var identifiers = storedIdentifiers()
        identifiers.removeAll { $0 == identifier }
        userDefaults.set(identifiers, forKey: key)
    }

    private func storedIdentifiers() -> [String] {
        let identifiers = userDefaults.stringArray(forKey: key) ?? []
        return identifiers.filter { TimeZone(identifier: $0) != nil }
    }

    private var defaultTimeZones: [SavedTimeZone] {
        [
            SavedTimeZone(identifier: "Europe/London"),
            SavedTimeZone(identifier: "America/New_York")
        ]
    }
}

enum AddResult {
    case added
    case alreadyExists
    case limitReached
}
