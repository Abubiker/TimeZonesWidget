import Foundation
import SwiftUI

class AppGroupManager: ObservableObject {
    static let shared = AppGroupManager()
    
    // Replace this with your actual App Group ID
    static let appGroupID = "group.com.yourname.TimeZonesWidget"
    
    static func sharedDefaults() -> UserDefaults {
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil,
           let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            return sharedDefaults
        }
        
        return UserDefaults.standard
    }
    
    private let defaults: UserDefaults
    
    @Published var savedTimeZones: [SavedTimeZone] = [] {
        didSet {
            saveTimeZones()
        }
    }
    
    @Published var config: AppConfig = .default {
        didSet {
            saveConfig()
        }
    }
    
    private let timeZonesKey = "savedTimeZones"
    private let configKey = "appConfig"
    
    init() {
        self.defaults = AppGroupManager.sharedDefaults()
        loadData()
    }
    
    func loadData() {
        if let data = defaults.data(forKey: timeZonesKey),
           let decoded = try? JSONDecoder().decode([SavedTimeZone].self, from: data) {
            self.savedTimeZones = decoded
        } else {
            self.savedTimeZones = []
        }
        
        if let data = defaults.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = .default
        }
    }
    
    private func saveTimeZones() {
        if let encoded = try? JSONEncoder().encode(savedTimeZones) {
            defaults.set(encoded, forKey: timeZonesKey)
        }
    }
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            defaults.set(encoded, forKey: configKey)
        }
    }
}
