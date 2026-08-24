import Foundation

/// Builds the request body for a single-file `multipart/form-data` upload.
/// Field name is fixed to `file`, matching `POST /api/v1/properties/{id}/documents`.
enum MultipartFormDataBuilder {
    static func makeBoundary() -> String {
        "Boundary-\(UUID().uuidString)"
    }

    static func contentTypeHeaderValue(boundary: String) -> String {
        "multipart/form-data; boundary=\(boundary)"
    }

    static func body(filename: String, mimeType: String, fileData: Data, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".utf8Data)
        body.append("Content-Type: \(mimeType)\r\n\r\n".utf8Data)
        body.append(fileData)
        body.append("\r\n".utf8Data)
        body.append("--\(boundary)--\r\n".utf8Data)
        return body
    }
}

private extension String {
    var utf8Data: Data { Data(self.utf8) }
}
