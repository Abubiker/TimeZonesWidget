import XCTest
@testable import TimeZonesWidget

final class TimeZonesWidgetTests: XCTestCase {
    private var disposableSuiteName: String?

    override func tearDown() {
        if let suiteName = disposableSuiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            disposableSuiteName = nil
        }
        super.tearDown()
    }

    func testCityNameFormatting() {
        let zone = SavedTimeZone(identifier: "Europe/London")
        XCTAssertEqual(zone.cityName, "London")
    }

    func testOffsetString() {
        let zone = SavedTimeZone(identifier: "UTC")
        XCTAssertFalse(zone.offsetString().isEmpty)
    }

    func testSortedIdentifiersOrderedByGMTThenCity() {
        let date = Date(timeIntervalSince1970: 1_736_899_200) // 2025-01-15T00:00:00Z
        let zones = [
            "Europe/Paris",
            "Europe/Belgrade",
            "UTC",
            "America/New_York"
        ]

        let sorted = SavedTimeZone.sortedIdentifiers(zones, at: date)

        XCTAssertEqual(sorted, ["America/New_York", "UTC", "Europe/Belgrade", "Europe/Paris"])
    }

    func testMatchesSearchByCityAndGMT() {
        let date = Date(timeIntervalSince1970: 1_736_899_200) // 2025-01-15T00:00:00Z

        XCTAssertTrue(SavedTimeZone.matchesSearch(identifier: "Europe/Belgrade", query: "belg", at: date))
        XCTAssertTrue(SavedTimeZone.matchesSearch(identifier: "Europe/Belgrade", query: "gmt+1", at: date))
        XCTAssertFalse(SavedTimeZone.matchesSearch(identifier: "Europe/Belgrade", query: "gmt-9", at: date))
    }

    func testAppGroupManagerPreventsDuplicatesAndPersists() {
        let suiteName = "TimeZonesWidgetTests.\(UUID().uuidString)"
        disposableSuiteName = suiteName
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let manager = AppGroupManager(defaults: defaults)
        XCTAssertTrue(manager.addTimeZone("Europe/Belgrade"))
        XCTAssertFalse(manager.addTimeZone("Europe/Belgrade"))
        XCTAssertFalse(manager.addTimeZone("Invalid/TimeZone"))
        XCTAssertEqual(manager.savedTimeZones.map(\.identifier), ["Europe/Belgrade"])

        let reloaded = AppGroupManager(defaults: defaults)
        XCTAssertTrue(reloaded.containsTimeZone("Europe/Belgrade"))

        reloaded.removeTimeZone("Europe/Belgrade")
        XCTAssertTrue(reloaded.savedTimeZones.isEmpty)
    }
}
