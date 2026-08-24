import SwiftUI
import UIKit

/// Display row for one staged/uploading attachment, keyed by the
/// `PendingDocument`'s stable id so it survives status updates.
struct AttachmentRow: Identifiable {
    let id: UUID
    let filename: String
    let status: DocumentUploadStatus?
}

struct AttachmentRowView: View {
    let row: AttachmentRow
    let onRetry: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: ValgateSpacing.space2) {
            Image(systemName: "doc")
                .foregroundStyle(Color.valTextSecondary)
                .font(.system(size: 14))
            Text(row.filename)
                .font(ValgateTypography.Body.standard)
                .foregroundStyle(Color.valTextPrimary)
                .lineLimit(1)
            Spacer()
            switch row.status {
            case .none, .pending:
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.valTextSecondary)
                }
            case .uploading:
                ProgressView()
            case .uploaded:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.valStatusSuccess)
            case .failed:
                Button(action: onRetry) {
                    Image(systemName: "exclamationmark.arrow.circlepath")
                        .foregroundStyle(Color.valStatusDanger)
                }
            }
        }
    }
}

/// Wraps `UIImagePickerController` in camera mode. Converts the captured
/// image to JPEG `Data` immediately and never retains the `UIImage`.
struct CameraCapturePicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapturePicker
        init(_ parent: CameraCapturePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            defer { parent.dismiss() }
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.8) else {
                parent.onCancel()
                return
            }
            parent.onCapture(data)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
            parent.onCancel()
        }
    }
}

/// Wraps `UIDocumentPickerViewController` for browsing Files-app documents.
/// Picks the file's original location (not a copy) so callers exercise the
/// security-scoped resource path via `SecurityScopedFileLoader`.
struct DocumentFilePicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentFilePicker
        init(_ parent: DocumentFilePicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            defer { parent.dismiss() }
            guard let url = urls.first else {
                parent.onCancel()
                return
            }
            parent.onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
            parent.onCancel()
        }
    }
}
