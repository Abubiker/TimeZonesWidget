import WidgetKit
import SwiftUI

let smallTimeZonesWidgetKind = "TimeZonesWidgetSmallV2"
let mediumTimeZonesWidgetKind = "TimeZonesWidgetMediumV2"

@main
struct TimeZonesWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeZonesSmallWidget()
        TimeZonesMediumWidget()
    }
}

struct TimeZonesSmallWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: smallTimeZonesWidgetKind,
            intent: TimeZonesSmallWidgetConfigurationIntent.self,
            provider: SmallProvider()
        ) { entry in
            TimeZonesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time Zones")
        .description("Small: up to 2 time zones.")
        .supportedFamilies([.systemSmall])
    }
}

struct TimeZonesMediumWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: mediumTimeZonesWidgetKind,
            intent: TimeZonesMediumWidgetConfigurationIntent.self,
            provider: MediumProvider()
        ) { entry in
            TimeZonesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time Zones")
        .description("Medium: up to 4 time zones.")
        .supportedFamilies([.systemMedium])
    }
}
