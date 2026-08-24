import Foundation

/// A user-selected file staged for upload — held as raw bytes only, never a
/// system picker handle, so the source (photo library item, camera buffer,
/// security-scoped file URL) can be released immediately after selection.
struct PendingDocument: Identifiable, Equatable {
    let id = UUID()
    let filename: String
    let mimeType: String
    let data: Data
}

enum DocumentUploadStatus: Equatable {
    case pending
    case uploading
    case uploaded(PropertyDocumentDto)
    case failed(String)
}

struct DocumentUploadItem: Identifiable, Equatable {
    let document: PendingDocument
    var status: DocumentUploadStatus

    var id: UUID { document.id }
}
