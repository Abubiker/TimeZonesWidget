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
    let entry = SimpleEntry(date: currentDate, timeZones: timeZones)
    let nextUpdate = nextMinuteBoundary(after: currentDate)
    return Timeline(entries: [entry], policy: .after(nextUpdate))
}

private func nextMinuteBoundary(after date: Date) -> Date {
    let calendar = Calendar.autoupdatingCurrent
    return calendar.nextDate(
        after: date,
        matching: DateComponents(second: 0),
        matchingPolicy: .nextTime,
        direction: .forward
    ) ?? date.addingTimeInterval(60)
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timeZones: [SavedTimeZone]
}
