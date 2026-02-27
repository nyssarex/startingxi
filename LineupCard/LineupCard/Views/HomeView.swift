import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject private var store: CardStore
    @State private var editingCard: LineupCard?  // nil = not editing; set to show sheet
    @State private var cardToDelete: LineupCard?
    @State private var showDeleteAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if store.cards.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.cards) { card in
                                CardGridItem(card: card)
                                    .contextMenu {
                                        Button {
                                            editingCard = card
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button {
                                            store.duplicate(card)
                                        } label: {
                                            Label("Duplicate", systemImage: "doc.on.doc")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            cardToDelete = card
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .onTapGesture {
                                        editingCard = card
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("LineupCard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingCard = LineupCard()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(item: $editingCard) { card in
            EditorView(card: card)
        }
        .alert("Delete Card?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let c = cardToDelete { store.delete(c) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "sportscourt")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "CC0000"))

            VStack(spacing: 8) {
                Text("No Cards Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Create your first lineup card\nand share it like the pros.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button {
                editingCard = LineupCard()
            } label: {
                Text("Create New Card")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(Color(hex: "CC0000"))
                    .cornerRadius(12)
            }
        }
        .padding(32)
    }
}

// MARK: - CardGridItem

struct CardGridItem: View {
    let card: LineupCard

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        return fmt.string(from: card.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Mini card preview
            CardCanvasView(card: card)
                .frame(maxWidth: .infinity)
                .aspectRatio(1080.0 / 1350.0, contentMode: .fit)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.matchLabel.isEmpty ? "Untitled" : card.matchLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("\(card.themePreset.displayName) · \(dateLabel)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 2)
        }
    }
}
