import SwiftUI
import Photos

// MARK: - CardRenderer
// Wraps ImageRenderer to produce a 1080×1350 px UIImage from a CardCanvasView.

@MainActor
struct CardRenderer {

    static let exportWidth: CGFloat  = 1080
    static let exportHeight: CGFloat = 1350

    /// Renders the card to a UIImage at export resolution.
    static func render(card: LineupCard) -> UIImage? {
        let view = CardCanvasView(card: card)
            .frame(width: exportWidth, height: exportHeight)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.proposedSize = ProposedViewSize(
            width: exportWidth,
            height: exportHeight
        )
        return renderer.uiImage
    }

    /// Saves the rendered image to the Photos library.
    static func saveToPhotos(card: LineupCard) async throws {
        guard let image = render(card: card) else {
            throw RenderError.renderFailed
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error {
                    cont.resume(throwing: error)
                } else if success {
                    cont.resume()
                } else {
                    cont.resume(throwing: RenderError.saveFailed)
                }
            }
        }
    }

    /// Returns a UIImage suitable for sharing (same as export resolution).
    static func imageForSharing(card: LineupCard) -> UIImage? {
        render(card: card)
    }

    enum RenderError: LocalizedError {
        case renderFailed
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .renderFailed: return "Failed to render the card image."
            case .saveFailed:   return "Failed to save image to Photos."
            }
        }
    }
}
