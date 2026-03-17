import WidgetKit
import SwiftUI

struct SmallProvider: AppIntentTimelineProvider {
    typealias Intent = TimeZonesSmallWidgetConfigurationIntent

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), timeZones: [])
    }

    func snapshot(for configuration: TimeZonesSmallWidgetConfigurationIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), timeZones: Array(configuration.selectedTimeZones.prefix(2)))
    }

    func timeline(for configuration: TimeZonesSmallWidgetConfigurationIntent, in context: Context) async -> Timeline<SimpleEntry> {
        makeTimeline(timeZones: Array(configuration.selectedTimeZones.prefix(2)))
    }
}

struct MediumProvider: AppIntentTimelineProvider {
    typealias Intent = TimeZonesMediumWidgetConfigurationIntent

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), timeZones: [])
    }

    func snapshot(for configuration: TimeZonesMediumWidgetConfigurationIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), timeZones: Array(configuration.selectedTimeZones.prefix(4)))
    }

    func timeline(for configuration: TimeZonesMediumWidgetConfigurationIntent, in context: Context) async -> Timeline<SimpleEntry> {
        makeTimeline(timeZones: Array(configuration.selectedTimeZones.prefix(4)))
    }
}

private func makeTimeline(timeZones: [SavedTimeZone]) -> Timeline<SimpleEntry> {
    let currentDate = Date()
    var entries: [SimpleEntry] = []

    for minuteOffset in 0 ..< 60 {
        if let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) {
            entries.append(SimpleEntry(date: entryDate, timeZones: timeZones))
        }
    }

    return Timeline(entries: entries, policy: .atEnd)
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timeZones: [SavedTimeZone]
}
