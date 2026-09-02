import XCTest
import MapKit
@testable import ValgateiOS

final class AddPropertyFlowTests: XCTestCase {

    @MainActor
    func test_locationPicker_updatesCoordinates() {
        let viewModel = LocationPickerViewModel(initialCoordinate: CLLocationCoordinate2D(latitude: 12.0, longitude: 104.0))

        let newCoord = CLLocationCoordinate2D(latitude: 12.5, longitude: 104.5)
        viewModel.updateCoordinate(newCoord)

        XCTAssertEqual(viewModel.coordinate.latitude, 12.5)
        XCTAssertEqual(viewModel.coordinate.longitude, 104.5)
    }

    func test_createPropertyForm_toRequest_encoding() {
        var form = CreatePropertyForm()
        form.name = " Test Property "
        form.type = .commercial
        form.status = .vacant
        form.city = "Phnom Penh"
        form.province = "Phnom Penh"
        form.lat = 12.3456
        form.lng = 104.5678
        form.totalArea = "500sqm"
        form.title = .none

        let request = form.toRequest()

        XCTAssertEqual(request.name, "Test Property")
        XCTAssertEqual(request.type, .commercial)
        XCTAssertEqual(request.status, .vacant)
        XCTAssertEqual(request.city, "Phnom Penh")
        XCTAssertEqual(request.province, "Phnom Penh")
        XCTAssertEqual(request.lat, 12.3456)
        XCTAssertEqual(request.lng, 104.5678)
        XCTAssertEqual(request.totalArea, "500sqm")
        XCTAssertEqual(request.title, .none)
    }

    func test_homeNavigationResolver_resolveCreated() {
        let createdDto = PropertyDetailDto(
            id: "prop_123",
            name: "New Villa",
            type: "residential",
            status: "Vacant",
            city: "Phnom Penh",
            province: "Phnom Penh",
            createdAt: 1700000000000,
            addressLine: nil,
            country: nil,
            totalArea: "100",
            bedrooms: nil,
            bathrooms: nil,
            yearBuilt: nil
        )

        let destination = HomeNavigationResolver.resolve(created: createdDto)

        if case .propertyDetail(let id) = destination {
            XCTAssertEqual(id, "prop_123")
        } else {
            XCTFail("Expected .propertyDetail destination")
        }
    }

    func test_simplePropertyCreateForm_validName() {
        var form = SimplePropertyCreateForm()
        form.name = " Villa One "

        XCTAssertTrue(form.isValid)
    }

    func test_simplePropertyCreateForm_blankNameInvalid() {
        var emptyForm = SimplePropertyCreateForm()
        XCTAssertFalse(emptyForm.isValid)

        var whitespaceForm = SimplePropertyCreateForm()
        whitespaceForm.name = "   "
        XCTAssertFalse(whitespaceForm.isValid)
    }

    func test_simplePropertyCreateForm_toRequest_usesMapCenterCoords() {
        var form = SimplePropertyCreateForm()
        form.name = " Villa One "
        form.type = .commercial

        let request = form.toRequest()

        XCTAssertEqual(request.name, "Villa One")
        XCTAssertEqual(request.type, .commercial)
        XCTAssertEqual(request.status, .vacant)
        XCTAssertEqual(request.lat, SimplePropertyCreateForm.defaultLatitude)
        XCTAssertEqual(request.lng, SimplePropertyCreateForm.defaultLongitude)
        XCTAssertEqual(request.lat, 12.5657)
        XCTAssertEqual(request.lng, 104.9910)
    }

    func test_propertySearchFilter_emptyQueryReturnsAll() {
        let results = PropertySearchFilter.matching(searchFixtures, query: "")
        XCTAssertEqual(results.map(\.id), ["prop_1", "prop_2"])
    }

    func test_propertySearchFilter_matchesCityPhnom() {
        let results = PropertySearchFilter.matching(searchFixtures, query: "Phnom")
        XCTAssertEqual(results.map(\.id), ["prop_1"])
    }

    func test_propertySearchFilter_unmatchedIsEmpty() {
        let results = PropertySearchFilter.matching(searchFixtures, query: "zzzz")
        XCTAssertTrue(results.isEmpty)
    }

    private var searchFixtures: [PropertyListItemDto] {
        [
            PropertyListItemDto(
                id: "prop_1",
                name: "Lakeview House",
                type: "residential",
                status: "Vacant",
                city: "Phnom Penh",
                province: "Phnom Penh",
                lat: 11.5564,
                lng: 104.9282,
                createdAt: 1_700_000_000_000
            ),
            PropertyListItemDto(
                id: "prop_2",
                name: "Riverside Office",
                type: "commercial",
                status: "Rented",
                city: "Siem Reap",
                province: "Siem Reap",
                lat: 13.3617,
                lng: 103.8516,
                createdAt: 1_700_000_000_001
            )
        ]
    }
}
