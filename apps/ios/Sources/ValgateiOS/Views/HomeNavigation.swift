import SwiftUI

enum HomeNavigationDestination: Hashable {
    case propertyDetail(id: String)
}

struct HomeNavigationResolver {
    static func resolve(property: PropertyListItemDto) -> HomeNavigationDestination {
        .propertyDetail(id: property.id)
    }

    static func resolve(created: PropertyDetailDto) -> HomeNavigationDestination {
        .propertyDetail(id: created.id)
    }
}
