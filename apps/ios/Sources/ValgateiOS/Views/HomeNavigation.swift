import SwiftUI

enum HomeNavigationDestination: Hashable {
    case propertyDetail(id: String)
}

struct HomeNavigationResolver {
    static func resolve(property: PropertyListItemDto) -> HomeNavigationDestination {
        .propertyDetail(id: property.id)
    }
}
