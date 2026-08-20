import Foundation

enum APIRoute {
    case me
    case properties(limit: Int?, cursor: String?)
    case property(id: String)
    case createProperty
    case updateProperty(id: String)
    case deleteProperty(id: String)
}
