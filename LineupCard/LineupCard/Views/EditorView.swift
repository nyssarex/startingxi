import SwiftUI
import PhotosUI

// MARK: - EditorViewModel

@MainActor
class EditorViewModel: ObservableObject {
    @Published var card: LineupCard

    init(card: LineupCard? = nil) {
        self.card = card ?? LineupCard()
    }

    // MARK: Player mutations

    func addStarter() {
        let nextNum = (card.starters.last?.number ?? 0) + 1
        card.starters.append(Player(number: nextNum, surname: ""))
    }

    func removeStarter(at offsets: IndexSet) {
        card.starters.remove(atOffsets: offsets)
    }

    func moveStarter(from source: IndexSet, to dest: Int) {
        card.starters.move(fromOffsets: source, toOffset: dest)
    }

    func addBench() {
        let nextNum = (card.bench.last?.number ?? 11) + 1
        card.bench.append(Player(number: nextNum, surname: ""))
    }

    func removeBench(at offsets: IndexSet) {
        card.bench.remove(atOffsets: offsets)
    }

    func moveBench(from source: IndexSet, to dest: Int) {
        card.bench.move(fromOffsets: source, toOffset: dest)
    }

    func toggleCaptain(playerID: UUID) {
        // Clear all captains first, then set new one
        for i in card.starters.indices {
            card.starters[i].isCaptain = card.starters[i].id == playerID
                ? !card.starters[i].isCaptain
                : false
        }
        for i in card.bench.indices {
            card.bench[i].isCaptain = false
        }
    }

    func setCaptainOnBench(playerID: UUID) {
        for i in card.bench.indices {
            card.bench[i].isCaptain = card.bench[i].id == playerID
                ? !card.bench[i].isCaptain
                : false
        }
        for i in card.starters.indices {
            card.starters[i].isCaptain = false
        }
    }

    // MARK: Image setters

    func setPlayerPhoto(_ data: Data?) { card.playerPhotoData = data }
    func setBackground(_ data: Data?) { card.backgroundImageData = data }
    func setBadge1(_ data: Data?) { card.badge1Data = data }
    func setBadge2(_ data: Data?) { card.badge2Data = data }
}

// MARK: - EditorView

struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CardStore
    @StateObject private var vm: EditorViewModel
    @State private var showPreview = false

    // PhotosPickerItems
    @State private var pickerPlayerPhoto: PhotosPickerItem?
    @State private var pickerBg: PhotosPickerItem?
    @State private var pickerBadge1: PhotosPickerItem?
    @State private var pickerBadge2: PhotosPickerItem?

    init(card: LineupCard? = nil) {
        _vm = StateObject(wrappedValue: EditorViewModel(card: card))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Live preview thumbnail
                    livePreviewHeader
                        .padding(.bottom, 12)

                    // Template picker
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeader("STYLE")
                        TemplatePickerView(selected: $vm.card.themePreset)
                    }

                    Divider().padding(.vertical, 4)

                    // Card details
                    cardDetailsSection

                    Divider().padding(.vertical, 4)

                    // Starting lineup
                    playerListSection(
                        title: "STARTING \(vm.card.romanNumeral)",
                        players: $vm.card.starters,
                        addAction: vm.addStarter,
                        removeAction: vm.removeStarter,
                        moveAction: vm.moveStarter,
                        captainToggle: vm.toggleCaptain
                    )

                    Divider().padding(.vertical, 4)

                    // Bench
                    playerListSection(
                        title: "BENCH",
                        players: $vm.card.bench,
                        addAction: vm.addBench,
                        removeAction: vm.removeBench,
                        moveAction: vm.moveBench,
                        captainToggle: vm.setCaptainOnBench
                    )

                    Divider().padding(.vertical, 4)

                    // Media
                    mediaSection

                    Divider().padding(.vertical, 4)

                    // Badges
                    badgesSection

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(vm.card.matchLabel.isEmpty ? "New Card" : vm.card.matchLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            showPreview = true
                        } label: {
                            Image(systemName: "eye")
                        }
                        Button("Save") {
                            store.save(vm.card)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            CardPreviewView(card: vm.card)
        }
        // Photo picker observers
        .onChange(of: pickerPlayerPhoto) { item in
            loadImage(item) { vm.setPlayerPhoto($0) }
        }
        .onChange(of: pickerBg) { item in
            loadImage(item) { vm.setBackground($0) }
        }
        .onChange(of: pickerBadge1) { item in
            loadImage(item) { vm.setBadge1($0) }
        }
        .onChange(of: pickerBadge2) { item in
            loadImage(item) { vm.setBadge2($0) }
        }
    }

    // MARK: - Live Preview Header

    private var livePreviewHeader: some View {
        GeometryReader { geo in
            let previewW = geo.size.width
            let previewH = previewW * (1350.0 / 1080.0)
            CardCanvasView(card: vm.card)
                .frame(width: previewW, height: previewH)
        }
        .aspectRatio(1080.0 / 1350.0, contentMode: .fit)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 24)
    }

    // MARK: - Card Details Section

    private var cardDetailsSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                LabeledTextField("Title word", text: $vm.card.titleWord, placeholder: "STARTING")
                Divider()
                LabeledTextField("Match label", text: $vm.card.matchLabel, placeholder: "vs Fulham")
                Divider()
                LabeledTextField("Sponsor line", text: $vm.card.sponsorLine, placeholder: "Presented by Snapdragon")
                Divider()
                LabeledTextField("Manager", text: $vm.card.managerName, placeholder: "Ten Hag")
            }
        } label: {
            sectionHeader("CARD DETAILS")
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Player List Section

    private func playerListSection(
        title: String,
        players: Binding<[Player]>,
        addAction: @escaping () -> Void,
        removeAction: @escaping (IndexSet) -> Void,
        moveAction: @escaping (IndexSet, Int) -> Void,
        captainToggle: @escaping (UUID) -> Void
    ) -> some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(Array(players.wrappedValue.enumerated()), id: \.element.id) { idx, player in
                    PlayerInputRow(
                        player: players[idx],
                        captainToggle: { captainToggle(player.id) }
                    )
                    if idx < players.wrappedValue.count - 1 {
                        Divider().padding(.leading, 44)
                    }
                }

                // Add button
                Button(action: addAction) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Add Player")
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        } label: {
            HStack {
                sectionHeader(title)
                Spacer()
                if !players.wrappedValue.isEmpty {
                    Text("\(players.wrappedValue.count) players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                // Player photo
                HStack {
                    Label("Player Photo", systemImage: "person.crop.square")
                        .font(.system(size: 15))
                    Spacer()
                    PhotosPicker(selection: $pickerPlayerPhoto, matching: .images) {
                        Text(vm.card.playerPhotoData == nil ? "Select" : "Change")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    if vm.card.playerPhotoData != nil {
                        Button {
                            vm.setPlayerPhoto(nil)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)

                if let data = vm.card.playerPhotoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 90)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(8)
                }

                Divider()

                // Background image (for blurred bg themes)
                HStack {
                    Label("Background Photo", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 15))
                    Spacer()
                    PhotosPicker(selection: $pickerBg, matching: .images) {
                        Text(vm.card.backgroundImageData == nil ? "Select" : "Change")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    if vm.card.backgroundImageData != nil {
                        Button {
                            vm.setBackground(nil)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
        } label: {
            sectionHeader("PHOTOS")
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Badges Section

    private var badgesSection: some View {
        GroupBox {
            HStack(spacing: 16) {
                badgePicker(label: "Badge 1", data: vm.card.badge1Data, picker: $pickerBadge1) {
                    vm.setBadge1(nil)
                }
                Divider()
                badgePicker(label: "Badge 2", data: vm.card.badge2Data, picker: $pickerBadge2) {
                    vm.setBadge2(nil)
                }
            }
        } label: {
            sectionHeader("TEAM BADGES")
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func badgePicker(
        label: String,
        data: Data?,
        picker: Binding<PhotosPickerItem?>,
        clear: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            if let d = data, let img = UIImage(data: d) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
                Button("Remove", role: .destructive) { clear() }
                    .font(.caption)
            } else {
                PhotosPicker(selection: picker, matching: .images) {
                    VStack(spacing: 6) {
                        Image(systemName: "shield")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(1.2)
    }

    private func loadImage(_ item: PhotosPickerItem?, completion: @escaping (Data?) -> Void) {
        guard let item else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run { completion(data) }
        }
    }
}

// MARK: - PlayerInputRow

struct PlayerInputRow: View {
    @Binding var player: Player
    let captainToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Number
            TextField("#", value: $player.number, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 38)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(6)

            // Surname
            TextField("SURNAME", text: $player.surname)
                .font(.system(size: 15, weight: .medium))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)

            // Captain toggle
            Button(action: captainToggle) {
                Image(systemName: player.isCaptain ? "c.circle.fill" : "c.circle")
                    .foregroundColor(player.isCaptain ? .yellow : Color(.tertiaryLabel))
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - LabeledTextField

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    init(_ label: String, text: Binding<String>, placeholder: String = "") {
        self.label = label
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .frame(width: 110, alignment: .leading)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}
