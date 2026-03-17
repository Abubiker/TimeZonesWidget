import Foundation

struct SavedTimeZone: Identifiable, Codable, Equatable {
    var id: String { identifier }
    let identifier: String
    
    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone.autoupdatingCurrent
    }
    
    var cityName: String {
        // Extract city name from identifier (e.g. "Europe/Belgrade" -> "Belgrade")
        let components = identifier.split(separator: "/")
        if let last = components.last {
            return String(last).replacingOccurrences(of: "_", with: " ")
        }
        return identifier
    }

    var countryCode: String? {
        Self.countryCode(for: identifier)
    }

    var flagEmoji: String {
        Self.flagEmoji(for: identifier)
    }
    
    func offsetString(relativeTo reference: TimeZone = .autoupdatingCurrent) -> String {
        let secondsFromGMT = timeZone.secondsFromGMT()
        let referenceSeconds = reference.secondsFromGMT()
        let diff = secondsFromGMT - referenceSeconds
        
        let hours = diff / 3600
        if hours == 0 {
            return "0HRS"
        } else if hours > 0 {
            return "+\(hours)HRS"
        } else {
            return "\(hours)HRS"
        }
    }
}

extension SavedTimeZone {
    private static let zoneTabPaths: [String] = [
        "/usr/share/zoneinfo/zone.tab",
        "/usr/share/zoneinfo/zone1970.tab"
    ]

    private static let timeZoneCountryMap: [String: String] = {
        for path in zoneTabPaths {
            if let mapping = loadZoneTab(from: path), !mapping.isEmpty {
                return mapping
            }
        }
        return [:]
    }()

    static func flagEmoji(for identifier: String) -> String {
        if let code = countryCode(for: identifier) {
            return flagEmoji(from: code)
        }
        return "🏳️"
    }

    static func countryCode(for identifier: String) -> String? {
        let canonical = TimeZone(identifier: identifier)?.identifier ?? identifier
        if let code = timeZoneCountryMap[canonical] {
            return code
        }

        let upper = canonical.uppercased()
        if upper == "UTC" || upper == "GMT" || canonical.hasPrefix("Etc/") {
            return "UN"
        }

        return nil
    }

    private static func loadZoneTab(from path: String) -> [String: String]? {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }

        var mapping: [String: String] = [:]

        for line in contents.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            let parts = trimmed.split(separator: "\t")
            guard parts.count >= 3 else { continue }

            let countryCodes = parts[0].split(separator: ",")
            guard let primary = countryCodes.first else { continue }

            let timeZoneId = String(parts[2])
            mapping[timeZoneId] = String(primary)
        }

        return mapping
    }

    private static func flagEmoji(from countryCode: String) -> String {
        let uppercased = countryCode.uppercased()
        guard uppercased.count == 2 else { return "🏳️" }

        let base: UInt32 = 127397
        var scalars: [UnicodeScalar] = []

        for scalar in uppercased.unicodeScalars {
            scalars.append(UnicodeScalar(base + scalar.value)!)
        }

        return String(String.UnicodeScalarView(scalars))
    }
}
