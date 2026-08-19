import Foundation

struct MeDto: Decodable {
    let email: String
    let displayName: String?
    let role: UserRole
    let orgName: String
}

enum UserRole: String, Decodable {
    case owner
    case admin
    case member
    case viewer
}
