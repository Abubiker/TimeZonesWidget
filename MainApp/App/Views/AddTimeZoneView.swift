import SwiftUI

struct AddTimeZoneView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appGroupManager: AppGroupManager

    @State private var searchText = ""
    @State private var hoveredIdentifier: String?
    @State private var selectedIdentifier: String?
    @State private var now = Date()
    @State private var sortedIdentifiers: [String] = []

    private let refreshTimer = Timer.publish(every: 60, tolerance: 2, on: .main, in: .common).autoconnect()
    
    var filteredTimeZones: [String] {
        if searchText.isEmpty {
            return sortedIdentifiers
        } else {
            return sortedIdentifiers.filter { SavedTimeZone.matchesSearch(identifier: $0, query: searchText, at: now) }
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
                                Text(SavedTimeZone.cityName(for: identifier))
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
                        .disabled(appGroupManager.containsTimeZone(identifier))
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
        .onAppear {
            reloadSortedIdentifiers()
        }
        .onReceive(refreshTimer) { date in
            now = date
            reloadSortedIdentifiers()
        }
    }
    
    private func previewTime(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let formatter = DateFormatterCache.shortTimeFormatter(for: tz)
        return formatter.string(from: now)
    }
    
    private func previewOffset(for identifier: String) -> String {
        gmtOffset(for: identifier)
    }

    private func gmtOffset(for identifier: String) -> String {
        SavedTimeZone.gmtOffsetString(for: identifier, at: now)
    }
    
    private func addTimeZone(_ identifier: String) {
        guard appGroupManager.addTimeZone(identifier) else { return }
        presentationMode.wrappedValue.dismiss()
    }

    private func reloadSortedIdentifiers() {
        sortedIdentifiers = SavedTimeZone.sortedKnownTimeZoneIdentifiers(at: now)
    }
}
