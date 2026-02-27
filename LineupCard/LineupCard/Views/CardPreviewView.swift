import SwiftUI
import Photos

// MARK: - CardPreviewView
// Full-screen preview with export actions.

struct CardPreviewView: View {
    let card: LineupCard

    @Environment(\.dismiss) private var dismiss
    @State private var exportState: ExportState = .idle
    @State private var shareItem: IdentifiableImage?
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView([.vertical, .horizontal], showsIndicators: false) {
                    CardCanvasView(card: card)
                        .frame(maxWidth: UIScreen.main.bounds.width)
                        .padding(.vertical, 16)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    exportMenu
                }
            }
        }
        .overlay(exportOverlay)
        .sheet(item: $shareItem) { item in
            ShareSheet(image: item.image)
        }
        .alert("LineupCard", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: Export Menu

    @ViewBuilder
    private var exportMenu: some View {
        Menu {
            Button {
                saveToPhotos()
            } label: {
                Label("Save to Photos", systemImage: "photo.on.rectangle")
            }

            Button {
                shareCard()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.white)
        }
        .disabled(exportState == .exporting)
    }

    // MARK: Export Overlay

    @ViewBuilder
    private var exportOverlay: some View {
        if exportState == .exporting {
            ZStack {
                Color.black.opacity(0.55)
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                    Text("Rendering…")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(28)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: Actions

    private func saveToPhotos() {
        exportState = .exporting
        Task {
            do {
                try await CardRenderer.saveToPhotos(card: card)
                await MainActor.run {
                    exportState = .idle
                    alertMessage = "Lineup card saved to Photos at 1080×1350."
                    showAlert = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            } catch {
                await MainActor.run {
                    exportState = .idle
                    let nsErr = error as NSError
                    if nsErr.domain == "PHPhotosErrorDomain" && nsErr.code == 3311 {
                        alertMessage = "Photos access denied. Enable it in Settings > Privacy > Photos."
                    } else {
                        alertMessage = error.localizedDescription
                    }
                    showAlert = true
                }
            }
        }
    }

    private func shareCard() {
        exportState = .exporting
        Task {
            if let image = await MainActor.run(body: { CardRenderer.render(card: card) }) {
                await MainActor.run {
                    exportState = .idle
                    shareItem = IdentifiableImage(image: image)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                await MainActor.run {
                    exportState = .idle
                    alertMessage = "Failed to render card."
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ExportState: Equatable {
    case idle
    case exporting
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
