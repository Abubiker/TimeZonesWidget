import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appGroupManager: AppGroupManager
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appGroupManager.config.appTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }

            Section(header: Text("Time Display")) {
                Picker("Time Format", selection: $appGroupManager.config.timeFormat) {
                    ForEach(TimeFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                
                Picker("Date Format", selection: $appGroupManager.config.dateFormat) {
                    ForEach(DateFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
            }
            
            Section(header: Text("Clipboard Settings")) {
                Picker("Default Timestamp Format", selection: $appGroupManager.config.timestampFormat) {
                    ForEach(TimestampFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
            }
            
            Section(header: Text("System Settings")) {
                Toggle("Launch at Login", isOn: Binding(
                    get: { appGroupManager.config.launchAtLogin },
                    set: { newValue in
                        appGroupManager.config.launchAtLogin = newValue
                        updateLaunchAtLogin(newValue)
                    }
                ))
            }
        }
        .padding()
        .frame(minWidth: 320, minHeight: 220)
    }
    
    private func updateLaunchAtLogin(_ enable: Bool) {
        // Requires macOS 13+
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update SMAppService: \(error.localizedDescription)")
            }
        } else {
            // For older macOS, this usually required a separate helper app
            print("Launch at login requires macOS 13+ with SMAppService.")
        }
    }
}
