import AppIntents
import Foundation

private enum TimeZoneIntentConstants {
    static let clearIdentifier = "__clear_selection__"
    static let suggestedLimit = 300
}

private enum TimeZoneIntentSelection {
    static func zones(from values: [TimeZoneEntity?], maxCount: Int) -> [SavedTimeZone] {
        var seen = Set<String>()
        var zones: [SavedTimeZone] = []

        for value in values {
            guard let identifier = value?.identifier else { continue }
            guard identifier != TimeZoneIntentConstants.clearIdentifier else { continue }
            guard TimeZone(identifier: identifier) != nil else { continue }
            guard !seen.contains(identifier) else { continue }
            seen.insert(identifier)
            zones.append(SavedTimeZone(identifier: identifier))
            if zones.count == maxCount {
                break
            }
        }

        return zones
    }
}

protocol TimeZonesSelectableIntent {
    var selectedTimeZones: [SavedTimeZone] { get }
}

struct TimeZonesSmallWidgetConfigurationIntent: WidgetConfigurationIntent, TimeZonesSelectableIntent {
    static var title: LocalizedStringResource = "Time Zones (Small)"
    static var description = IntentDescription("Choose up to two time zones for the small widget.")

    @Parameter(title: "Time Zone 1")
    var timeZone1: TimeZoneEntity?

    @Parameter(title: "Time Zone 2")
    var timeZone2: TimeZoneEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$timeZone1), \(\.$timeZone2)")
    }

    var selectedTimeZones: [SavedTimeZone] {
        TimeZoneIntentSelection.zones(from: [timeZone1, timeZone2], maxCount: 2)
    }
}

struct TimeZonesMediumWidgetConfigurationIntent: WidgetConfigurationIntent, TimeZonesSelectableIntent {
    static var title: LocalizedStringResource = "Time Zones (Medium)"
    static var description = IntentDescription("Choose up to four time zones for the medium widget.")

    @Parameter(title: "Time Zone 1")
    var timeZone1: TimeZoneEntity?

    @Parameter(title: "Time Zone 2")
    var timeZone2: TimeZoneEntity?

    @Parameter(title: "Time Zone 3")
    var timeZone3: TimeZoneEntity?

    @Parameter(title: "Time Zone 4")
    var timeZone4: TimeZoneEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$timeZone1), \(\.$timeZone2), \(\.$timeZone3), \(\.$timeZone4)")
    }

    var selectedTimeZones: [SavedTimeZone] {
        TimeZoneIntentSelection.zones(from: [timeZone1, timeZone2, timeZone3, timeZone4], maxCount: 4)
    }
}

struct TimeZoneEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Zone")
    static var defaultQuery = TimeZoneEntityQuery()

    let identifier: String
    var id: String { identifier }

    var displayRepresentation: DisplayRepresentation {
        if identifier == TimeZoneIntentConstants.clearIdentifier {
            return DisplayRepresentation(
                title: "✕ Clear Selection",
                subtitle: "Remove this slot value"
            )
        }

        let zone = SavedTimeZone(identifier: identifier)
        return DisplayRepresentation(
            title: "\(zone.flagEmoji) \(zone.cityName)",
            subtitle: "\(SavedTimeZone.gmtOffsetString(for: zone.timeZone)) • \(zone.identifier)"
        )
    }
}

struct TimeZoneEntityQuery: EntityStringQuery {
    func entities(for identifiers: [TimeZoneEntity.ID]) async throws -> [TimeZoneEntity] {
        identifiers.map { TimeZoneEntity(identifier: $0) }
    }

    func suggestedEntities() async throws -> [TimeZoneEntity] {
        let sorted = SavedTimeZone.sortedKnownTimeZoneIdentifiers()
            .prefix(TimeZoneIntentConstants.suggestedLimit)
            .map { TimeZoneEntity(identifier: $0) }

        return [TimeZoneEntity(identifier: TimeZoneIntentConstants.clearIdentifier)] + sorted
    }

    func entities(matching query: String) async throws -> [TimeZoneEntity] {
        let lower = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.isEmpty {
            return try await suggestedEntities()
        }

        let now = Date()
        var leadingEntities: [TimeZoneEntity] = []

        if "clear".contains(lower) || "remove".contains(lower) || "delete".contains(lower) ||
            "очист".contains(lower) || "удал".contains(lower) {
            leadingEntities.append(TimeZoneEntity(identifier: TimeZoneIntentConstants.clearIdentifier))
        }

        let matchedIdentifiers = TimeZone.knownTimeZoneIdentifiers.filter { identifier in
            SavedTimeZone.matchesSearch(identifier: identifier, query: lower, at: now)
        }

        let entities = SavedTimeZone.sortedIdentifiers(matchedIdentifiers, at: now)
            .prefix(TimeZoneIntentConstants.suggestedLimit)
            .map { TimeZoneEntity(identifier: $0) }

        return leadingEntities + entities
    }
}
