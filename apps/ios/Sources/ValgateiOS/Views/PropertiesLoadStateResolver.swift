import Foundation

enum PropertiesLoadStateResolver {
    static func resolve(
        result: Result<(me: MeDto, page: PropertiesPageDto), APIClientError>
    ) -> PropertiesViewModel.LoadState {
        switch result {
        case .success(let value):
            return value.page.items.isEmpty
                ? .empty(me: value.me)
                : .loaded(me: value.me, properties: value.page.items)
        case .failure(let error):
            if case let APIClientError.server(status, code, _) = error, status == 401 || code == .unauthorized {
                return .unauthorized
            }
            return .error("Something went wrong. Please check your connection and try again.")
        }
    }
}
