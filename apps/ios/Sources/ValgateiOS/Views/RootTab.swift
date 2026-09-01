import Foundation

enum RootTab: Int, CaseIterable, Identifiable {
    case home
    case properties
    case add
    case portfolio
    case profile

    var id: Int { rawValue }
}
