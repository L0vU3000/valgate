import XCTest
@testable import ValgateiOS

/// Verifies the fixture payloads actually satisfy the same `APIClient` calls
/// the real views make, end to end through a stubbed `URLSession` — not just
/// that the JSON parses in isolation. This is what lets `FixtureRootView`
/// reuse `HomeView`/`PropertiesView`/etc. unmodified.
final class FixtureAPIStubURLProtocolTests: XCTestCase {
    private func makeClient() -> APIClient {
        APIClient(baseURL: FixtureData.baseURL, session: FixtureAPIStubURLProtocol.makeSession())
    }

    func test_me_decodesFixtureOrgOwner() async throws {
        let dto = try await makeClient().me(sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(dto.role, .owner)
        XCTAssertEqual(dto.orgName, "Fixture Properties Inc.")
    }

    func test_properties_decodesSinglePropertyMatchingFixturePropertyId() async throws {
        let page = try await makeClient().properties(limit: 100, cursor: nil, sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items.first?.id, FixtureData.propertyId)
        XCTAssertNil(page.nextCursor)
    }

    func test_property_decodesDetailForFixturePropertyId() async throws {
        let dto = try await makeClient().property(id: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(dto.id, FixtureData.propertyId)
        XCTAssertEqual(dto.name, "Fixture Harbor Lofts")
    }

    func test_property_unknownIdReturnsNotFound() async {
        do {
            _ = try await makeClient().property(id: "not-a-fixture-id", sessionToken: FixtureData.sessionToken)
            XCTFail("expected APIClientError.server(404)")
        } catch APIClientError.server(let status, _, _) {
            XCTAssertEqual(status, 404)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func test_listDocuments_decodesOneFixtureDocument() async throws {
        let documents = try await makeClient().listDocuments(propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents.first?.propertyId, FixtureData.propertyId)
    }

    func test_listLeases_decodesOneFixtureLease() async throws {
        let leases = try await makeClient().listLeases(propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(leases.count, 1)
        XCTAssertEqual(leases.first?.unit, "Unit 4B")
    }

    func test_listValuations_decodesOneFixtureValuation() async throws {
        let valuations = try await makeClient().listValuations(propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(valuations.count, 1)
        XCTAssertEqual(valuations.first?.price, 685000.0)
    }

    func test_ownership_decodesFixtureOwnershipRecord() async throws {
        let ownership = try await makeClient().ownership(propertyId: FixtureData.propertyId, sessionToken: FixtureData.sessionToken)

        XCTAssertEqual(ownership?.holdingType, "individual")
        XCTAssertEqual(ownership?.verified, true)
    }
}
