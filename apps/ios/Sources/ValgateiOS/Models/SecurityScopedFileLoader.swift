import Foundation

/// Reads file contents from a URL that may require security-scoped access
/// (e.g. a Files-app document outside the app sandbox). Always releases the
/// scope it opened, even when the read fails, and never throws — an
/// inaccessible or vanished file simply yields `nil`.
enum SecurityScopedFileLoader {
    static func loadData(from url: URL) -> Data? {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try? Data(contentsOf: url)
    }
}
