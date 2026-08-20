import SwiftUI

enum EditPropertyState: Equatable {
    case loading
    case editing(PropertyDetailDto)
    case saving
    case saved
    case unauthorized
    case error(String)
}

enum EditPropertyStateResolver {
    static func resolve(result: Result<PropertyDetailDto, APIClientError>) -> EditPropertyState {
        switch result {
        case .success(let dto):
            return .editing(dto)
        case .failure(let error):
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                return .unauthorized
            }
            return .error("Something went wrong. Please try again.")
        }
    }
}

@MainActor
final class EditPropertyViewModel: ObservableObject {
    @Published private(set) var state: EditPropertyState = .loading

    // Form fields
    @Published var name: String = ""
    @Published var type: PropertyType = .residential
    @Published var status: PropertyStatus = .vacant
    @Published var city: String = ""
    @Published var province: String = ""
    @Published var lat: Double = 0
    @Published var lng: Double = 0
    @Published var totalArea: String = ""
    @Published var title: PropertyTitle = .none
    @Published var addressLine: String = ""
    @Published var addressLine2: String = ""
    @Published var zip: String = ""
    @Published var country: String = ""
    @Published var yearBuilt: String = ""
    @Published var bedrooms: String = ""
    @Published var bathrooms: String = ""
    @Published var parkingSpaces: String = ""
    @Published var storageUnit: String = ""
    @Published var purchasePrice: String = ""
    @Published var purchaseDate: Int? = nil
    @Published var currentMarketValue: Double = 0
    @Published var outstandingMortgage: Double = 0
    @Published var monthlyPayment: Double = 0
    @Published var interestRate: Double = 0
    @Published var annualPropertyTax: Double = 0
    @Published var taxAssessmentValue: Double = 0
    @Published var annualInsurance: Double = 0
    @Published var ownershipStatus: String = ""
    @Published var buyNumeric: Double = 0
    @Published var photoStorageIds: [String] = []
    @Published var documentStorageIds: [String] = []

    private let client: APIClient
    private let propertyId: String
    private let sessionToken: String
    private let onUnauthorized: @MainActor () -> Void
    private let onUpdated: @MainActor () -> Void

    init(client: APIClient, propertyId: String, property: PropertyDetailDto, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onUpdated: @escaping @MainActor () -> Void = {}) {
        self.client = client
        self.propertyId = propertyId
        self.sessionToken = sessionToken
        self.onUnauthorized = onUnauthorized
        self.onUpdated = onUpdated

        // Pre-populate
        self.name = property.name
        self.type = property.type
        self.status = property.status
        self.city = property.city ?? ""
        self.province = property.province ?? ""
        self.lat = property.lat
        self.lng = property.lng
        self.totalArea = property.totalArea
        self.title = property.title
        self.addressLine = property.addressLine ?? ""
        self.addressLine2 = property.addressLine2 ?? ""
        self.zip = property.zip ?? ""
        self.country = property.country ?? ""
        self.yearBuilt = property.yearBuilt ?? ""
        self.bedrooms = property.bedrooms ?? ""
        self.bathrooms = property.bathrooms ?? ""
        self.parkingSpaces = property.parkingSpaces ?? ""
        self.storageUnit = property.storageUnit ?? ""
        self.purchasePrice = property.purchasePrice ?? ""
        self.purchaseDate = property.purchaseDate
        self.currentMarketValue = property.currentMarketValue ?? 0
        self.outstandingMortgage = property.outstandingMortgage ?? 0
        self.monthlyPayment = property.monthlyPayment ?? 0
        self.interestRate = property.interestRate ?? 0
        self.annualPropertyTax = property.annualPropertyTax ?? 0
        self.taxAssessmentValue = property.taxAssessmentValue ?? 0
        self.annualInsurance = property.annualInsurance ?? 0
        self.ownershipStatus = property.ownershipStatus ?? ""
        self.buyNumeric = property.buyNumeric
        self.photoStorageIds = property.photoStorageIds
        self.documentStorageIds = property.documentStorageIds

        self.state = .editing(property)
    }

    func save() async {
        state = .saving
        let request = UpdatePropertyRequest(
            id: propertyId,
            name: name,
            type: type,
            status: status,
            city: city.isEmpty ? nil : city,
            province: province.isEmpty ? nil : province,
            lat: lat,
            lng: lng,
            totalArea: totalArea.isEmpty ? nil : totalArea,
            title: title,
            addressLine: addressLine.isEmpty ? nil : addressLine,
            addressLine2: addressLine2.isEmpty ? nil : addressLine2,
            zip: zip.isEmpty ? nil : zip,
            country: country.isEmpty ? nil : country,
            yearBuilt: yearBuilt.isEmpty ? nil : yearBuilt,
            bedrooms: bedrooms.isEmpty ? nil : bedrooms,
            bathrooms: bathrooms.isEmpty ? nil : bathrooms,
            parkingSpaces: parkingSpaces.isEmpty ? nil : parkingSpaces,
            storageUnit: storageUnit.isEmpty ? nil : storageUnit,
            purchasePrice: purchasePrice.isEmpty ? nil : purchasePrice,
            purchaseDate: purchaseDate,
            currentMarketValue: currentMarketValue,
            outstandingMortgage: outstandingMortgage,
            monthlyPayment: monthlyPayment,
            interestRate: interestRate,
            annualPropertyTax: annualPropertyTax,
            taxAssessmentValue: taxAssessmentValue,
            annualInsurance: annualInsurance,
            ownershipStatus: ownershipStatus.isEmpty ? nil : ownershipStatus,
            buyNumeric: buyNumeric,
            photoStorageIds: photoStorageIds,
            documentStorageIds: documentStorageIds
        )

        do {
            _ = try await client.updateProperty(id: propertyId, body: request, sessionToken: sessionToken)
            state = .saved
            onUpdated()
        } catch let error as APIClientError {
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                state = .unauthorized
                onUnauthorized()
            } else {
                state = .error(error.localizedDescription)
            }
        } catch {
            state = .error("Something went wrong. Please try again.")
        }
    }
}

struct EditPropertyView: View {
    @StateObject private var viewModel: EditPropertyViewModel
    @Environment(\.dismiss) private var dismiss

    init(client: APIClient, propertyId: String, property: PropertyDetailDto, sessionToken: String, onUnauthorized: @escaping @MainActor () -> Void = {}, onUpdated: @escaping @MainActor () -> Void = {}) {
        _viewModel = StateObject(
            wrappedValue: EditPropertyViewModel(client: client, propertyId: propertyId, property: property, sessionToken: sessionToken, onUnauthorized: onUnauthorized, onUpdated: onUpdated)
        )
    }

    var body: some View {
        Form {
            Section("General Information") {
                TextField("Property Name", text: $viewModel.name)
                Picker("Type", selection: $viewModel.type) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                Picker("Status", selection: $viewModel.status) {
                    ForEach(PropertyStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Location") {
                TextField("City", text: $viewModel.city)
                TextField("Province", text: $viewModel.province)
                TextField("Country", text: $viewModel.country)
                TextField("Address Line 1", text: $viewModel.addressLine)
                TextField("Address Line 2", text: $viewModel.addressLine2)
                TextField("Zip Code", text: $viewModel.zip)
            }

            Section("Details") {
                TextField("Total Area", text: $viewModel.totalArea)
                Picker("Title", selection: $viewModel.title) {
                    ForEach(PropertyTitle.allCases, id: \.self) { title in
                        Text(title.rawValue).tag(title)
                    }
                }
                TextField("Year Built", text: $viewModel.yearBuilt)
                TextField("Bedrooms", text: $viewModel.bedrooms)
                TextField("Bathrooms", text: $viewModel.bathrooms)
                TextField("Parking Spaces", text: $viewModel.parkingSpaces)
                TextField("Storage Unit", text: $viewModel.storageUnit)
            }

            Section("Financials") {
                TextField("Purchase Price", text: $viewModel.purchasePrice)
                TextField("Current Market Value", value: $viewModel.currentMarketValue, format: .number)
                TextField("Outstanding Mortgage", value: $viewModel.outstandingMortgage, format: .number)
                TextField("Monthly Payment", value: $viewModel.monthlyPayment, format: .number)
                TextField("Interest Rate", value: $viewModel.interestRate, format: .number)
                TextField("Annual Property Tax", value: $viewModel.annualPropertyTax, format: .number)
                TextField("Tax Assessment Value", value: $viewModel.taxAssessmentValue, format: .number)
                TextField("Annual Insurance", value: $viewModel.annualInsurance, format: .number)
                TextField("Ownership Status", text: $viewModel.ownershipStatus)
            }
        }
        .navigationTitle("Edit Property")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.save()
                        if viewModel.state == .saved {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.state == .saving)
            }
        }
        .overlay {
            if case .error(let message) = viewModel.state {
                Text(message)
                    .foregroundStyle(.red)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
        }
    }
}
