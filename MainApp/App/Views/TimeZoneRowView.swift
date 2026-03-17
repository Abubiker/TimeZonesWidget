import SwiftUI

struct TimeZoneRowView: View {
    let savedZone: SavedTimeZone
    let onCopy: (String, String) -> Void
    @EnvironmentObject var timeManager: TimeManager
    @EnvironmentObject var appGroupManager: AppGroupManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(savedZone.flagEmoji)
                    Text(savedZone.cityName)
                }
                .font(.headline)
                
                Text(savedZone.offsetString())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString(for: savedZone))
                    .font(.system(.title2, design: .default).monospacedDigit())
                
                if appGroupManager.config.dateFormat != .none {
                    Text(dateString(for: savedZone))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                copyTimestamp()
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Copy Timestamp")
            .padding(.leading, 8)
            .anchorPreference(key: CopyButtonAnchorKey.self, value: .bounds) { anchor in
                [savedZone.id: anchor]
            }

            Button(action: {
                deleteTimeZone()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Remove Time Zone")
            .padding(.leading, 8)
        }
        .padding(.vertical, 6)
    }
    
    private func timeString(for zone: SavedTimeZone) -> String {
        let formatter = DateFormatterCache.timeFormatter(
            for: zone.timeZone,
            format: appGroupManager.config.timeFormat
        )
        return formatter.string(from: timeManager.currentTime)
    }
    
    private func dateString(for zone: SavedTimeZone) -> String {
        switch appGroupManager.config.dateFormat {
        case .none:
            return ""
        default:
            break
        }

        let formatter = DateFormatterCache.dateFormatter(
            for: zone.timeZone,
            format: appGroupManager.config.dateFormat
        )
        return formatter.string(from: timeManager.currentTime)
    }
    
    private func copyTimestamp() {
        let copied = ClipboardHelper.copyTimestamp(for: savedZone, config: appGroupManager.config)
        onCopy(savedZone.id, "Copied: \(copied)")
    }

    private func deleteTimeZone() {
        withAnimation {
            appGroupManager.savedTimeZones.removeAll { $0.id == savedZone.id }
        }
    }
}

struct CopyButtonAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
