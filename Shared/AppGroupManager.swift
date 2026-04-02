import Foundation
import SwiftUI

final class AppGroupManager: ObservableObject {
    static let shared = AppGroupManager()
    
    // Replace this with your actual App Group ID
    static let appGroupID = "group.com.yourname.TimeZonesWidget"
    private static let timeZonesKey = "savedTimeZones"
    private static let configKey = "appConfig"
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
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
            guard oldValue != savedTimeZones else { return }
            saveTimeZones()
        }
    }
    
    @Published var config: AppConfig = .default {
        didSet {
            guard oldValue != config else { return }
            saveConfig()
        }
    }

    init(defaults: UserDefaults = AppGroupManager.sharedDefaults()) {
        self.defaults = defaults
        loadData()
    }
    
    func loadData() {
        if let data = defaults.data(forKey: Self.timeZonesKey),
           let decoded = try? Self.decoder.decode([SavedTimeZone].self, from: data) {
            self.savedTimeZones = decoded
        } else {
            self.savedTimeZones = []
        }
        
        if let data = defaults.data(forKey: Self.configKey),
           let decoded = try? Self.decoder.decode(AppConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = .default
        }
    }

    func containsTimeZone(_ identifier: String) -> Bool {
        savedTimeZones.contains { $0.identifier == identifier }
    }

    @discardableResult
    func addTimeZone(_ identifier: String) -> Bool {
        guard TimeZone(identifier: identifier) != nil else { return false }
        guard !containsTimeZone(identifier) else { return false }
        savedTimeZones.append(SavedTimeZone(identifier: identifier))
        return true
    }

    func removeTimeZone(_ identifier: String) {
        savedTimeZones.removeAll { $0.identifier == identifier }
    }

    func removeTimeZones(at offsets: IndexSet) {
        savedTimeZones.remove(atOffsets: offsets)
    }

    func moveTimeZones(from source: IndexSet, to destination: Int) {
        savedTimeZones.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveTimeZones() {
        if let encoded = try? Self.encoder.encode(savedTimeZones) {
            defaults.set(encoded, forKey: Self.timeZonesKey)
        }
    }
    
    private func saveConfig() {
        if let encoded = try? Self.encoder.encode(config) {
            defaults.set(encoded, forKey: Self.configKey)
        }
    }
}
