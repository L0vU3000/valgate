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
}
