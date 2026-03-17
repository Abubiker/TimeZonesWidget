import SwiftUI

struct AddTimeZoneView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appGroupManager: AppGroupManager
    @EnvironmentObject var timeManager: TimeManager
    
    @State private var searchText = ""
    @State private var hoveredIdentifier: String?
    @State private var selectedIdentifier: String?
    
    private var sortedIdentifiers: [String] {
        let now = timeManager.currentTime
        return TimeZone.knownTimeZoneIdentifiers
            .filter { TimeZone(identifier: $0) != nil }
            .sorted { lhs, rhs in
                let lhsOffset = TimeZone(identifier: lhs)?.secondsFromGMT(for: now) ?? Int.max
                let rhsOffset = TimeZone(identifier: rhs)?.secondsFromGMT(for: now) ?? Int.max
                if lhsOffset != rhsOffset {
                    return lhsOffset < rhsOffset
                }

                let lhsCity = formatIdentifier(lhs)
                let rhsCity = formatIdentifier(rhs)
                if lhsCity != rhsCity {
                    return lhsCity < rhsCity
                }

                return lhs < rhs
            }
    }
    
    var filteredTimeZones: [String] {
        let identifiers = sortedIdentifiers
        if searchText.isEmpty {
            return identifiers
        } else {
            let lower = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let compactLower = lower.replacingOccurrences(of: " ", with: "")

            return identifiers.filter { identifier in
                let city = formatIdentifier(identifier).lowercased()
                let gmt = gmtOffset(for: identifier).lowercased()
                let compactGMT = gmt.replacingOccurrences(of: " ", with: "")
                return identifier.lowercased().contains(lower)
                    || city.contains(lower)
                    || compactGMT.contains(compactLower)
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Add TimeZone")
                .font(.headline)
                .padding()
            
            TextField("Search city or region...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            List {
                ForEach(filteredTimeZones, id: \.self) { identifier in
                    let isSelected = selectedIdentifier == identifier
                    let isHovered = hoveredIdentifier == identifier

                    HStack {
                        VStack(alignment: .leading) {
                            HStack(spacing: 6) {
                                Text(SavedTimeZone.flagEmoji(for: identifier))
                                Text(formatIdentifier(identifier))
                            }
                            .font(.body)
                            Text(identifier)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(previewTime(for: identifier))
                                .font(.system(.body, design: .default).monospacedDigit())
                            Text(previewOffset(for: identifier))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Add") {
                            selectedIdentifier = identifier
                            addTimeZone(identifier)
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .padding(.leading, 8)
                        .disabled(appGroupManager.savedTimeZones.contains(where: { $0.identifier == identifier }))
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIdentifier = identifier
                        addTimeZone(identifier)
                    }
                    .onHover { inside in
                        if inside {
                            hoveredIdentifier = identifier
                        } else if hoveredIdentifier == identifier {
                            hoveredIdentifier = nil
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.accentColor.opacity(0.2) : (isHovered ? Color.primary.opacity(0.06) : Color.clear))
                    )
                }
            }
            .listStyle(PlainListStyle())
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .frame(minWidth: 360, minHeight: 360)
    }
    
    private func formatIdentifier(_ identifier: String) -> String {
        let components = identifier.split(separator: "/")
        if let last = components.last {
            return String(last).replacingOccurrences(of: "_", with: " ")
        }
        return identifier
    }
    
    private func previewTime(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let formatter = DateFormatterCache.shortTimeFormatter(for: tz)
        return formatter.string(from: timeManager.currentTime)
    }
    
    private func previewOffset(for identifier: String) -> String {
        gmtOffset(for: identifier)
    }

    private func gmtOffset(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let seconds = tz.secondsFromGMT(for: timeManager.currentTime)
        let sign = seconds >= 0 ? "+" : "-"
        let absolute = abs(seconds)
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60

        if minutes == 0 {
            return "GMT\(sign)\(hours)"
        }

        return String(format: "GMT%@%d:%02d", sign, hours, minutes)
    }
    
    private func addTimeZone(_ identifier: String) {
        if !appGroupManager.savedTimeZones.contains(where: { $0.identifier == identifier }) {
            appGroupManager.savedTimeZones.append(SavedTimeZone(identifier: identifier))
            presentationMode.wrappedValue.dismiss()
        }
    }
}
