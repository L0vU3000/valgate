import XCTest
@testable import ValgateiOS

final class CreatePropertyViewModelTests: XCTestCase {
    @MainActor
    func test_submitTransitionsFromIdleToSubmitted() async {
        let client = StubCreatePropertyClient(result: .success(stubDetailDto()))
        let vm = CreatePropertyViewModel(
            client: client,
            sessionToken: "tok",
            onUnauthorized: {}
        )

        await vm.submit(minimalRequest())

        XCTAssertEqual(vm.state, .submitted(stubDetailDto()))
        XCTAssertEqual(client.receivedRequest?.name, "Villa")
    }

    @MainActor
    func test_submitWithUnauthorizedTriggersCallback() async {
        let expectUnauthorized = expectation(description: "onUnauthorized")
        let client = StubCreatePropertyClient(
            result: .failure(APIClientError.server(status: 401, code: .unauthorized, message: nil))
        )
        let vm = CreatePropertyViewModel(
            client: client,
            sessionToken: "tok",
            onUnauthorized: { expectUnauthorized.fulfill() }
        )

        await vm.submit(minimalRequest())

        await fulfillment(of: [expectUnauthorized], timeout: 1)
        XCTAssertEqual(vm.state, .unauthorized)
    }

    @MainActor
    func test_dismissErrorReturnsToIdle() async {
        let client = StubCreatePropertyClient(
            result: .failure(APIClientError.server(status: 500, code: .internalError, message: nil))
        )
        let vm = CreatePropertyViewModel(client: client, sessionToken: "tok")

        await vm.submit(minimalRequest())
        XCTAssertTrue(vm.state.isError)

        vm.dismissError()
        XCTAssertEqual(vm.state, .idle)
    }

    @MainActor
    func test_dismissErrorDoesNothingWhenNotError() {
        let vm = CreatePropertyViewModel(
            client: StubCreatePropertyClient(result: .success(stubDetailDto())),
            sessionToken: "tok"
        )
        vm.dismissError()
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: - Helpers

    private func minimalRequest() -> CreatePropertyRequest {
        CreatePropertyRequest(name: "Villa", type: .residential, status: .vacant, lat: 0, lng: 0)
    }

    private func stubDetailDto() -> PropertyDetailDto {
        PropertyDetailDto(
            id: "prop_1",
            name: "Villa",
            type: "residential",
            status: "Vacant",
            city: nil,
            province: nil,
            createdAt: 1700000000000,
            addressLine: nil,
            country: nil,
            totalArea: "120",
            bedrooms: nil,
            bathrooms: nil,
            yearBuilt: nil
        )
    }
}

// MARK: - Stub Client

private actor StubCreatePropertyClient: APIClient {
    var receivedRequest: CreatePropertyRequest?
    private let result: Result<PropertyDetailDto, APIClientError>

    init(result: Result<PropertyDetailDto, APIClientError>) {
        self.result = result
        super.init(baseURL: URL(string: "https://example.invalid")!)
    }

    override func createProperty(_ body: CreatePropertyRequest, sessionToken: String) async throws -> PropertyDetailDto {
        receivedRequest = body
        switch result {
        case .success(let dto): return dto
        case .failure(let error): throw error
        }
    }
}
