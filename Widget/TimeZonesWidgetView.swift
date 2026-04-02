import WidgetKit
import SwiftUI

struct TimeZonesWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if #available(macOS 14.0, *) {
            content
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
                .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if entry.timeZones.isEmpty {
                emptyState
            } else {
                zoneLayout
            }
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Add time zones from Edit Widget")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Time Zones")
                .font(.headline)

            Spacer()
        }
    }

    @ViewBuilder
    private var zoneLayout: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.timeZones.prefix(2), id: \.id) { zone in
                    WidgetZoneRow(zone: zone, date: entry.date, compact: true)
                }
            }

        case .systemMedium:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(entry.timeZones.prefix(4), id: \.id) { zone in
                    WidgetZoneRow(zone: zone, date: entry.date, compact: false)
                }
            }

        case .systemLarge, .systemExtraLarge:
            EmptyView()

        @unknown default:
            EmptyView()
        }
    }
}

private struct WidgetZoneRow: View {
    let zone: SavedTimeZone
    let date: Date
    let compact: Bool

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            HStack(spacing: 6) {
                Text(zone.flagEmoji)
                Text(zone.cityName)
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer(minLength: 6)
            }

            HStack {
                Text(formattedTime(for: zone, at: date))
                    .font(compact ? .headline : .title3)
                    .monospacedDigit()
                Spacer()
                Text(zone.offsetString(at: date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedTime(for zone: SavedTimeZone, at date: Date) -> String {
        // Render city-local wall clock from absolute date; formatter stays in GMT to avoid host-timezone override.
        let adjusted = date.addingTimeInterval(TimeInterval(zone.timeZone.secondsFromGMT(for: date)))
        return Self.timeFormatter.string(from: adjusted)
    }
}
