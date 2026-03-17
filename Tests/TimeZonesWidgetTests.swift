import XCTest
@testable import TimeZonesWidget

final class TimeZonesWidgetTests: XCTestCase {
    func testCityNameFormatting() {
        let zone = SavedTimeZone(identifier: "Europe/London")
        XCTAssertEqual(zone.cityName, "London")
    }

    func testOffsetString() {
        let zone = SavedTimeZone(identifier: "UTC")
        XCTAssertFalse(zone.offsetString().isEmpty)
    }
}
