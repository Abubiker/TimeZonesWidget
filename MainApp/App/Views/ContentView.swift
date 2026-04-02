import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appGroupManager: AppGroupManager
    
    @State private var showingAddSheet = false
    
    var body: some View {
        TimeZonesTabView(showingAddSheet: $showingAddSheet)
        .sheet(isPresented: $showingAddSheet) {
            AddTimeZoneView()
                .environmentObject(appGroupManager)
        }
    }
}

private struct TimeZonesTabView: View {
    @EnvironmentObject var appGroupManager: AppGroupManager
    @Binding var showingAddSheet: Bool
    @State private var toastMessage: String = ""
    @State private var showingToast = false
    @State private var toastAnchorId: String?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                HStack {
                    Text("Time Zones")
                        .font(.headline)

                    Spacer()

                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Add Time Zone")
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                if appGroupManager.savedTimeZones.isEmpty {
                    Spacer()
                    Text("No timezones added yet.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(appGroupManager.savedTimeZones, id: \.id) { savedZone in
                            TimeZoneRowView(savedZone: savedZone, onCopy: showToast)
                                .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        }
                        .onMove(perform: moveTimeZones)
                        .onDelete(perform: deleteTimeZones)
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .coordinateSpace(name: "TimeZonesTab")
        .overlayPreferenceValue(CopyButtonAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if showingToast, let id = toastAnchorId, let anchor = anchors[id] {
                    let frame = proxy[anchor]
                    Text(toastMessage)
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .position(x: frame.midX, y: max(12, frame.minY - 12))
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func moveTimeZones(from source: IndexSet, to destination: Int) {
        appGroupManager.moveTimeZones(from: source, to: destination)
    }

    private func deleteTimeZones(at offsets: IndexSet) {
        appGroupManager.removeTimeZones(at: offsets)
    }

    private func showToast(_ id: String, _ message: String) {
        toastAnchorId = id
        toastMessage = message
        withAnimation {
            showingToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingToast = false
            }
        }
    }
}
