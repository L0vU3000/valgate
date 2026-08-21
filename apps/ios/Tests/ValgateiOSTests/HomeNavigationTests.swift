import XCTest
@testable import ValgateiOS

final class HomeNavigationTests: XCTestCase {
    func test_propertySelection_yieldsPropertyDetailDestination() {
        // Fixture: All required PropertyListItemDto fields including lat/lng
        let property = PropertyListItemDto(
            id: "prop_123",
            name: "Test Property",
            type: "residential",
            status: "active",
            city: "London",
            province: "Greater London",
            lat: 51.5074,
            lng: -0.1278,
            createdAt: 1700000000000
        )

        // Act: Resolve the navigation destination for the selected property
        let destination = HomeNavigationResolver.resolve(property: property)

        // Assert: Selection must produce a property-detail destination carrying that property ID
        XCTAssertEqual(
            destination,
            .propertyDetail(id: property.id),
            "Selecting a property should produce a .propertyDetail destination carrying the property ID."
        )
    }
}
