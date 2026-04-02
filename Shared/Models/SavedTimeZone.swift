import Foundation

struct SavedTimeZone: Identifiable, Codable, Equatable {
    var id: String { identifier }
    let identifier: String
    
    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone.autoupdatingCurrent
    }
    
    var cityName: String {
        Self.cityName(for: identifier)
    }

    var countryCode: String? {
        Self.countryCode(for: identifier)
    }

    var flagEmoji: String {
        Self.flagEmoji(for: identifier)
    }
    
    func offsetString(at date: Date = Date(), relativeTo reference: TimeZone = .autoupdatingCurrent) -> String {
        let secondsFromGMT = timeZone.secondsFromGMT(for: date)
        let referenceSeconds = reference.secondsFromGMT(for: date)
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

    func offsetString(relativeTo reference: TimeZone = .autoupdatingCurrent) -> String {
        offsetString(at: Date(), relativeTo: reference)
    }
}

extension SavedTimeZone {
    private struct SortKey {
        let identifier: String
        let city: String
        let gmtOffset: Int
    }

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

    static func cityName(for identifier: String) -> String {
        let components = identifier.split(separator: "/")
        if let last = components.last {
            return String(last).replacingOccurrences(of: "_", with: " ")
        }
        return identifier
    }

    static func gmtOffsetString(for timeZone: TimeZone, at date: Date = Date()) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absolute = abs(seconds)
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60

        if minutes == 0 {
            return "GMT\(sign)\(hours)"
        }

        return String(format: "GMT%@%d:%02d", sign, hours, minutes)
    }

    static func gmtOffsetString(for identifier: String, at date: Date = Date()) -> String {
        guard let zone = TimeZone(identifier: identifier) else { return "" }
        return gmtOffsetString(for: zone, at: date)
    }

    static func sortedKnownTimeZoneIdentifiers(at date: Date = Date()) -> [String] {
        sortedIdentifiers(TimeZone.knownTimeZoneIdentifiers, at: date)
    }

    static func sortedIdentifiers<S: Sequence>(_ identifiers: S, at date: Date = Date()) -> [String]
    where S.Element == String {
        let keyed = identifiers.compactMap { identifier -> SortKey? in
            guard let zone = TimeZone(identifier: identifier) else { return nil }
            return SortKey(
                identifier: identifier,
                city: cityName(for: identifier),
                gmtOffset: zone.secondsFromGMT(for: date)
            )
        }

        return keyed
            .sorted { lhs, rhs in
                if lhs.gmtOffset != rhs.gmtOffset {
                    return lhs.gmtOffset < rhs.gmtOffset
                }
                if lhs.city != rhs.city {
                    return lhs.city < rhs.city
                }
                return lhs.identifier < rhs.identifier
            }
            .map(\.identifier)
    }

    static func matchesSearch(identifier: String, query: String, at date: Date = Date()) -> Bool {
        let loweredQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if loweredQuery.isEmpty {
            return true
        }

        let compactQuery = loweredQuery.replacingOccurrences(of: " ", with: "")
        let city = cityName(for: identifier).lowercased()
        let gmt = gmtOffsetString(for: identifier, at: date).lowercased()
        let compactGMT = gmt.replacingOccurrences(of: " ", with: "")

        return identifier.lowercased().contains(loweredQuery)
            || city.contains(loweredQuery)
            || compactGMT.contains(compactQuery)
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
